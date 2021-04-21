
//a copy of the settle contract on testnet

//testnet
import FungibleToken from 0x9a0766d93b6608b7
import NonFungibleToken from 0x631e88ae7f1d7c20
import Versus from 0xbc08417e9d472f2e

/*
Transaction to settle/finish off an auction. Has to be signed by the owner of the versus marketplace
 */
transaction(dropId: UInt64) {
    // reference to the buyer's NFT collection where they
    // will store the bought NFT

    let versusRef: &Versus.DropCollection
    let artRef:&NonFungibleToken.Collection
    prepare(account: AuthAccount) {

        self.versusRef = account.borrow<&Versus.DropCollection>(from: Versus.CollectionStoragePath) ?? panic("Could not get versus storage")
        self.artRef=account.borrow<&NonFungibleToken.Collection>(from: Art.CollectionStoragePath)!   
    }

    execute {
        self.versusRef.settle(dropId)

        //since settling will return all items not sold to the NFTTrash, we take out the trash here.
        for key in self.artRef.ownedNFTs.keys{
          log("burning art with key=".concat(key.toString()))
          destroy <- self.artRef.ownedNFTs.remove(key: key)
        }

    }
}
 
