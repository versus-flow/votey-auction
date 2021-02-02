import FungibleToken from 0xee82856bf20e2aa6
import DemoToken from 0x01cf0e2f2f715450
/*
Setup an address with an empty NFT collection and a FT vault with the given amount of tokens.
Used purely for demo purposes    
 */
transaction(tokens:UFix64) {

    prepare(acct: AuthAccount) {

        //TODO: replace with transaction to mint flow tokens and a seperate for setting up art collection let reciverRef = acct.getCapability(/public/DemoTokenReceiver)

        // create a new empty Vault resource
        let vaultA <- DemoToken.createVaultWithTokens(tokens)

        // store the vault in the accout storage
        acct.save<@FungibleToken.Vault>(<-vaultA, to: /storage/DemoTokenVault)

        // create a public Receiver capability to the Vault
        acct.link<&{FungibleToken.Receiver}>( /public/DemoTokenReceiver, target: /storage/DemoTokenVault)

        // create a public Balance capability to the Vault
        acct.link<&{FungibleToken.Balance}>( /public/DemoTokenBalance, target: /storage/DemoTokenVault)

    }

}
 