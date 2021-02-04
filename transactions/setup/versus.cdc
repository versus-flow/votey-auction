
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken, Content, Art, Auction, Versus from 0x01cf0e2f2f715450

//This transaction setup of a versus marketplace
//Each drop settlement will deposit cutPercentage number of tokens into the signers vault
//Standard dropLength can be set and the number of seconds to postpone the drops on if there is a late bid

// If there is a bid 1 block before it ends it will be extended with minimumTimeRemainingAfterBidOrTie-1 
transaction(cutPercentage: UFix64, dropLength: UFix64, minimumTimeRemainingAfterBidOrTie: UFix64) {

    prepare(account: AuthAccount) {
        // create a new sale object     
        // initializing it with the reference to the owner's Vault


        // Would this fail if the capability was not here? 
        let marketplaceReceiver=account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        if !marketplaceReceiver.check() {
            panic("Cannot borrow vault receiver run the setup/actor transaction first")
        }

         account.save<@NonFungibleToken.Collection>(<- Art.createEmptyCollection(), to: /storage/ArtCollection)
         account.link<&{Art.CollectionPublic}>(/public/ArtCollection, target: /storage/ArtCollection)
         let marketplaceNFTTrash=account.getCapability<&{Art.CollectionPublic}>(/public/ArtCollection)

        let versus <- Versus.createVersusDropCollection(
            marketplaceVault: marketplaceReceiver,
            marketplaceNFTTrash:marketplaceNFTTrash,
            cutPercentage: cutPercentage,
            dropLength: dropLength, 
            minimumTimeRemainingAfterBidOrTie: minimumTimeRemainingAfterBidOrTie
        )

        // store the sale resource in the account for storage
        account.save(<-versus, to: /storage/Versus)

        // create a public capability to the sale so that others
        // can call it's methods
        account.link<&{Versus.PublicDrop}>(
            /public/Versus,
            target: /storage/Versus
        )

        account.save(<- Content.createEmptyCollection(), to: /storage/VersusContent)
        account.link<&Content.Collection>(/private/VersusContent, target: /storage/VersusContent)
    }
}
 