
//a copy of the settle contract on testnet

//testnet
import Versus from 0xbc08417e9d472f2e

/*
Transaction to settle/finish off an auction. Has to be signed by the owner of the versus marketplace
 */
transaction(dropId: UInt64) {

    let client: &Versus.Admin
    prepare(account: AuthAccount) {

        self.client = account.borrow<&Versus.Admin>(from: Versus.VersusAdminStoragePath) ?? panic("could not load versus admin")
    }

    execute {
        self.client.settle(dropId)
    }
}
 
