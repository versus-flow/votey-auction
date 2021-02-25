

//local emulator
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken, Content, Art, Auction, Versus from 0xf8d6e0586b0a20c7

//these are testnet 
//import FungibleToken from 0x9a0766d93b6608b7
//import NonFungibleToken from 0x631e88ae7f1d7c20
//import Content, Art, Auction, Versus from 0x1ff7e32d71183db0

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


        account.save<@NonFungibleToken.Collection>(<- Art.createEmptyCollection(), to: Art.CollectionStoragePath)
        account.link<&{Art.CollectionPublic}>(Art.CollectionPublicPath, target: Art.CollectionStoragePath)

        let marketplaceNFTTrash=account.getCapability<&{Art.CollectionPublic}>(Art.CollectionPublicPath)

        let versus <- Versus.createVersusDropCollection(
            marketplaceVault: marketplaceReceiver,
            marketplaceNFTTrash:marketplaceNFTTrash,
            cutPercentage: cutPercentage,
            dropLength: dropLength, 
            minimumTimeRemainingAfterBidOrTie: minimumTimeRemainingAfterBidOrTie
        )

        // store the sale resource in the account for storage
        account.save(<-versus, to: Versus.CollectionStoragePath)

        // create a public capability to the sale so that others
        // can call it's methods
        account.link<&{Versus.PublicDrop}>(Versus.CollectionPublicPath, target: Versus.CollectionStoragePath)
        account.save(<- Content.createEmptyCollection(), to: Content.CollectionStoragePath)
        account.link<&Content.Collection>(Content.CollectionPrivatePath, target: Content.CollectionStoragePath)
    }
}
 