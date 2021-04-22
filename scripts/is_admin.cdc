
//testnet
//import FungibleToken from 0x9a0766d93b6608b7
//import NonFungibleToken from 0x631e88ae7f1d7c20
//import Art from 0x1ff7e32d71183db0

//emulator
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken, Content, Art, Auction, Versus from 0xf8d6e0586b0a20c7

/*
  This script will check an address and print out its an admin
 */
pub fun main(address:Address) : Bool {

    let account=getAccount(address)
    let adminClient: Capability<&{Versus.AdminPublic}> =account.getCapability<&{Versus.AdminPublic}>(Versus.VersusAdminPublicPath) 
    return adminClient.check()

}
