
//a copy of the settle contract on testnet

//testnet
import FungibleToken from 0x9a0766d93b6608b7
import NonFungibleToken from 0x631e88ae7f1d7c20
import Versus from 0x6bb8a74d4db97b46

/*
Transaction to settle/finish off an auction. Has to be signed by the owner of the versus marketplace
 */
transaction(dropId: UInt64) {
    // reference to the buyer's NFT collection where they
    // will store the bought NFT

    let versusRef: &Versus.DropCollection
    prepare(account: AuthAccount) {

        self.versusRef = account.borrow<&Versus.DropCollection>(from: Versus.CollectionStoragePath) ?? panic("Could not get versus storage")
    }

    execute {
        self.versusRef.settle(dropId)
          //should maybe consider to delete the trash here
    }
}
 
