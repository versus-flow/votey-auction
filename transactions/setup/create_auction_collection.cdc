// This transaction creates an empty NFT Collection for the signer
// and publishes a capability to the collection in storage

import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0x01cf0e2f2f715450
import DemoToken from 0x179b6b1cb6755e31
import Art from 0xf3fcd2c1a78f5eee
import Auction from 0xe03daebed8ca0615

transaction {

    prepare(account: AuthAccount) {
        // create a new sale object     
        // initializing it with the reference to the owner's Vault


        // Would this fail if the capability was not here? 
        let marketplaceReceiver=account.getCapability<&{FungibleToken.Receiver}>(/public/DemoTokenReceiver)!
        if !marketplaceReceiver.check() {
            panic("Cannot borrow vault receiver")
        }

        let auction <- Auction.createAuctionCollection(
            marketplaceVault: marketplaceReceiver,
            cutPercentage: UFix64(0.15)
        )

        // store the sale resource in the account for storage
        account.save(<-auction, to: /storage/NFTAuction)

        // create a public capability to the sale so that others
        // can call it's methods
        account.link<&{Auction.AuctionPublic}>(
            /public/NFTAuction,
            target: /storage/NFTAuction
        )

        log("Auction Collection and public capability created.")
    }
}
 