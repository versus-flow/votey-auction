
import FungibleToken from "./standard/FungibleToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import Art from "./Art.cdc"
import Auction from "./Auction.cdc"

pub contract Versus {

   
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub var totalDrops: UInt64

    //Events
    //Versus marketplace is created
    pub event CollectionCreated(owner:Address, cutPercentage: UFix64)

    //When a drop is extended due to a late bid or bid after tie we emit and event
    pub event DropExtended(id: UInt64, extendWith: Fix64, extendTo: Fix64)

    //TODO: businessEvent and technicalEvent
    //When somebody bids on a versus drop we emit and event with the  id of the drop and acution as well as who bid and how much
    pub event Bid(dropId: UInt64, auctionId: UInt64, bidderAddress: Address, bidPrice: UFix64, time: Fix64, blockHeight:UInt64)

    //When a drop is created we emit and event with its id, who owns the art, how many editions are sold vs the unique and the metadata
    pub event DropCreated(id: UInt64, owner: Address, editions: UInt64)

    //Versus drop is settled
    pub event Settle(id: UInt64, winner: String, price:UFix64)


    //sending in a reference to a editionMinter would be a nice enhancement here. So that the Art NFT is not coded in here at all. 
    pub fun createVersusDropCollection(
        marketplaceVault: Capability<&{FungibleToken.Receiver}>,
        marketplaceNFTTrash: Capability<&{Art.CollectionPublic}>,
        cutPercentage: UFix64,
        dropLength: UFix64, 
        minimumTimeRemainingAfterBidOrTie: UFix64): @DropCollection {
        let collection <- create DropCollection(
            marketplaceVault: marketplaceVault, 
            marketplaceNFTTrash: marketplaceNFTTrash,
            cutPercentage: cutPercentage,
            dropLength: dropLength,
            minimumTimeRemainingAfterBidOrTie:minimumTimeRemainingAfterBidOrTie
        )
        emit CollectionCreated(owner: marketplaceVault.borrow()!.owner!.address, cutPercentage:cutPercentage)
        return <- collection
    }


    //A Drop in versus represents a single auction vs an editioned auction
    pub resource Drop {

        //It would be really simple here to support many vs many or even a many vs many vs many vs many type of auction here
        //just convert these to a dictionary of key:AuctionCollection.

        access(contract) let uniqueAuction: @Auction.AuctionItem
        access(contract) let editionAuctions: @Auction.AuctionCollection
        pub let dropID: UInt64
        access(contract) var firstBidBlock: UInt64?


        init( uniqueAuction: @Auction.AuctionItem, 
            editionAuctions: @Auction.AuctionCollection) { 

            Versus.totalDrops = Versus.totalDrops + (1 as UInt64)

            self.dropID=Versus.totalDrops
            self.uniqueAuction <-uniqueAuction
            self.editionAuctions <- editionAuctions
            self.firstBidBlock=nil
        }
            
        destroy(){
            destroy self.uniqueAuction
            destroy self.editionAuctions
        }


        //A method used in scripts to get drop status. Will aggregate information from all auctions into a single struct
        pub fun getDropStatus() : DropStatus {

            let uniqueRef = &self.uniqueAuction as &Auction.AuctionItem
            let editionRef= &self.editionAuctions as &Auction.AuctionCollection

            let editionStatuses= editionRef.getAuctionStatuses()
            var sum:UFix64= 0.0
            for es in editionStatuses.keys {
                sum = sum + editionStatuses[es]!.price
            }
            let uniqueStatus=uniqueRef.getAuctionStatus()
            var price= uniqueStatus.price


            var winningStatus="UNIQUE"
            if sum > price {
                winningStatus="EDITIONED"
                price=sum
            } else if (sum == price) {
                winningStatus="TIE"
            }
            return DropStatus(
                dropId: self.dropID,
                uniqueStatus: uniqueStatus,
                editionsStatuses: editionStatuses, 
                editionPrice: sum,
                price: price, 
                status: winningStatus,
                firstBidBlock: self.firstBidBlock,
                art: uniqueRef.content()
            )
        }


        // This method will place a bid in a given auction and possibly extend the duration of all auctions if there is to little
        // time left or if the auction is tied
        pub fun placeBid(
            auctionId:UInt64,
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&{FungibleToken.Receiver}>, 
            collectionCap: Capability<&{Art.CollectionPublic}>, 
            minimumTimeRemaining: UFix64) {

            let dropStatus = self.getDropStatus()
            let block=getCurrentBlock()
            let time=Fix64(block.timestamp)

            if dropStatus.startTime > time {
                panic("The drop has not started")
            }
            if dropStatus.endTime < time && dropStatus.winning != "TIE" {
                panic("This drop has ended")
            }
           
            //TODO: save time of first bid
            let bidEndTime = time + Fix64(minimumTimeRemaining)

            if self.firstBidBlock == nil {
                self.firstBidBlock=block.height
            }
            //We need to extend the auction since there is too little time left. If we did not do this a late user could potentially win with a cheecky bid
            if dropStatus.endTime < bidEndTime {
                let extendWith=bidEndTime - dropStatus.endTime
                emit DropExtended(id: self.dropID, extendWith: extendWith, extendTo: bidEndTime)
                self.extendDropWith(UFix64(extendWith))
            }

            let bidPrice = bidTokens.balance
            let bidder=vaultCap.borrow()!.owner!.address

            //Figure out what id to use
            if self.uniqueAuction.auctionID == auctionId {
                let auctionRef = &self.uniqueAuction as &Auction.AuctionItem
                auctionRef.placeBid(bidTokens: <- bidTokens, vaultCap:vaultCap, collectionCap:collectionCap)
            } else {
                let editionsRef = &self.editionAuctions as &Auction.AuctionCollection 
                editionsRef.placeBid(id: auctionId, bidTokens: <- bidTokens, vaultCap:vaultCap, collectionCap:collectionCap)
            }
            emit Bid(dropId: self.dropID, auctionId: auctionId, bidderAddress: bidder , bidPrice: bidPrice, time: time, blockHeight: block.height)
        }

        pub fun extendDropWith(_ time: UFix64) {
            log("Drop extended with duration")
            self.uniqueAuction.extendWith(time)
            self.editionAuctions.extendAllAuctionsWith(time)
        }
        
    }


    //The struct that holds status information of a drop. 
    //Some more data should proably be extracted from the uniqueStatus here. 
    // - information used to show a drop (artist name, description, url aso)
    // - blocks remaining
    pub struct DropStatus {
        pub let dropId: UInt64
        pub let uniquePrice: UFix64
        pub let editionPrice: UFix64
        pub let endTime: Fix64
        pub let startTime: Fix64
        pub let uniqueStatus: Auction.AuctionStatus
        pub let editionsStatuses: {UInt64: Auction.AuctionStatus}
        pub let price: UFix64
        pub let winning: String
        pub let active: Bool
        pub let timeRemaining: Fix64
        pub let firstBidBlock:UInt64?
        pub let art: String?

        init(
            dropId: UInt64,
            uniqueStatus: Auction.AuctionStatus,
            editionsStatuses: {UInt64: Auction.AuctionStatus},
            editionPrice: UFix64, 
            price: UFix64,
            status: String,
            firstBidBlock:UInt64?,
            art:String? //can has enum!
            ) {
                self.dropId=dropId
                self.uniqueStatus=uniqueStatus
                self.editionsStatuses=editionsStatuses
                self.uniquePrice= uniqueStatus.price
                self.editionPrice= editionPrice
                self.endTime=uniqueStatus.endTime
                self.startTime=uniqueStatus.startTime
                self.timeRemaining=uniqueStatus.timeRemaining
                self.active=uniqueStatus.active
                self.price=price
                self.winning=status
                self.firstBidBlock=firstBidBlock
                self.art=art
            }
    }

    pub resource interface PublicDrop {
         
         //Versus is a currated auction so users cannot create a drop themselves. 
        pub fun getAllStatuses(): {UInt64: DropStatus}
        pub fun getStatus(dropId: UInt64): DropStatus

        pub fun placeBid(
            dropId: UInt64, 
            auctionId:UInt64,
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&{FungibleToken.Receiver}>, 
            collectionCap: Capability<&{Art.CollectionPublic}>
        )

    }

    pub resource DropCollection: PublicDrop {

        pub var drops: @{UInt64: Drop}
        pub var cutPercentage:UFix64 
        pub let marketplaceVault: Capability<&{FungibleToken.Receiver}>
        pub let marketplaceNFTTrash: Capability<&{Art.CollectionPublic}>

        //naming things are hard...
        pub let minimumTimeRemainingAfterBidOrTie: UFix64
        //seconds
        pub let dropLength: UFix64


        init(
            marketplaceVault: Capability<&{FungibleToken.Receiver}>, 
            marketplaceNFTTrash: Capability<&{Art.CollectionPublic}>,
            cutPercentage: UFix64,
            dropLength: UFix64,
            minimumTimeRemainingAfterBidOrTie:UFix64
        ) {
            self.marketplaceNFTTrash=marketplaceNFTTrash
            self.cutPercentage= cutPercentage
            self.marketplaceVault = marketplaceVault
            self.dropLength=dropLength
            self.minimumTimeRemainingAfterBidOrTie=minimumTimeRemainingAfterBidOrTie
            self.drops <- {}
        }


        // When creating a drop you send in an NFT and the number of editions you want to sell vs the unique one
        // There will then be minted edition number of extra copies and put into the editions auction
        // When the auction is settled all NFTs that are not sold will be destroyed.
        pub fun createDrop(
             nft: @NonFungibleToken.NFT,
             editions: UInt64,
             minimumBidIncrement: UFix64, 
             startTime: UFix64, 
             startPrice: UFix64,  
             vaultCap: Capability<&{FungibleToken.Receiver}>) {


            pre {
                vaultCap.check() == true : "Vault capability should exist"
            }

            let art <- nft as! @Art.NFT

            //Sending in a NFTEditioner capability here and using that instead of this loop would probably make sense. 
            let editionedAuctions <- Auction.createAuctionCollection( 
                marketplaceVault: self.marketplaceVault , 
                cutPercentage: self.cutPercentage)

            var currentEdition=(1 as UInt64)
            while currentEdition <= editions {
                //A nice enhancement here would be that the art created is done through a minter so it is not art specific.
                //It could even be a Cloner capability or maybe a editionMinter? 
                editionedAuctions.createAuction(
                    token: <- art.makeEdition(edition: currentEdition, maxEdition: editions),
                    minimumBidIncrement: minimumBidIncrement, 
                    auctionLength: self.dropLength,
                    auctionStartTime:startTime,
                    startPrice: startPrice, 
                    collectionCap: self.marketplaceNFTTrash, 
                    vaultCap: vaultCap)
                currentEdition=currentEdition+(1 as UInt64)
            }

                //copy the metadata of the previous art since that is used to mint the copies
            let item <- Auction.createStandaloneAuction(
                token: <- art,
                minimumBidIncrement: minimumBidIncrement,
                auctionLength: self.dropLength,
                auctionStartTime: startTime,
                startPrice: startPrice,
                collectionCap: self.marketplaceNFTTrash,
                vaultCap: vaultCap
            )
            
            let drop  <- create Drop(uniqueAuction: <- item, editionAuctions:  <- editionedAuctions)
            emit DropCreated(id: drop.dropID, owner: vaultCap.borrow()!.owner!.address, editions: editions)

            let oldDrop <- self.drops[drop.dropID] <- drop
            destroy oldDrop
        }



        pub fun getAllStatuses(): {UInt64: DropStatus} {
            var dropStatus: {UInt64: DropStatus }= {}
            for id in self.drops.keys {
                let itemRef = &self.drops[id] as? &Drop
                dropStatus[id] = itemRef.getDropStatus()
            }
            return dropStatus

        }
        pub fun getStatus(dropId:UInt64): DropStatus {
             pre {
                self.drops[dropId] != nil:
                    "drop doesn't exist"
            }

            // Get the auction item resources
            let itemRef = &self.drops[dropId] as &Drop
            return itemRef.getDropStatus()
        }

        pub fun settle(_ dropId: UInt64) {
           pre {
                self.drops[dropId] != nil:
                    "drop doesn't exist"
            }
            let itemRef = &self.drops[dropId] as &Drop

            let status=itemRef.getDropStatus()

            if itemRef.uniqueAuction.isAuctionExpired() == false {
                panic("Auction has not completed yet")
            }

            let winning=status.winning
            if winning == "UNIQUE" {
                itemRef.uniqueAuction.settleAuction(cutPercentage: self.cutPercentage, cutVault: self.marketplaceVault)
                itemRef.editionAuctions.cancelAllAuctions()
            } else if winning == "EDITIONED" {
                itemRef.uniqueAuction.returnAuctionItemToOwner()
                itemRef.editionAuctions.settleAllAuctions()
            } else {
                panic("tie")
            }
            emit Settle(id: dropId, winner: winning, price: status.price )

        }

        pub fun placeBid(
            dropId: UInt64, 
            auctionId:UInt64,
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&{FungibleToken.Receiver}>, 
            collectionCap: Capability<&{Art.CollectionPublic}>
        ) {
            pre {
                self.drops[dropId] != nil:
                    "Drop does not exist"

                collectionCap.check() == true : "Collection capability must be linked"

                vaultCap.check() == true : "Vault capability must be linked"

            }
            let drop = &self.drops[dropId] as &Drop
            let minimumTimeRemainingAfterBidOrTie=self.minimumTimeRemainingAfterBidOrTie


            drop.placeBid(auctionId: auctionId, bidTokens: <- bidTokens, vaultCap: vaultCap, collectionCap:collectionCap, minimumTimeRemaining: minimumTimeRemainingAfterBidOrTie)

        }
        destroy() {            
            destroy self.drops
        }
    }


    /*
     Get an active drop in the versus marketplace with the given address
     
     */
    pub fun getActiveDrop(address:Address) : Versus.DropStatus?{
        // get the accounts' public address objects
        let account = getAccount(address)

        let versusCap=account.getCapability<&{Versus.PublicDrop}>(self.CollectionPublicPath)
        if let versus = versusCap.borrow() {
            let versusStatuses=versus.getAllStatuses()
            for s in versusStatuses.keys {
                let status = versusStatuses[s]!
                if status.uniqueStatus.active != false {
                    return status
                }
            } 
        } 
        return nil
    }

    init() {

        self.CollectionPublicPath= /public/versusCollection
        self.CollectionStoragePath= /storage/versusCollection

        self.totalDrops = (0 as UInt64)
    }
     
}
 