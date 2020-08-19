
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0x01cf0e2f2f715450
import DemoToken from 0x179b6b1cb6755e31
import Art from 0xf3fcd2c1a78f5eee
import Auction from 0xe03daebed8ca0615


pub contract Versus {
   init() {
        self.totalDrops = UInt64(0)
    }

    pub var totalDrops: UInt64

    pub fun createVersusDropCollection(
        marketplaceVault: Capability<&{FungibleToken.Receiver}>,
        cutPercentage: UFix64,
        dropLength: UInt64, 
        minimumBlockRemainingAfterBidOrTie: UInt64): @DropCollection {
        let collection <- create DropCollection(
            marketplaceVault: marketplaceVault, 
            cutPercentage: cutPercentage,
            dropLength: dropLength,
            minimumBlockRemainingAfterBidOrTie:minimumBlockRemainingAfterBidOrTie
        )
        return <- collection
    }

    pub resource Drop {

        pub let uniqueAuction: @Auction.AuctionItem
        pub let editionAuctions: @Auction.AuctionCollection
        pub let dropID: UInt64
        // TODO: fix start block over then current block 


        init( uniqueAuction: @Auction.AuctionItem, editionAuctions: @Auction.AuctionCollection) {
             Versus.totalDrops = Versus.totalDrops + UInt64(1)

            self.dropID=Versus.totalDrops
            self.uniqueAuction <-uniqueAuction
            self.editionAuctions <- editionAuctions
        }
            
        destroy(){
            destroy self.uniqueAuction
            destroy self.editionAuctions
        }

        pub fun getDropStatus() : DropStatus {

            let uniqueRef = &self.uniqueAuction as &Auction.AuctionItem
            let editionRef= &self.editionAuctions as &Auction.AuctionCollection

            let editionStatuses= editionRef.getAuctionStatuses()
            var sum:UFix64= UFix64(0)
            for es in editionStatuses.keys {
                sum = sum + editionStatuses[es]!.price
            }

            return DropStatus(
                dropId: self.dropID,
                uniqueStatus: uniqueRef.getAuctionStatus(),
                editionsStatuses: editionStatuses, 
                editionPrice: sum
            )
        }

        pub fun placeBid(
            auctionId:UInt64,
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&{FungibleToken.Receiver}>, 
            collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>, 
            minimumBlockRemaining: UInt64) {

            let dropStatus = self.getDropStatus()
            let currentBlockHeight=getCurrentBlock().height

            if(dropStatus.uniqueStatus.startBlock > currentBlockHeight) {
                panic("The drop has not started")
            }
            if dropStatus.endBlock < currentBlockHeight && dropStatus.winning() != "TIE" {
                panic("This drop has ended")
            }
           
            let currentEndBlock = dropStatus.endBlock
            let bidEndBlock = currentBlockHeight + minimumBlockRemaining

            if currentEndBlock < bidEndBlock {
                self.extendDropWith(bidEndBlock - currentEndBlock)
            }
            if self.uniqueAuction.auctionID == auctionId {
                let auctionRef = &self.uniqueAuction as &Auction.AuctionItem
                auctionRef.placeBid(bidTokens: <- bidTokens, vaultCap:vaultCap, collectionCap:collectionCap)
            } else {
                let editionsRef = &self.editionAuctions as &Auction.AuctionCollection 
                editionsRef.placeBid(id: auctionId, bidTokens: <- bidTokens, vaultCap:vaultCap, collectionCap:collectionCap)
            }
        }

        pub fun extendDropWith(_ block: UInt64) {
            log("Drop extended with duration")
            log(block)
            self.uniqueAuction.extendWith(block)
            self.editionAuctions.extendAllAuctionsWith(block)
        }
        
    }

    pub struct DropStatus {
        pub let dropId: UInt64
        pub let uniquePrice: UFix64
        pub let editionPrice: UFix64
        pub let endBlock: UInt64
        pub let uniqueStatus: Auction.AuctionStatus
        pub let editionsStatuses: {UInt64: Auction.AuctionStatus}

        pub fun winning(): String {
            if self.uniquePrice > self.editionPrice {
                return "UNIQUE"
            } else if ( self.uniquePrice== self.editionPrice) {
                return "TIE"
            } else {
                return "EDITIONED"
            }
        }

        init(
            dropId: UInt64,
            uniqueStatus: Auction.AuctionStatus,
            editionsStatuses: {UInt64: Auction.AuctionStatus},
            editionPrice: UFix64
            ) {
                self.dropId=dropId
                self.uniqueStatus=uniqueStatus
                self.editionsStatuses=editionsStatuses
                self.uniquePrice= uniqueStatus.price
                self.editionPrice= editionPrice
                self.endBlock=uniqueStatus.endBlock
            }
    }

    pub resource interface PublicDrop {
          pub fun createDrop(
             uniqueArt: @NonFungibleToken.NFT, 
             editionsArt: @NonFungibleToken.Collection,
             minimumBidIncrement: UFix64, 
             startBlock: UInt64, 
             startPrice: UFix64,  
             collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>, 
             vaultCap: Capability<&{FungibleToken.Receiver}>)

        pub fun getAllStatuses(): {UInt64: DropStatus}
        pub fun getStatus(dropId: UInt64): DropStatus

        pub fun placeBid(
            dropId: UInt64, 
            auctionId:UInt64,
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&{FungibleToken.Receiver}>, 
            collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>
        )

    }

    pub resource DropCollection: PublicDrop {

        pub var drops: @{UInt64: Drop}
        pub var cutPercentage:UFix64 
        pub let marketplaceVault: Capability<&{FungibleToken.Receiver}>

        pub let minimumBlockRemainingAfterBidOrTie: UInt64
        pub let dropLength: UInt64

        init(
            marketplaceVault: Capability<&{FungibleToken.Receiver}>, 
            cutPercentage: UFix64,
            dropLength: UInt64,
            minimumBlockRemainingAfterBidOrTie:UInt64
        ) {
            self.cutPercentage= cutPercentage
            self.marketplaceVault = marketplaceVault
            self.dropLength=dropLength
            self.minimumBlockRemainingAfterBidOrTie=minimumBlockRemainingAfterBidOrTie
            self.drops <- {}
        }

        pub fun createDrop(
             uniqueArt: @NonFungibleToken.NFT, 
             editionsArt: @NonFungibleToken.Collection,
             minimumBidIncrement: UFix64, 
             startBlock: UInt64, 
             startPrice: UFix64,  
             collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>, 
             vaultCap: Capability<&{FungibleToken.Receiver}>) {

            let item <- Auction.createStandaloneAuction(
                token: <-uniqueArt,
                minimumBidIncrement: minimumBidIncrement,
                auctionLengthInBlocks: self.dropLength,
                auctionStartBlock: startBlock,
                startPrice: startPrice,
                collectionCap: collectionCap,
                vaultCap: vaultCap
            )

            let editionedAuctions <- Auction.createAuctionCollection( marketplaceVault: self.marketplaceVault , cutPercentage: self.cutPercentage)


            for editionId in editionsArt.getIDs() {
                let art <- editionsArt.withdraw(withdrawID: editionId)
                editionedAuctions.createAuction(
                    token: <- art, 
                    minimumBidIncrement: minimumBidIncrement, 
                    auctionLengthInBlocks: self.dropLength,
                    auctionStartBlock:startBlock,
                    startPrice: startPrice, 
                    collectionCap: collectionCap, 
                    vaultCap: vaultCap)
            }
            destroy editionsArt
            
            let drop  <- create Drop(uniqueAuction: <- item, editionAuctions:  <- editionedAuctions)

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

            if itemRef.uniqueAuction.isAuctionExpired() == false {
                panic("Auction has not completed yet")
            }

            let status=itemRef.getDropStatus()
            let winning=status.winning()
            if winning == "UNIQUE" {
                itemRef.uniqueAuction.settleAuction(cutPercentage: self.cutPercentage, cutVault: self.marketplaceVault)
                itemRef.editionAuctions.cancelAllAuctions()
            }else if winning == "EDITIONED" {
                itemRef.uniqueAuction.returnAuctionItemToOwner()
                itemRef.editionAuctions.settleAllAuctions()
            }else {
                panic("tie")
            }
        }

        pub fun placeBid(
            dropId: UInt64, 
            auctionId:UInt64,
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&{FungibleToken.Receiver}>, 
            collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>
        ) {

            pre {
                self.drops[dropId] != nil:
                    "NFT doesn't exist"
            }
            let drop = &self.drops[dropId] as &Drop
            let minimumBlockRemaining=self.minimumBlockRemainingAfterBidOrTie

            drop.placeBid(auctionId: auctionId, bidTokens: <- bidTokens, vaultCap: vaultCap, collectionCap:collectionCap, minimumBlockRemaining: minimumBlockRemaining)

        }
        destroy() {            
            destroy self.drops
        }
    }
     
}