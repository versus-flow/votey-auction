
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

    pub fun createVersusDropCollection(marketplaceVault: Capability<&{FungibleToken.Receiver}>,cutPercentage: UFix64): @DropCollection {
        let collection <- create DropCollection(
            marketplaceVault: marketplaceVault, 
            cutPercentage: cutPercentage
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
            return DropStatus(
                uniqueStatus: uniqueRef.getAuctionStatus(),
                editionsStatuses: editionRef.getAuctionStatuses()
            )
        }

        pub fun placeBid(
            auctionId:UInt64,
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&{FungibleToken.Receiver}>, 
            collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>) {
                if self.uniqueAuction.auctionID == auctionId {
                    let auctionRef = &self.uniqueAuction as &Auction.AuctionItem
                    auctionRef.placeBid(bidTokens: <- bidTokens, vaultCap:vaultCap, collectionCap:collectionCap)
                } else {
                    let editionsRef = &self.editionAuctions as &Auction.AuctionCollection 
                    editionsRef.placeBid(id: auctionId, bidTokens: <- bidTokens, vaultCap:vaultCap, collectionCap:collectionCap)
                }
            }
        
    }

    pub struct DropStatus {
        pub let uniqueStatus: Auction.AuctionStatus
        pub let editionsStatuses: {UInt64: Auction.AuctionStatus}
        init(
            uniqueStatus: Auction.AuctionStatus,
            editionsStatuses: {UInt64: Auction.AuctionStatus}
            ) {
                self.uniqueStatus=uniqueStatus
                self.editionsStatuses=editionsStatuses
            }
    }

    pub resource interface PublicDrop {
          pub fun createDrop(
             uniqueArt: @NonFungibleToken.NFT, 
             editionsArt: @NonFungibleToken.Collection,
             editions: UInt64,
             minimumBidIncrement: UFix64, 
             auctionLengthInBlocks: UInt64, 
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

        init(
            marketplaceVault: Capability<&{FungibleToken.Receiver}>, 
            cutPercentage: UFix64
        ) {
            self.cutPercentage= cutPercentage
            self.marketplaceVault = marketplaceVault
            self.drops <- {}
        }

        pub fun createDrop(
             uniqueArt: @NonFungibleToken.NFT, 
             editionsArt: @NonFungibleToken.Collection,
             editions: UInt64,
             minimumBidIncrement: UFix64, 
             auctionLengthInBlocks: UInt64, 
             startPrice: UFix64,  
             collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>, 
             vaultCap: Capability<&{FungibleToken.Receiver}>) {

            let item <- Auction.createStandaloneAuction(
                token: <-uniqueArt,
                minimumBidIncrement: minimumBidIncrement,
                auctionLengthInBlocks: auctionLengthInBlocks,
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
                    auctionLengthInBlocks: auctionLengthInBlocks, 
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
            drop.placeBid(auctionId: auctionId, bidTokens: <- bidTokens, vaultCap: vaultCap, collectionCap:collectionCap)

        }
        destroy() {            
            destroy self.drops
        }
    }
     
}