// Auction.cdc
//
// The Auction contract is an experimental implementation of an NFT Auction on Flow.
//
// This contract allows users to put their NFTs up for sale. Other users
// can purchase these NFTs with fungible tokens.
//
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0x01cf0e2f2f715450
import DemoToken from 0x179b6b1cb6755e31

pub contract Auction {

    //TODO: expose minNextBid
    pub struct AuctionStatus{

        pub let id: UInt64
        pub let price : UFix64
        pub let bidIncrement : UFix64
        pub let bids : UInt64
        pub let active: Bool
        pub let blocksRemaining : Int64
        pub let endBlock : UInt64
        pub let startBlock : UInt64
        pub let metadata : {String: String}
        pub let owner: Address
        pub let leader: Address?
        pub let minNextBid: UFix64
    
        init(id:UInt64, 
            currentPrice: UFix64, 
            bids:UInt64, 
            active: Bool, 
            blocksRemaining:Int64, 
            nftMetadata: {String: String}, 
            leader:Address?, 
            bidIncrement: UFix64,
            owner: Address, 
            startBlock: UInt64,
            endBlock: UInt64,
            minNextBid:UFix64
        ) {
            self.id=id
            self.price= currentPrice
            self.bids=bids
            self.active=active
            self.blocksRemaining=blocksRemaining
            self.metadata=nftMetadata
            self.leader= leader
            self.bidIncrement=bidIncrement
            self.owner=owner
            self.startBlock=startBlock
            self.endBlock=endBlock
            self.minNextBid=minNextBid
        }
    }

    // The total amount of AuctionItems that have been created
    pub var totalAuctions: UInt64

    // Events
    pub event NewAuctionCollectionCreated(minimumBidIncrement: UFix64, auctionLengthInBlocks: UInt64)
    pub event TokenAddedToAuctionItems(tokenID: UInt64, startPrice: UFix64)
    pub event TokenStartPriceUpdated(tokenID: UInt64, newPrice: UFix64)
    pub event NewBid(tokenID: UInt64, bidPrice: UFix64)
    pub event AuctionSettled(tokenID: UInt64, price: UFix64)
    pub event AuctionCanceled(tokenID: UInt64)

    pub event MarketplaceEarned(amount:UFix64)

    // AuctionItem contains the Resources and metadata for a single auction
    pub resource AuctionItem {
        
        pub var numberOfBids: UInt64
        //The Item that is sold at this auction
        pub(set) var NFT: @NonFungibleToken.NFT?

        //This is the escrow vault that holds the tokens for the current largest bid
        pub let bidVault: @FungibleToken.Vault

        //Should an auction know about its Id? It has to in order to send good events. But Then it is hard to move it to 
        //another collection? Or should this be a pub(set) var?
        pub let auctionID: UInt64

        //The minimum increment for a bid. This is an english auction style system where bids increase
        pub let minimumBidIncrement: UFix64

        //the block this auction should start at
        pub(set) var auctionStartBlock: UInt64

        //The length in blocks for this auction
        pub var auctionLengthInBlocks: UInt64

        pub(set) var auctionCompleted: Bool

        // Auction State
        pub(set) var startPrice: UFix64
        pub(set) var currentPrice: UFix64

        //the capability that points to the resource wher  you want the NFT transfered to if you win this bid. 
        pub(set) var recipientCollectionCap: Capability<&{NonFungibleToken.CollectionPublic}>?

        //the capablity to send the escrow bidVault to if you are outbid
        pub(set) var recipientVaultCap: Capability<&{FungibleToken.Receiver}>?

        //the capability for the owner of the NFT to return the item to if the auction is cancelled
        pub let ownerCollectionCap: Capability<&{NonFungibleToken.CollectionPublic}>

        //the capability to pay the owner of the item when the auction is done
        pub let ownerVaultCap: Capability<&{FungibleToken.Receiver}>

        init(
            NFT: @NonFungibleToken.NFT,
            minimumBidIncrement: UFix64,
            auctionLengthInBlocks: UInt64,
            startPrice: UFix64, 
            auctionStartBlock: UInt64,
            ownerCollectionCap: Capability<&{NonFungibleToken.CollectionPublic}>,
            ownerVaultCap: Capability<&{FungibleToken.Receiver}>,
        ) {

            Auction.totalAuctions = Auction.totalAuctions + UInt64(1)
            self.NFT <- NFT
            self.bidVault <- DemoToken.createEmptyVault()
            self.auctionID = Auction.totalAuctions
            self.minimumBidIncrement = minimumBidIncrement
            self.auctionLengthInBlocks = auctionLengthInBlocks
            self.startPrice = startPrice
            self.currentPrice = UFix64(0)
            self.auctionStartBlock = auctionStartBlock
            self.auctionCompleted = false
            self.recipientCollectionCap = nil
            self.recipientVaultCap = nil
            self.ownerCollectionCap = ownerCollectionCap
            self.ownerVaultCap = ownerVaultCap
            self.numberOfBids=0
        }
        
        // sendNFT sends the NFT to the Collection belonging to the provided Capability
        access(contract) fun sendNFT(_ capability: Capability<&{NonFungibleToken.CollectionPublic}>) {
            // borrow a reference to the owner's NFT receiver
            if let collectionRef = capability.borrow() {

                let NFT <- self.NFT <- nil
                // deposit the token into the owner's collection
                //TODO: What if does not exist?
                collectionRef.deposit(token: <-NFT!)
            } else {
                log("sendNFT(): unable to borrow collection ref")
                log(capability)
            }
        }

        // sendBidTokens sends the bid tokens to the Vault Receiver belonging to the provided Capability
        access(contract) fun sendBidTokens(_ capability: Capability<&{FungibleToken.Receiver}>) {
            // borrow a reference to the owner's NFT receiver
            if let vaultRef = capability.borrow() {
                let bidVaultRef = &self.bidVault as &FungibleToken.Vault
                log("Paid out money")
                log(bidVaultRef.balance)
                vaultRef.deposit(from: <-bidVaultRef.withdraw(amount: bidVaultRef.balance))
            } else {
                log("sendBidTokens(): couldn't get vault ref")
                log(capability)
            }
        }

        pub fun releasePreviousBid() {
            // release the bidTokens from the vault back to the bidder
            if let vaultCap = self.recipientVaultCap {
                self.sendBidTokens(self.recipientVaultCap!)
            } else {
                log("unable to get vault capability")
            }
        }
 


        pub fun settleAuction(cutPercentage: UFix64, cutVault:Capability<&{FungibleToken.Receiver}> )  {

            if self.auctionCompleted {
                log("this auction is already settled")
                return 
            }
            if self.NFT == nil {
                log("auction doesn't exist")
                return 
            }

            // check if the auction has expired
            if self.isAuctionExpired() == false {
                log("Auction has not completed yet")
                return
            }

                
            // return if there are no bids to settle
            if self.currentPrice == UFix64(0){
                self.returnAuctionItemToOwner()
                log("No bids. Nothing to settle")
                return
            }            

            //Withdraw cutPercentage to marketplace and put it in their vault
            let amount=self.currentPrice*cutPercentage
            let beneficiaryCut <- self.bidVault.withdraw(amount:amount )

            log("Marketplace cut was")
            log(amount)
            emit MarketplaceEarned(amount: amount)
            log(cutVault)
            cutVault.borrow()!.deposit(from: <- beneficiaryCut)

            self.exchangeTokens()

            self.auctionCompleted = true
            
            emit AuctionSettled(tokenID: self.auctionID, price: self.currentPrice)
        }

        pub fun returnAuctionItemToOwner() {

            // release the bidder's tokens
            self.releasePreviousBid()

            // deposit the NFT into the owner's collection
            self.sendNFT(self.ownerCollectionCap)
         }

        //this can be negative if is expired
        pub fun blocksRemaining() : Int64 {
            let auctionLength = self.auctionLengthInBlocks

            let startBlock = self.auctionStartBlock 

            let currentBlock = getCurrentBlock().height
            return Int64(startBlock+auctionLength) - Int64(currentBlock) 
        }

      
        pub fun isAuctionExpired(): Bool {
            return self.blocksRemaining() < Int64(0)
        }

        // exchangeTokens sends the purchased NFT to the buyer and the bidTokens to the seller
        pub fun exchangeTokens() {
            
            if self.NFT == nil {
                log("auction doesn't exist")
                return
            }
            

            self.sendNFT(self.recipientCollectionCap!)
            self.sendBidTokens(self.ownerVaultCap)
        }

        pub fun minNextBid() :UFix64{
            //If there are bids then the next min bid is the current price plus the increment
            if self.currentPrice != UFix64(0) {
                return self.currentPrice+self.minimumBidIncrement
            }
            //else start price
            return self.startPrice


        }

        pub fun extendWith(_ amount: UInt64) {
            self.auctionLengthInBlocks = self.auctionLengthInBlocks + amount
        }
        pub fun placeBid(bidTokens: @FungibleToken.Vault, vaultCap: Capability<&{FungibleToken.Receiver}>, collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>) {


            if self.auctionCompleted {
                panic("auction has already completed")
            }

            if bidTokens.balance < self.minNextBid() {
                panic("bid amount be larger or equal to the current price + minimum bid increment")
            }
            
            if self.bidVault.balance != UFix64(0) {
                if let vaultCap = self.recipientVaultCap {
                    self.sendBidTokens(self.recipientVaultCap!)
                } else {
                    panic("unable to get recipient Vault capability")
                }
            }

            // Update the auction item
            self.bidVault.deposit(from: <-bidTokens)

            self.recipientVaultCap = vaultCap

            // Update the current price of the token
            self.currentPrice = self.bidVault.balance

            // Add the bidder's Vault and NFT receiver references
            self.recipientCollectionCap = collectionCap
            self.numberOfBids=self.numberOfBids+UInt64(1)

            //TODO make better bid event
            emit NewBid(tokenID: self.auctionID, bidPrice: self.currentPrice)
        }

        pub fun getAuctionStatus() :AuctionStatus {

            var leader:Address?= nil
            if let recipient = self.recipientVaultCap {
                leader=recipient.borrow()!.owner!.address
            }

            //log(self.recipientVaultCap!.borrow()!.owner?.address ?? nil)

            return AuctionStatus(
                id:self.auctionID,
                currentPrice: self.currentPrice, 
                bids: self.numberOfBids,
                active: !self.auctionCompleted  && !self.isAuctionExpired(),
                blocksRemaining: self.blocksRemaining(),
                nftMetadata: self.NFT?.metadata ?? {},
                leader: leader,
                bidIncrement: self.minimumBidIncrement,
                owner: self.ownerVaultCap.borrow()!.owner!.address,
                startBlock: self.auctionStartBlock, 
                endBlock: self.auctionStartBlock+self.auctionLengthInBlocks, 
                minNextBid: self.minNextBid()
                )
        }

        destroy() {
            // send the NFT back to auction owner
            self.sendNFT(self.ownerCollectionCap)
            
            // if there's a bidder...
            if let vaultCap = self.recipientVaultCap {
                // ...send the bid tokens back to the bidder
                self.sendBidTokens(vaultCap)
            }

            destroy self.NFT
            destroy self.bidVault
        }
    }

    

    // AuctionPublic is a resource interface that restricts users to
    // retreiving the auction price list and placing bids
    pub resource interface AuctionPublic {

        pub fun extendAllAuctionsWith(_ amount: UInt64)
         pub fun createAuction(
             token: @NonFungibleToken.NFT, 
             minimumBidIncrement: UFix64, 
             auctionLengthInBlocks: UInt64, 
             auctionStartBlock: UInt64,
             startPrice: UFix64, 
             collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>, 
             vaultCap: Capability<&{FungibleToken.Receiver}>) 

        pub fun getAuctionStatuses(): {UInt64: AuctionStatus}
        pub fun getAuctionStatus(_ id:UInt64): AuctionStatus

        pub fun placeBid(
            id: UInt64, 
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&{FungibleToken.Receiver}>, 
            collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>
        )
    }

    // AuctionCollection contains a dictionary of AuctionItems and provides
    // methods for manipulating the AuctionItems
    pub resource AuctionCollection: AuctionPublic {

        // Auction Items
        pub var auctionItems: @{UInt64: AuctionItem}
        pub var cutPercentage:UFix64 
        pub let marketplaceVault: Capability<&{FungibleToken.Receiver}>

        init(
            marketplaceVault: Capability<&{FungibleToken.Receiver}>, 
            cutPercentage: UFix64
        ) {
            self.cutPercentage= cutPercentage
            self.marketplaceVault = marketplaceVault
            self.auctionItems <- {}
        }


        pub fun extendAllAuctionsWith(_ amount: UInt64) {
            for id in self.auctionItems.keys {
                let itemRef = &self.auctionItems[id] as? &AuctionItem
                itemRef.extendWith(amount)
            }
            
        }
        // addTokenToauctionItems adds an NFT to the auction items and sets the meta data
        // for the auction item
        pub fun createAuction(
            token: @NonFungibleToken.NFT, 
            minimumBidIncrement: UFix64, 
            auctionLengthInBlocks: UInt64, 
            auctionStartBlock: UInt64,
            startPrice: UFix64, 
            collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>, 
            vaultCap: Capability<&{FungibleToken.Receiver}>) {
            
            // create a new auction items resource container
            let item <- Auction.createStandaloneAuction(
                token: <-token,
                minimumBidIncrement: minimumBidIncrement,
                auctionLengthInBlocks: auctionLengthInBlocks,
                auctionStartBlock: auctionStartBlock,
                startPrice: startPrice,
                collectionCap: collectionCap,
                vaultCap: vaultCap
            )

            let id = item.auctionID

            // update the auction items dictionary with the new resources
            let oldItem <- self.auctionItems[id] <- item
            destroy oldItem

            emit TokenAddedToAuctionItems(tokenID: id, startPrice: startPrice)
        }

        // getAuctionPrices returns a dictionary of available NFT IDs with their current price
        pub fun getAuctionStatuses(): {UInt64: AuctionStatus} {
            pre {
                self.auctionItems.keys.length > 0: "There are no auction items"
            }

            let priceList: {UInt64: AuctionStatus} = {}

            for id in self.auctionItems.keys {
                let itemRef = &self.auctionItems[id] as? &AuctionItem
                priceList[id] = itemRef.getAuctionStatus()
            }
            
            return priceList
        }

        pub fun getAuctionStatus(_ id:UInt64): AuctionStatus {
            pre {
                self.auctionItems[id] != nil:
                    "NFT doesn't exist"
            }

            // Get the auction item resources
            let itemRef = &self.auctionItems[id] as &AuctionItem
            return itemRef.getAuctionStatus()

        }

        // settleAuction sends the auction item to the highest bidder
        // and deposits the FungibleTokens into the auction owner's account
        pub fun settleAuction(_ id: UInt64) {
            let itemRef = &self.auctionItems[id] as &AuctionItem

            itemRef.settleAuction(cutPercentage: self.cutPercentage, cutVault: self.marketplaceVault)

        }

        pub fun settleAllAuctions() {
           for id in self.auctionItems.keys {
               self.settleAuction(id)
           } 
            
        }

        pub fun cancelAllAuctions() {
            for id in self.auctionItems.keys {
                self.cancelAuction(id)
            }
        }
        
        pub fun cancelAuction(_ id: UInt64) {
            pre {
                self.auctionItems[id] != nil:
                    "Auction does not exist"
            }
            let itemRef = &self.auctionItems[id] as &AuctionItem
            itemRef.returnAuctionItemToOwner()
            emit AuctionCanceled(tokenID: id)
        }

        // placeBid sends the bidder's tokens to the bid vault and updates the
        // currentPrice of the current auction item
        pub fun placeBid(id: UInt64, bidTokens: @FungibleToken.Vault, vaultCap: Capability<&{FungibleToken.Receiver}>, collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>) {
            pre {
                self.auctionItems[id] != nil:
                    "NFT doesn't exist"
            }

            // Get the auction item resources
            let itemRef = &self.auctionItems[id] as &AuctionItem
            itemRef.placeBid(bidTokens: <- bidTokens, 
              vaultCap:vaultCap, 
              collectionCap:collectionCap)

        }

        destroy() {
            // destroy the empty resources
            destroy self.auctionItems
        }
    }

        // addTokenToauctionItems adds an NFT to the auction items and sets the meta data
        // for the auction item
        pub fun createStandaloneAuction(
            token: @NonFungibleToken.NFT, 
            minimumBidIncrement: UFix64, 
            auctionLengthInBlocks: UInt64, 
            auctionStartBlock: UInt64,
            startPrice: UFix64, 
            collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>, 
            vaultCap: Capability<&{FungibleToken.Receiver}>) : @AuctionItem {
            
            // create a new auction items resource container
            return  <- create AuctionItem(
                NFT: <-token,
                minimumBidIncrement: minimumBidIncrement,
                auctionLengthInBlocks: auctionLengthInBlocks,
                startPrice: startPrice,
                auctionStartBlock: auctionStartBlock,
                ownerCollectionCap: collectionCap,
                ownerVaultCap: vaultCap
            )
        }
    // createAuctionCollection returns a new AuctionCollection resource to the caller
    pub fun createAuctionCollection(marketplaceVault: Capability<&{FungibleToken.Receiver}>,cutPercentage: UFix64): @AuctionCollection {
        let auctionCollection <- create AuctionCollection(
            marketplaceVault: marketplaceVault, 
            cutPercentage: cutPercentage
        )
        return <- auctionCollection
    }

    init() {
        self.totalAuctions = UInt64(0)
    }   
}
 