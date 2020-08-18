// This transaction mints tokens for Accounts 1 and 2 using
// the minter stored on Account 1.

// Signer: Account 1 - 0x01cf0e2f2f715450

import FungibleToken from 0xee82856bf20e2aa6
import DemoToken from 0x179b6b1cb6755e31


// TODO: add argument on capacity here
transaction {

 
    prepare(acct: AuthAccount) {
       
        // borrow a reference to the Administrator resource in Account 2
        let adminRef = acct.borrow<&DemoToken.Administrator>(from: /storage/DemoTokenAdmin)
                            ?? panic("Signer is not the token admin!")
        
        // create a new minter and store it in account storage
        let minter <-adminRef.createNewMinter(allowedAmount: UFix64(1000))
        acct.save<@DemoToken.Minter>(<-minter, to: /storage/DemoTokenMinter)

        // create a capability for the new minter
         acct.link<&DemoToken.Minter>(/public/DemoTokenMinter, target: /storage/DemoTokenMinter)

    }

}
 