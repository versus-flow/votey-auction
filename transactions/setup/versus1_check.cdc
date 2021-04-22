

//local emulator
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken, Content, Art, Auction, Versus from 0xf8d6e0586b0a20c7

//these are testnet 
//import FungibleToken from 0x9a0766d93b6608b7
//import NonFungibleToken from 0x631e88ae7f1d7c20
//import Content, Art, Auction, Versus from 0x1ff7e32d71183db0

//this transaction is run as the account that will host and own the marketplace to set up the 
//versusAdmin client and create the empty content and art collection
transaction() {

    prepare(account: AuthAccount) {


        
        //create versus admin client
        account.save(<- Versus.createAdminClient(), to:Versus.VersusAdminStoragePath)
        account.link<&{Versus.AdminPublic}>(Versus.VersusAdminPublicPath, target: Versus.VersusAdminStoragePath)


    }
}
