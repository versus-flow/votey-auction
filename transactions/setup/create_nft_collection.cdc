// This transaction creates an empty NFT Collection for the signer
// and publishes a capability to the collection in storage

import NonFungibleToken from 0x01cf0e2f2f715450
import Art from 0xf3fcd2c1a78f5eee

transaction {

    prepare(acct: AuthAccount) {
        // store an empty NFT Collection in account storage
        acct.save<@NonFungibleToken.Collection>(<- Art.createEmptyCollection(), to: /storage/ArtCollection)

        // publish a capability to the Collection in storage
        acct.link<&{NonFungibleToken.CollectionPublic}>(/public/ArtCollection, target: /storage/ArtCollection)

        log("Created a new empty collection and published a reference")
    }
}
 