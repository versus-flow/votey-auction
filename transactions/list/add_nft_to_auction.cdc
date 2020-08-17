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

//TODO use this
transaction(auction: Address, tokenID: UInt64, startPrice: UFix64) {
    prepare(account: AuthAccount) {


         // borrow a reference to the entire NFT Collection functionality (for withdrawing)
        let accountCollectionRef = account.borrow<&NonFungibleToken.Collection>(from: /storage/RockCollection)!

        // get the public Capability for the signer's NFT collection (for the auction)
        let publicCollectionCap = account.getCapability<&{NonFungibleToken.CollectionPublic}>(/public/RockCollection)
        ?? panic("Unable to borrow the CollectionPublic capability")

        // Get the array of token IDs in the account's collection
        let collectionIDs = accountCollectionRef.getIDs()

        let vaultCap = account.getCapability<&{FungibleToken.Receiver}>(/public/DemoTokenReceiver)??
            panic("Unable to borrow the Vault Receiver capability")

        let auctionAccount= getAccount(auction)
       //get the auctionCollectionReference to add the item to
        let auctionCollectionRef = auctionAccount.getCapability(/public/NFTAuction)!
                         .borrow<&{VoteyAuction.AuctionPublic}>()
                         ?? panic("Could not borrow seller's sale reference")

        log(collectionIDs)

            // Create an empty bid Vault for the auction
            let bidVault <- DemoToken.createEmptyVault()

            // withdraw the NFT from the collection that you want to sell
            // and move it into the transaction's context
            let NFT <- accountCollectionRef.withdraw(withdrawID: tokenID)


            // list the token for sale by moving it into the sale resource
            auctionCollectionRef.createAuction(
                token: <-NFT,
                minimumBidIncrement: UFix64(5),
                auctionLengthInBlocks: UInt64(2),
                startPrice: startPrice,
                bidVault: <-bidVault,
                collectionCap: publicCollectionCap,
                vaultCap: vaultCap
            )
    }
}
 