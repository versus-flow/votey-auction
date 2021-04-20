
import FungibleToken from "./standard/FungibleToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import Art from "./Art.cdc"
import Auction from "./Auction.cdc"

/*

 The main contract in the Versus auction system.

 A versions auction contains a single auction and a group of auctions and either of them will be fulfilled while the other will be cancelled
 Currently this is modeled as 1 vs x, but It could easily be modeled as x vs y  so you could have 5 editions vs 10 editions if you want to

 The auctions themselves are not implemented in this contract but rather in the Auction contract. The goal here is to be able to
 reuse the Auction contract for other things if somebody would want that.  

 */
pub contract Versus {

    //A set of capability and storage paths used in this contract
    pub let VersusAdministratorPrivatePath: PrivatePath
    pub let VersusAdministratorStoragePath: StoragePath
    pub let VersusAdminClientPublicPath: PublicPath
    pub let VersusAdminClientStoragePath: StoragePath
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath


    //counter for drops that is incremented every time there is a new versus drop made
    pub var totalDrops: UInt64

    //All the events that start with a T are more technical in nature while the other events are there to be distributed to Discord or similar social media

    //emitted when a drop is extended
    pub event DropExtended(name: String, artist: String, dropId: UInt64, extendWith: Fix64, extendTo: Fix64)

    //emitted when a bid is made
    pub event Bid(name: String, artist: String, edition:String, bidder: Address, price: UFix64, dropId: UInt64, auctionId:UInt64)

    //emitted when a drop is created
    pub event DropCreated(name: String, artist: String, editions: UInt64, owner:Address, dropId: UInt64)

    pub event DropDestroyed(dropId:UInt64)

    //emitted when a drop is settled, that is it ends and either the uniqe or the edition side wins
    pub event Settle(name: String, artist: String, winner: String, price:UFix64, dropId: UInt64)

    //emitted when the winning side in the auction changes 
    pub event LeaderChanged(name: String, artist: String, winning: String, dropId:UInt64)

   //A Drop in versus represents a single auction vs an editioned auction
    pub resource Drop {


        pub let metadata: Art.Metadata

        access(contract) let uniqueAuction: @Auction.AuctionItem
        access(contract) let editionAuctions: @Auction.AuctionCollection
        pub let dropID: UInt64

        //this is used to be able to query events for a drop from a given start point
        access(contract) var firstBidBlock: UInt64?
        access(contract) var settledAt: UInt64?


        init( uniqueAuction: @Auction.AuctionItem, 
            editionAuctions: @Auction.AuctionCollection) { 

            Versus.totalDrops = Versus.totalDrops + (1 as UInt64)

            self.dropID=Versus.totalDrops
            self.uniqueAuction <-uniqueAuction
            self.editionAuctions <- editionAuctions
            self.firstBidBlock=nil
            self.settledAt=nil
            self.metadata=self.uniqueAuction.getAuctionStatus().metadata!
        }
            
        destroy(){
            log("Destroy versus")
            destroy self.uniqueAuction
            destroy self.editionAuctions
            emit DropDestroyed(dropId: self.dropID)
        }


        //Returns a DropStatus struct that could be used in a script to show information about the drop
        pub fun getDropStatus() : DropStatus {
            let uniqueRef = &self.uniqueAuction as &Auction.AuctionItem
            let editionRef= &self.editionAuctions as &Auction.AuctionCollection

            let editionStatuses= editionRef.getAuctionStatuses()
            var editionPrice:UFix64= 0.0

            let editionDropAcutionStatus: {UInt64:DropAuctionStatus} = {}
            for es in editionStatuses.keys {
                var status=editionStatuses[es]!
                editionDropAcutionStatus[es] = DropAuctionStatus(status)
                editionPrice = editionPrice + status.price
            }

            let uniqueStatus=uniqueRef.getAuctionStatus()

            var winningStatus=""
            var difference=0.0
            if editionPrice > uniqueStatus.price {
                winningStatus="EDITIONED"
                difference = editionPrice - uniqueStatus.price 
            } else if (editionPrice == uniqueStatus.price) {
                winningStatus="TIE"
                difference=0.0
            } else {
                difference=uniqueStatus.price - editionPrice
                winningStatus="UNIQUE"
            }

            let block=getCurrentBlock()
            let time=Fix64(block.timestamp)

            var started = uniqueStatus.startTime < time 
            var active=true
            if !started {
                active=false
            } else if uniqueStatus.completed {
                active=false
            } else if uniqueStatus.expired && winningStatus != "TIE" {
                active=false
            }
            
            return DropStatus(
                dropId: self.dropID,
                uniqueStatus: uniqueStatus,
                editionsStatuses: editionDropAcutionStatus, 
                editionPrice: editionPrice,
                status: winningStatus,
                firstBidBlock: self.firstBidBlock,
                difference: difference,
                metadata: self.metadata,
                settledAt: self.settledAt,
                active: active
            )
        }

        pub fun settle(cutPercentage:UFix64, vault: Capability<&{FungibleToken.Receiver}> ) {
            let status=self.getDropStatus()

            if status.settled {
                panic("Drop has already been settled")
            }

            if status.expired == false {
                panic("Auction has not completed yet")
            }

            let winning=status.winning
            var price=0.0
            if winning == "UNIQUE" {
                self.uniqueAuction.settleAuction(cutPercentage: cutPercentage, cutVault: vault)
                self.cancelAllEditionedAuctions()
                price=status.uniquePrice
            } else if winning == "EDITIONED" {
                self.uniqueAuction.returnAuctionItemToOwner()
                self.settleAllEditionedAuctions()
                price=status.editionPrice
            } else {
                panic("tie")
            }

            self.settledAt=getCurrentBlock().height
            emit Settle(name: status.metadata.name, artist: status.metadata.artist, winner: winning, price: price, dropId: self.dropID )
        }


        pub fun settleAllEditionedAuctions() {
           for id in self.editionAuctions.keys() {
               self.editionAuctions.settleAuction(id)
           } 
        }

        pub fun cancelAllEditionedAuctions() {
           for id in self.editionAuctions.keys() {
               self.editionAuctions.cancelAuction(id)
           } 
        }
        
        //place a bid on a given auction
        pub fun placeBid(
            auctionId:UInt64,
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&{FungibleToken.Receiver}>, 
            collectionCap: Capability<&{Art.CollectionPublic}>, 
            minimumTimeRemaining: UFix64) {

            pre {
                collectionCap.check() == true : "Collection capability must be linked"
                vaultCap.check() == true : "Vault capability must be linked"
            }

            let dropStatus = self.getDropStatus()
            let block=getCurrentBlock()
            let time=Fix64(block.timestamp)

            if dropStatus.startTime > time {
                panic("The drop has not started")
            }

            if dropStatus.endTime < time && dropStatus.winning != "TIE" {
                panic("This drop has ended")
            }
           
            let bidEndTime = time + Fix64(minimumTimeRemaining)

            //we save the time of the first bid so that it can be used to fetch events from that given block
            if self.firstBidBlock == nil {
                self.firstBidBlock=block.height
            }

            //We need to extend the auction since there is too little time left. If we did not do this a late user could potentially win with a cheecky bid
            if dropStatus.endTime < bidEndTime {
                let extendWith=bidEndTime - dropStatus.endTime
                emit DropExtended(name: dropStatus.metadata.name, artist: dropStatus.metadata.artist, dropId:self.dropID, extendWith: extendWith, extendTo: bidEndTime)
                self.extendDropWith(UFix64(extendWith))
            }

            let bidPrice = bidTokens.balance
            let bidder=vaultCap.borrow()!.owner!.address

            var edition:String="1 of 1"

            var price:UFix64=0.0
            //the bid is on a unique auction so we place the bid there
            if self.uniqueAuction.auctionID == auctionId {
                let auctionRef = &self.uniqueAuction as &Auction.AuctionItem
                auctionRef.placeBid(bidTokens: <- bidTokens, vaultCap:vaultCap, collectionCap:collectionCap)
            } else {
                let editionStatus=dropStatus.editionsStatuses[auctionId]!
                edition=editionStatus.edition.toString().concat( " of ").concat(editionStatus.maxEdition.toString())
                let editionsRef = &self.editionAuctions as &Auction.AuctionCollection 
                editionsRef.placeBid(id: auctionId, bidTokens: <- bidTokens, vaultCap:vaultCap, collectionCap:collectionCap)
            }
            
            emit Bid(name: dropStatus.metadata.name, artist:dropStatus.metadata.artist, edition: edition, bidder:bidder, price:bidPrice, dropId:self.dropID, auctionId:auctionId)

            let dropStatusAfter = self.getDropStatus()
            if dropStatus.winning != dropStatusAfter.winning {
                emit LeaderChanged(name:dropStatus.metadata.name, artist: dropStatus.metadata.artist, winning:dropStatusAfter.winning, dropId: self.dropID)
            }
        }

        //This would make it possible to extend the drop with more time from an admin interface
        //here we just delegate to the auctions and extend them all
        pub fun extendDropWith(_ time: UFix64) {
            log("Drop extended with duration")
            self.uniqueAuction.extendWith(time)
            self.editionAuctions.extendAllAuctionsWith(time)
        }
        
    }


    //this is a simpler version of the Acution status since we do not need to duplicate all the fields
    //edition and maxEidtion will not be kept here after the auction has been settled.
    //Really not sure on how to handle showing historic drops so for now I will just leave it as it is
    pub struct DropAuctionStatus {
        pub let id: UInt64
        pub let price : UFix64
        pub let bidIncrement : UFix64
        pub let bids : UInt64
        pub let edition: UInt64
        pub let maxEdition: UInt64
        pub let leader: Address?
        pub let minNextBid: UFix64
        init(_ auctionStatus: Auction.AuctionStatus) {
                self.price=auctionStatus.price
                self.bidIncrement=auctionStatus.bidIncrement
                self.bids=auctionStatus.bids
                self.edition=auctionStatus.metadata?.edition  ?? (0 as UInt64)
                self.maxEdition=auctionStatus.metadata?.maxEdition ?? (0 as UInt64)
                self.leader=auctionStatus.leader
                self.minNextBid=auctionStatus.minNextBid
                self.id=auctionStatus.id
            }
    }

    //The struct that holds status information of a drop. 
    //this probably has some duplicated data that could go away. like do you need both a settled and settledAt? and active?
    pub struct DropStatus {
        pub let dropId: UInt64
        pub let uniquePrice: UFix64
        pub let editionPrice: UFix64
        pub let difference: UFix64
        pub let endTime: Fix64
        pub let startTime: Fix64
        pub let uniqueStatus: DropAuctionStatus
        pub let editionsStatuses: {UInt64: DropAuctionStatus}
        pub let winning: String
        pub let active: Bool
        pub let timeRemaining: Fix64
        pub let firstBidBlock:UInt64?
        pub let metadata: Art.Metadata
        pub let settled: Bool
        pub let expired: Bool
        pub let settledAt: UInt64?

        init(
            dropId: UInt64,
            uniqueStatus: Auction.AuctionStatus,
            editionsStatuses: {UInt64: DropAuctionStatus},
            editionPrice: UFix64, 
            status: String,
            firstBidBlock:UInt64?,
            difference:UFix64,
            metadata: Art.Metadata,
            settledAt: UInt64?,
            active: Bool
            ) {
                self.dropId=dropId
                self.uniqueStatus=DropAuctionStatus(uniqueStatus)
                self.editionsStatuses=editionsStatuses
                self.uniquePrice= uniqueStatus.price
                self.editionPrice= editionPrice
                self.endTime=uniqueStatus.endTime
                self.startTime=uniqueStatus.startTime
                self.timeRemaining=uniqueStatus.timeRemaining
                self.active=active
                self.winning=status
                self.firstBidBlock=firstBidBlock
                self.difference=difference
                self.metadata=metadata
                self.settled=uniqueStatus.completed
                self.expired=uniqueStatus.expired
                self.settledAt=settledAt

            }
    }

    //An resource interface that everybody can access through a public capability.
    pub resource interface PublicDrop {

        pub fun getAllStatuses(): {UInt64: DropStatus}
        pub fun getStatus(dropId: UInt64): DropStatus

        pub fun getArt(dropId: UInt64): String

        pub fun placeBid(
            dropId: UInt64, 
            auctionId:UInt64,
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&{FungibleToken.Receiver}>, 
            collectionCap: Capability<&{Art.CollectionPublic}>
        )

    }

    pub resource interface AdminDrop {

        pub fun createDrop(
             nft: @NonFungibleToken.NFT,
             editions: UInt64,
             minimumBidIncrement: UFix64, 
             minimumBidUniqueIncrement: UFix64,
             startTime: UFix64, 
             startPrice: UFix64,  //TODO: seperate startPrice for unique and edition
             vaultCap: Capability<&{FungibleToken.Receiver}>, 
             artAdmin: &Art.Administrator)

        pub fun settle(_ dropId: UInt64)
    }

    pub resource DropCollection: PublicDrop, AdminDrop {

        pub var drops: @{UInt64: Drop}

        //it is possible to adjust the cutPercentage if you own a Versus.DropCollection
        pub(set) var cutPercentage:UFix64 

        pub let marketplaceVault: Capability<&{FungibleToken.Receiver}>

        //NFTs that are not sold are put here when a bid is settled.  
        pub let marketplaceNFTTrash: Capability<&{Art.CollectionPublic}>

        //naming things are hard...
        pub(set) var minimumTimeRemainingAfterBidOrTie: UFix64

        //make it possible to change the standard drop length from the admin gui
        pub(set) var dropLength: UFix64

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
        pub fun createDrop(
             nft: @NonFungibleToken.NFT,
             editions: UInt64,
             minimumBidIncrement: UFix64, 
             minimumBidUniqueIncrement: UFix64,
             startTime: UFix64, 
             startPrice: UFix64,  //TODO: seperate startPrice for unique and edition
             vaultCap: Capability<&{FungibleToken.Receiver}>, 
             artAdmin: &Art.Administrator) {

            pre {
                vaultCap.check() == true : "Vault capability should exist"
            }

            let art <- nft as! @Art.NFT

            let metadata= art.metadata
            //Sending in a NFTEditioner capability here and using that instead of this loop would probably make sense. 
            let editionedAuctions <- Auction.createAuctionCollection( 
                marketplaceVault: self.marketplaceVault , 
                cutPercentage: self.cutPercentage)

            var currentEdition=(1 as UInt64)
            while currentEdition <= editions {
                editionedAuctions.createAuction(
                    token: <- artAdmin.makeEdition(original: &art as &Art.NFT, edition: currentEdition, maxEdition: editions),
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
                minimumBidIncrement: minimumBidUniqueIncrement,
                auctionLength: self.dropLength,
                auctionStartTime: startTime,
                startPrice: startPrice,
                collectionCap: self.marketplaceNFTTrash,
                vaultCap: vaultCap
            )
            
            let drop  <- create Drop(uniqueAuction: <- item, editionAuctions:  <- editionedAuctions)
            emit DropCreated(name: metadata.name, artist: metadata.artist,  editions: editions, owner: vaultCap.borrow()!.owner!.address, dropId: drop.dropID)

            let oldDrop <- self.drops[drop.dropID] <- drop
            destroy oldDrop
        }



        //Get all the drop statuses
        pub fun getAllStatuses(): {UInt64: DropStatus} {
            var dropStatus: {UInt64: DropStatus }= {}
            for id in self.drops.keys {
                let itemRef = &self.drops[id] as? &Drop
                dropStatus[id] = itemRef.getDropStatus()
            }
            return dropStatus

        }

        access(contract) fun getDrop(_ dropId:UInt64) : &Drop {
            pre {
                self.drops[dropId] != nil:
                    "drop doesn't exist"
            }
            return &self.drops[dropId] as &Drop
        }

        pub fun getStatus(dropId:UInt64): DropStatus {
            return self.getDrop(dropId).getDropStatus()
        }

        //get the art for this drop
        pub fun getArt(dropId:UInt64) : String {
            let drop= self.getDrop(dropId)
            let uniqueRef = &drop.uniqueAuction as &Auction.AuctionItem
            return uniqueRef.content()!
        }

        //settle a drop
        pub fun settle(_ dropId: UInt64) {
            self.getDrop(dropId).settle(cutPercentage: self.cutPercentage, vault: self.marketplaceVault)
       }

        //place a bid, will just delegate to the method in the drop collection
        pub fun placeBid(
            dropId: UInt64, 
            auctionId:UInt64,
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&{FungibleToken.Receiver}>, 
            collectionCap: Capability<&{Art.CollectionPublic}>
        ) {
            self.getDrop(dropId).placeBid(
                auctionId: auctionId, 
                bidTokens: <- bidTokens, 
                vaultCap: vaultCap, 
                collectionCap:collectionCap, 
                minimumTimeRemaining: self.minimumTimeRemainingAfterBidOrTie
            )
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
                if status.active != false {
                    return status
                }
            } 
        } 
        return nil
    }

 
    //An Administrator resource that is stored as a private capability. That capability will be given to another account using a capability receiver
    pub resource Administrator {
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
            return <- collection
        }
    }


    //The interface used to add a Administrator capability to a client
    pub resource interface VersusAdminClient {
        pub fun addCapability(_ cap: Capability<&Administrator>)
    }

    //The versus admin resource that a client will create and store, then link up a public VersusAdminClient
    pub resource VersusAdmin: VersusAdminClient {

        access(self) var server: Capability<&Administrator>?

        init() {
            self.server = nil
        }

         pub fun addCapability(_ cap: Capability<&Administrator>) {
            pre {
                cap.check() : "Invalid server capablity"
                self.server == nil : "Server already set"
            }
            self.server = cap
        }

        //make it possible to create a versus marketplace. Will just delegate to the administrator
        pub fun createVersusMarketplace(
            marketplaceVault: Capability<&{FungibleToken.Receiver}>,
            marketplaceNFTTrash: Capability<&{Art.CollectionPublic}>,
            cutPercentage: UFix64,
            dropLength: UFix64, 
            minimumTimeRemainingAfterBidOrTie: UFix64) :@DropCollection {

            pre {
                self.server != nil: 
                    "Cannot create versus marketplace if server is not set"
            }
            return <- self.server!.borrow()!.createVersusDropCollection(
                marketplaceVault: marketplaceVault, 
                marketplaceNFTTrash: marketplaceNFTTrash, 
                cutPercentage: cutPercentage, 
                dropLength: dropLength, 
                minimumTimeRemainingAfterBidOrTie: minimumTimeRemainingAfterBidOrTie
            )
        }
    }

    //make it possible for a user that wants to be a versus admin to create the client
    pub fun createAdminClient(): @VersusAdmin {
        return <- create VersusAdmin()
    }
    


    //initialize all the paths and create and link up the admin proxy
    init() {
        self.totalDrops = (0 as UInt64)

        self.CollectionPublicPath= /public/versusCollection
        self.CollectionStoragePath= /storage/versusCollection
        self.VersusAdminClientPublicPath= /public/versusAdminClient
        self.VersusAdminClientStoragePath=/storage/versusAdminClient
        self.VersusAdministratorStoragePath=/storage/versusAdmin
        self.VersusAdministratorPrivatePath=/private/versusAdmin

        self.account.save(<- create Administrator(), to: self.VersusAdministratorStoragePath)
        self.account.link<&Administrator>(self.VersusAdministratorPrivatePath, target: self.VersusAdministratorStoragePath)
    }
     
}
 