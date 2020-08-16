// VoteyAuction.cdc
//
// The VoteyAuction contract is an experimental implementation of an NFT Auction on Flow.
//
// This contract allows users to put their NFTs up for sale. Other users
// can purchase these NFTs with fungible tokens.
//
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0x01cf0e2f2f715450

// Contract Deployment:
// Acct 1 - 0x01cf0e2f2f715450 - NonFungibleToken.cdc
// Acct 2 - 0x179b6b1cb6755e31 - DemoToken.cdc
// Acct 3 - 0xf3fcd2c1a78f5eee - Rocks.cdc
// Acct 4 - 0xe03daebed8ca0615 - Auction.cdc
//

pub contract VoteyAuction {

    // The total amount of AuctionItems that have been created
    pub var totalAuctions: UInt64

    // Events
    pub event NewAuctionCollectionCreated(minimumBidIncrement: UFix64, auctionLengthInBlocks: UInt64)
    pub event TokenAddedToAuctionItems(tokenID: UInt64, startPrice: UFix64)
    pub event TokenStartPriceUpdated(tokenID: UInt64, newPrice: UFix64)
    pub event NewBid(tokenID: UInt64, bidPrice: UFix64)
    pub event AuctionSettled(tokenID: UInt64, price: UFix64)

    pub event MarketplaceEarned(amount:UFix64)

    // AuctionItem contains the Resources and metadata for a single auction
    pub resource AuctionItem {
        
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
        pub let auctionLengthInBlocks: UInt64

        pub(set) var auctionCompleted: Bool

        // Auction State
        pub(set) var startPrice: UFix64
        pub(set) var currentPrice: UFix64

        //the capability that points to the resource wher  you want the NFT transfered to if you win this bid. 
        pub(set) var recipientCollectionCap: Capability<&{NonFungibleToken.CollectionPublic}>

        //the capablity to send the escrow bidVault to if you are outbid
        pub(set) var recipientVaultCap: Capability<&{FungibleToken.Receiver}>?

        //the capability for the owner of the NFT to return the item to if the auction is cancelled
        pub let ownerCollectionCap: Capability<&{NonFungibleToken.CollectionPublic}>

        //the capability to pay the owner of the item when the auction is done
        pub let ownerVaultCap: Capability<&{FungibleToken.Receiver}>

        init(
            NFT: @NonFungibleToken.NFT,
            bidVault: @FungibleToken.Vault,
            minimumBidIncrement: UFix64,
            auctionLengthInBlocks: UInt64,
            startPrice: UFix64, 
            auctionStartBlock: UInt64,
            ownerCollectionCap: Capability<&{NonFungibleToken.CollectionPublic}>,
            ownerVaultCap: Capability<&{FungibleToken.Receiver}>
        ) {

            VoteyAuction.totalAuctions = VoteyAuction.totalAuctions + UInt64(1)
            self.NFT <- NFT
            self.bidVault <- bidVault
            self.auctionID = VoteyAuction.totalAuctions
            self.minimumBidIncrement = minimumBidIncrement
            self.auctionLengthInBlocks = auctionLengthInBlocks
            self.startPrice = startPrice
            self.currentPrice = startPrice
            self.auctionStartBlock = auctionStartBlock
            self.auctionCompleted = false
            self.recipientCollectionCap = ownerCollectionCap
            self.recipientVaultCap = ownerVaultCap
            self.ownerCollectionCap = ownerCollectionCap
            self.ownerVaultCap = ownerVaultCap
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
            if self.currentPrice == self.startPrice {
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

           // isAuctionExpired returns true if the auction has exceeded it's length in blocks,
        // otherwise it returns false
        pub fun isAuctionExpired(): Bool {

            let auctionLength = self.auctionLengthInBlocks
            let startBlock = self.auctionStartBlock 
            let currentBlock = getCurrentBlock()
            
            if currentBlock.height - startBlock > auctionLength {
                return true
            } else {
                return false
            }
        }

        // exchangeTokens sends the purchased NFT to the buyer and the bidTokens to the seller
        pub fun exchangeTokens() {
            
            if self.NFT == nil {
                log("auction doesn't exist")
                return
            }
            

            self.sendNFT(self.recipientCollectionCap)
            self.sendBidTokens(self.ownerVaultCap)
        }

        pub fun placeBid(bidTokens: @FungibleToken.Vault, vaultCap: Capability<&{FungibleToken.Receiver}>, collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>) {


            if self.auctionCompleted {
                panic("auction has already completed")
            }

            if bidTokens.balance < self.minimumBidIncrement {
                panic("bid amount be larger than minimum bid increment")
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

            //TODO make better bid event
            emit NewBid(tokenID: self.auctionID, bidPrice: self.currentPrice)
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
        // TODO; add addTOken method

        //TODO extend this to be auctionInfo with time remaining aso
        pub fun getAuctionPrices(): {UInt64: UFix64}
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

        // addTokenToauctionItems adds an NFT to the auction items and sets the meta data
        // for the auction item
        pub fun addTokenToAuctionItems(token: @NonFungibleToken.NFT, minimumBidIncrement: UFix64, auctionLengthInBlocks: UInt64, startPrice: UFix64, bidVault: @FungibleToken.Vault, collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>, vaultCap: Capability<&{FungibleToken.Receiver}>) {
            
            // create a new auction items resource container
            let item <- create AuctionItem(
                NFT: <-token,
                bidVault: <-bidVault,
                minimumBidIncrement: minimumBidIncrement,
                auctionLengthInBlocks: auctionLengthInBlocks,
                startPrice: startPrice,
                auctionStartBlock: getCurrentBlock().height,
                ownerCollectionCap: collectionCap,
                ownerVaultCap: vaultCap
            )

            let id = item.auctionID

            // update the auction items dictionary with the new resources
            let oldItem <- self.auctionItems[id] <- item
            destroy oldItem

            emit TokenAddedToAuctionItems(tokenID: id, startPrice: startPrice)
        }

        // getAuctionPrices returns a dictionary of available NFT IDs with their current price
        pub fun getAuctionPrices(): {UInt64: UFix64} {
            pre {
                self.auctionItems.keys.length > 0: "There are no auction items"
            }

            let priceList: {UInt64: UFix64} = {}

            for id in self.auctionItems.keys {
                let itemRef = &self.auctionItems[id] as? &AuctionItem
                if itemRef.auctionCompleted == false {
                    priceList[id] = itemRef.currentPrice
                }
            }
            
            return priceList
        }

        // settleAuction sends the auction item to the highest bidder
        // and deposits the FungibleTokens into the auction owner's account
        pub fun settleAuction(_ id: UInt64) {
            let itemRef = &self.auctionItems[id] as &AuctionItem

            itemRef.settleAuction(cutPercentage: self.cutPercentage, cutVault: self.marketplaceVault)

        }

        // placeBid sends the bidder's tokens to the bid vault and updates the
        // currentPrice of the current auction item
        pub fun placeBid(id: UInt64, bidTokens: @FungibleToken.Vault, vaultCap: Capability<&{FungibleToken.Receiver}>, collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>) 
            {
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
 