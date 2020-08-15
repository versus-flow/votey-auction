// This transaction creates a new Auction Collection object,
// lists all NFTs for auction, puts it in account storage,
// and creates a public capability to the auction so that 
// others can bid on the tokens.

// Signer - Account 1 - 0x01cf0e2f2f715450

import NonFungibleToken from 0x01cf0e2f2f715450
import FungibleToken from 0xee82856bf20e2aa6
import DemoToken from 0x179b6b1cb6755e31
import VoteyAuction from 0xe03daebed8ca0615

// Contract Deployment:
// Acct 1 - 0x01cf0e2f2f715450 - onflow/NonFungibleToken.cdc
// Acct 2 - 0x179b6b1cb6755e31 - demo-token.cdc
// Acct 3 - 0xf3fcd2c1a78f5eee - rocks.cdc
// Acct 4 - 0xe03daebed8ca0615 - auction.cdc

transaction(artist:Address) {
    prepare(account: AuthAccount) {

        let artistAccount = getAccount(artist)
        // borrow a reference to the entire NFT Collection functionality (for withdrawing)
        let artistCollectionCap = artistAccount.getCapability<&{NonFungibleToken.CollectionPublic}>(/public/RockCollection)!
        let artistCollection= artistCollectionCap.borrow()!
        let artistVault = artistAccount.getCapability<&{FungibleToken.Receiver}>(/public/DemoTokenReceiver)??
            panic("Unable to borrow the Vault Receiver capability")

        // get the public Capability for the signer's NFT collection (for the auction)
        let publicCollectionCap = account.getCapability<&{NonFungibleToken.CollectionPublic}>(/public/RockCollection)
        ?? panic("Unable to borrow the CollectionPublic capability")

        // Get the array of token IDs in the account's collection
        let collectionIDs = artistCollection.getIDs()


        // borrow a reference to the Auction Collection in account storage
        let auctionCollectionRef = account.borrow<&VoteyAuction.AuctionCollection>(from: /storage/NFTAuction)!

        for id in collectionIDs {
            // Create an empty bid Vault for the auction
            let bidVault <- DemoToken.createEmptyVault()

            // withdraw the NFT from the collection that you want to sell
            // and move it into the transaction's context
            let NFT <- artistCollection.withdraw(withdrawID: id)

            // list the token for sale by moving it into the sale resource
            auctionCollectionRef.addTokenToAuctionItems(
                token: <-NFT,
                minimumBidIncrement: UFix64(5),
                auctionLengthInBlocks: UInt64(2),
                startPrice: UFix64(10),
                bidVault: <-bidVault,
                collectionCap: publicCollectionCap,
                vaultCap: artistVault
            )
        }
    }
}
 