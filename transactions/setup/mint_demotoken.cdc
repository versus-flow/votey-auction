
import FungibleToken from 0xee82856bf20e2aa6
import DemoToken from 0x179b6b1cb6755e31


transaction(account: Address, amount: UFix64) {

    // public Vault reciever references for both accounts
    let accountRef: &{FungibleToken.Receiver}

    // reference to the DemoToken administrator
    let minterRef: &DemoToken.Minter
    
    prepare(acct: AuthAccount) {
        let account = getAccount(account)

        self.accountRef = account.getCapability(/public/DemoTokenReceiver)!
                        .borrow<&{FungibleToken.Receiver}>()
                        ?? panic("Could not borrow Account 2's vault reference")
        
        // get the stored Minter reference from account 2
        self.minterRef = acct.borrow<&DemoToken.Minter>(from: /storage/DemoTokenMinter)
            ?? panic("Could not borrow owner's vault minter reference")
    }

    execute {
        // mint tokens for both accounts
        self.accountRef.deposit(from: <-self.minterRef.mintTokens(amount: amount))

        log("Minted new DemoTokens for account sent in as argument")
    }
}
 