
//a copy of the settle contract on testnet

//testnet
import Versus from 0xe193e719ae2b5853

/*
Transaction to settle/finish off an auction. Has to be signed by the owner of the versus marketplace
 */
transaction() {

    let client: &Versus.Admin
    prepare(account: AuthAccount) {
        self.client = account.borrow<&Versus.Admin>(from: Versus.VersusAdminStoragePath) ?? panic("could not load versus admin")
    }

    execute {

      let versusStatuses =Versus.getDrops()
      for status in versusStatuses {
        if status.active == false && status.expired==true && status.settledAt == nil {
          self.client.settle(status.dropId)
        }
      } 
    } 
}