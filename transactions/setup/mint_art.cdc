
//testnet
import FungibleToken from 0x9a0766d93b6608b7
import NonFungibleToken from 0x631e88ae7f1d7c20
import Content, Art, Auction, Versus from 0x6bb8a74d4db97b46


//local emulator
//import FungibleToken from 0xee82856bf20e2aa6
//import Art, Versus from 0xf8d6e0586b0a20c7

transaction(
    artist: Address,
    artistName: String, 
    artName: String, 
    content: String, 
    description: String) {

    let artistCollection: Capability<&{Art.CollectionPublic}>
    let client: &Versus.VersusAdmin

    prepare(account: AuthAccount) {

        self.client = account.borrow<&Versus.VersusAdmin>(from: Versus.VersusAdminClientStoragePath) ?? panic("could not load versus admin")
        self.artistCollection= getAccount(artist).getCapability<&{Art.CollectionPublic}>(Art.CollectionPublicPath)
    }

    execute {
        let art <-  self.client.mintArt(artist: artist, artistName: artistName, artName: artName, content:content, description: description)
        self.artistCollection.borrow()!.deposit(token: <- art)
    }
}

