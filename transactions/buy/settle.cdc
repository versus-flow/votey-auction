
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

    let versusRef: &Versus.DropCollection
    let artRef:&NonFungibleToken.Collection
    prepare(account: AuthAccount) {

        self.versusRef = account.borrow<&Versus.DropCollection>(from: Versus.CollectionStoragePath) ?? panic("Could not get versus storage")
        self.artRef=account.borrow<&NonFungibleToken.Collection>(from: Art.CollectionStoragePath)!   
    }

    execute {
        self.versusRef.settle(dropId)
        for key in self.artRef.ownedNFTs.keys{
          log("burning art with key=".concat(key.toString()))
          destroy <- self.artRef.ownedNFTs.remove(key: key)
        }
          //should maybe consider to delete the trash here
    }
}
 