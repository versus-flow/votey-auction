
//testnet
//import FungibleToken from 0x9a0766d93b6608b7
//import NonFungibleToken from 0x631e88ae7f1d7c20
//import Content, Art, Auction, Versus from 0x1ff7e32d71183db0


//local emulator
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken, Content, Art, Auction, Versus from 0xf8d6e0586b0a20c7
//This transaction will setup a drop in a versus auction

//This transaction will setup a drop in a versus auction
transaction(
    artist: Address, 
    startPrice: UFix64, 
    startTime: UFix64,
    artistName: String, 
    artName: String,
    content: String, 
    description: String, 
    editions: UInt64,
    minimumBidIncrement: UFix64, 
    minimumBidUniqueIncrement:UFix64,
    duration:UFix64
    ) {


    let client: &Versus.Admin
    let artistWallet: Capability<&{FungibleToken.Receiver}>

    prepare(account: AuthAccount) {

        self.client = account.borrow<&Versus.Admin>(from: Versus.VersusAdminStoragePath) ?? panic("could not load versus admin")
        self.artistWallet=  getAccount(artist).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
    }
    
    execute {

        let art <-  self.client.mintArt(artist: artist, artistName: artistName, artName: artName, content:content, description: description)

        self.client.createDrop(
           nft:  <- art,
           editions: editions,
           minimumBidIncrement: minimumBidIncrement,
           minimumBidUniqueIncrement: minimumBidUniqueIncrement,
           startTime: startTime,
           startPrice: startPrice,
           vaultCap: self.artistWallet,
           duration: duration,
           extensionOnLateBid: duration
       )

       let content=self.client.getContent()
       log(content.contents.keys)

       let wallet=self.client.getFlowWallet()
       log(wallet.balance)


    }
}


