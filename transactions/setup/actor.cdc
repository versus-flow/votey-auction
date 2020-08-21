// This transaction will setup and actor in the voting system
// And actor has a Vault with a certain amount of tokens and an empty NFTCollection linked

import FungibleToken from 0xee82856bf20e2aa6
import DemoToken from 0x179b6b1cb6755e31
import Art from 0xf3fcd2c1a78f5eee
import NonFungibleToken from 0x01cf0e2f2f715450

transaction(tokens:UFix64) {

    prepare(acct: AuthAccount) {

        let tokens:UFix64 = 100.0
        let reciverRef = acct.getCapability(/public/DemoTokenReceiver)!
        //If we have a DemoTokenReceiver then we are already set up so just return
        if reciverRef.check<&{FungibleToken.Receiver}>() {
            return
        }

        // create a new empty Vault resource
        let vaultA <- DemoToken.createVaultWithTokens(tokens)

        // store the vault in the accout storage
        acct.save<@FungibleToken.Vault>(<-vaultA, to: /storage/DemoTokenVault)

        // create a public Receiver capability to the Vault
        acct.link<&{FungibleToken.Receiver}>( /public/DemoTokenReceiver, target: /storage/DemoTokenVault)

        // create a public Balance capability to the Vault
        acct.link<&{FungibleToken.Balance}>( /public/DemoTokenBalance, target: /storage/DemoTokenVault)

        // store an empty NFT Collection in account storage
        acct.save<@NonFungibleToken.Collection>(<- Art.createEmptyCollection(), to: /storage/ArtCollection)

        // publish a capability to the Collection in storage
        acct.link<&{NonFungibleToken.CollectionPublic}>(/public/ArtCollection, target: /storage/ArtCollection)
      
    }

}
 