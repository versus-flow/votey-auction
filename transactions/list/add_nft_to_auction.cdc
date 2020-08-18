import NonFungibleToken from 0x01cf0e2f2f715450
import FungibleToken from 0xee82856bf20e2aa6
import DemoToken from 0x179b6b1cb6755e31
import Auction from 0xe03daebed8ca0615

transaction(auction: Address, tokenID: UInt64, startPrice: UFix64, auctionLength: UInt64) {
    prepare(account: AuthAccount) {


         // borrow a reference to the entire NFT Collection functionality (for withdrawing)
        let accountCollectionRef = account.borrow<&NonFungibleToken.Collection>(from: /storage/ArtCollection)!

        // get the public Capability for the signer's NFT collection (for the auction)
        let publicCollectionCap = account.getCapability<&{NonFungibleToken.CollectionPublic}>(/public/ArtCollection)!
        if !publicCollectionCap.check()  {
           panic("Unable to borrow the CollectionPublic capability")
        }

        // Get the array of token IDs in the account's collection
        let collectionIDs = accountCollectionRef.getIDs()

        let vaultCap = account.getCapability<&{FungibleToken.Receiver}>(/public/DemoTokenReceiver)!
        if !vaultCap.check() {
            panic("Unable to borrow the Vault Receiver capability")
         }

        let auctionAccount= getAccount(auction)
       //get the auctionCollectionReference to add the item to
        let auctionCollectionRef = auctionAccount.getCapability(/public/NFTAuction)!
                         .borrow<&{Auction.AuctionPublic}>()
                         ?? panic("Could not borrow seller's sale reference")

            // Create an empty bid Vault for the auction
            let bidVault <- DemoToken.createEmptyVault()

            // withdraw the NFT from the collection that you want to sell
            // and move it into the transaction's context
            let NFT <- accountCollectionRef.withdraw(withdrawID: tokenID)


            // list the token for sale by moving it into the sale resource
            auctionCollectionRef.createAuction(
                token: <-NFT,
                minimumBidIncrement: UFix64(5),
                auctionLengthInBlocks: auctionLength,
                startPrice: startPrice,
                bidVault: <-bidVault,
                collectionCap: publicCollectionCap,
                vaultCap: vaultCap
            )
    }
}
 