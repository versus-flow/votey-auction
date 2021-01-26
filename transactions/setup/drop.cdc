import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken, DemoToken, Art, Auction, Versus from 0x01cf0e2f2f715450

//This transaction will setup a drop in a versus auction
transaction(
    artist: Address, 
    startPrice: UFix64, 
    startTime: UFix64,
    artistName: String, 
    artName: String, 
    url: String, 
    description: String, 
    editions: UInt64,
    minimumBidIncrement: UFix64) {


    let artistWallet: Capability<&{FungibleToken.Receiver}>
    let versus: &Versus.DropCollection

    prepare(account: AuthAccount) {

        self.versus= account.borrow<&Versus.DropCollection>(from: /storage/Versus)!
        self.artistWallet=  getAccount(artist).getCapability<&{FungibleToken.Receiver}>(/public/DemoTokenReceiver)
    }

    execute {

        var metadata: {String: String} = {
            "name" : artName, 
            "artist" : artistName,
            "artistAddress" : artist.toString(),
            "url" : url,
            "description": description
        }
        
       self.versus.createDrop(
           nft:  <-  Art.createArt(metadata),
           editions: editions,
           minimumBidIncrement: minimumBidIncrement,
           startTime: startTime,
           startPrice: startPrice,
           vaultCap: self.artistWallet
       )
    }
}
 