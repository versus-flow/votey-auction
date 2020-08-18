// This transaction saves an empty Vault to the signer's
// account storage and creates a public capability
// for the Balance and Receiver interface

import FungibleToken from 0xee82856bf20e2aa6
import DemoToken from 0x179b6b1cb6755e31

transaction{
    
    prepare(acct: AuthAccount) {
        
        // create a new empty Vault resource
        let vaultA <- DemoToken.createEmptyVault()

        // store the vault in the accout storage
        acct.save<@FungibleToken.Vault>(<-vaultA, to: /storage/DemoTokenVault)

        // create a public Receiver capability to the Vault
        acct.link<&{FungibleToken.Receiver}>(
            /public/DemoTokenReceiver,
            target: /storage/DemoTokenVault
        )

        // create a public Balance capability to the Vault
        acct.link<&{FungibleToken.Balance}>(
            /public/DemoTokenBalance,
            target: /storage/DemoTokenVault
        )

        log("Created a Vault and published the references")
        
    }
}
 