
//emulator
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken, Content, Art, Auction, Versus from 0xf8d6e0586b0a20c7

//testnet
//import FungibleToken from 0x9a0766d93b6608b7
//import NonFungibleToken from 0x631e88ae7f1d7c20
//import Versus from 0x1ff7e32d71183db0
/*
Transaction to settle/finish off an auction. Has to be signed by the owner of the versus marketplace
 */
transaction(dropId: UInt64) {
    // reference to the buyer's NFT collection where they
    // will store the bought NFT

    let client: &Versus.VersusAdmin
    prepare(account: AuthAccount) {

        self.client = account.borrow<&Versus.VersusAdmin>(from: Versus.VersusAdminClientStoragePath) ?? panic("could not load versus admin")
    }

    execute {
        self.client.settle(dropId)
          //should maybe consider to delete the trash here
    }
}
 