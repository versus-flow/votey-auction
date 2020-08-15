// This transaction creates an empty NFT Collection for the signer
// and publishes a capability to the collection in storage

import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0x01cf0e2f2f715450
import DemoToken from 0x179b6b1cb6755e31
import Rocks from 0xf3fcd2c1a78f5eee
import VoteyAuction from 0xe03daebed8ca0615
// Contract Deployment:
// Acct 1 - 0x01cf0e2f2f715450 - NonFungibleToken.cdc
// Acct 2 - 0x179b6b1cb6755e31 - DemoToken.cdc
// Acct 3 - 0xf3fcd2c1a78f5eee - Rocks.cdc
// Acct 4 - 0xe03daebed8ca0615 - Auction.cdc
transaction {

    prepare(account: AuthAccount) {
        // create a new sale object     
        // initializing it with the reference to the owner's Vault

        let marketplaceReceiver=account.getCapability<&{FungibleToken.Receiver}>(/public/DemoTokenReceiver)!

        let auction <- VoteyAuction.createAuctionCollection(
            marketplaceVault: marketplaceReceiver,
            cutPercentage: UFix64(0.15)
        )

        // store the sale resource in the account for storage
        account.save(<-auction, to: /storage/NFTAuction)

        // create a public capability to the sale so that others
        // can call it's methods
        account.link<&{VoteyAuction.AuctionPublic}>(
            /public/NFTAuction,
            target: /storage/NFTAuction
        )

        log("Auction Collection and public capability created.")
    }
}
 