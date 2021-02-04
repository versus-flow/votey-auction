import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken, Art, Auction, Versus from 0x01cf0e2f2f715450

/*
    Transaction to make a bid in a marketplace for the given dropId and auctionId

 */
transaction(marketplace: Address, dropId: UInt64, auctionId: UInt64, bidAmount: UFix64) {
    // reference to the buyer's NFT collection where they
    // will store the bought NFT

    let vaultCap: Capability<&{FungibleToken.Receiver}>
    let collectionCap: Capability<&{Art.CollectionPublic}> 
    // Vault that will hold the tokens that will be used
    // to buy the NFT
    let temporaryVault: @FungibleToken.Vault

    prepare(account: AuthAccount) {

        // get the references to the buyer's Vault and NFT Collection receiver
        var collectionCap = account.getCapability<&{Art.CollectionPublic}>(/public/ArtCollection)

        // if collection is not created yet we make it.
        if !collectionCap.check() {
            // store an empty NFT Collection in account storage
            account.save<@NonFungibleToken.Collection>(<- Art.createEmptyCollection(), to: /storage/ArtCollection)

            // publish a capability to the Collection in storage
            account.link<&{Art.CollectionPublic}>(/public/ArtCollection, target: /storage/ArtCollection)
        }

        self.collectionCap=collectionCap
        
        self.vaultCap = account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
                   
        let vaultRef = account.borrow<&FungibleToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow owner's Vault reference")

        // withdraw tokens from the buyer's Vault
        self.temporaryVault <- vaultRef.withdraw(amount: bidAmount)
    }

    execute {
        // get the read-only account storage of the seller
        let seller = getAccount(marketplace)

        // get the reference to the seller's sale
        let versusRef = seller.getCapability(/public/Versus)
                         .borrow<&{Versus.PublicDrop}>()
                         ?? panic("Could not borrow seller's sale reference")

        versusRef.placeBid(dropId: dropId, auctionId: auctionId, bidTokens: <- self.temporaryVault, vaultCap: self.vaultCap, collectionCap: self.collectionCap)
    }
}
 