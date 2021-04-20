

//these are testnet 
import FungibleToken from 0x9a0766d93b6608b7
import NonFungibleToken from 0x631e88ae7f1d7c20
import Content, Art, Auction, Versus from 0xbc08417e9d472f2e

//this transaction is run as the account that will host and own the marketplace to set up the 
//versusAdmin client and create the empty content and art collection
transaction() {

    prepare(account: AuthAccount) {

        //create versus admin client
        account.save(<- Versus.createAdminClient(), to:Versus.VersusAdminClientStoragePath)
        account.link<&{Versus.VersusAdminClient}>(Versus.VersusAdminClientPublicPath, target: Versus.VersusAdminClientStoragePath)


    }
}
