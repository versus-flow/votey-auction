

//local emulator

//these are testnet 
import FungibleToken from 0x9a0766d93b6608b7
import NonFungibleToken from 0x631e88ae7f1d7c20
import Content, Art, Auction, Versus from 0xe193e719ae2b5853

//This transactions is run as the owner of the versus contract and links in the client
//ownerAddress is the address that will host the marketplace
transaction(ownerAddress: Address) {

    //versus account
    prepare(account: AuthAccount) {

        let owner= getAccount(ownerAddress)
        let client= owner.getCapability<&{Versus.AdminPublic}>(Versus.VersusAdminPublicPath)
                .borrow() ?? panic("Could not borrow admin client")

        let versusAdminCap=account.getCapability<&Versus.DropCollection>(Versus.CollectionPrivatePath)
        if !versusAdminCap.check() {
            panic("not linked")
        }
        client.addCapability(versusAdminCap)

    }
}
 