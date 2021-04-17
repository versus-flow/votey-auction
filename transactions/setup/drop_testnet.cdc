//todo, update this when the contract is updated on testnet
//a copy of the drop transaction on testnet
//testnet
import FungibleToken from 0x9a0766d93b6608b7
import NonFungibleToken from 0x631e88ae7f1d7c20
import Content, Art, Auction, Versus from 0x6bb8a74d4db97b46


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
    dropLength:UFix64
    ) {


    let client: &Versus.VersusAdmin
    let artistWallet: Capability<&{FungibleToken.Receiver}>

    prepare(account: AuthAccount) {

        self.client = account.borrow<&Versus.VersusAdmin>(from: Versus.VersusAdminClientStoragePath) ?? panic("could not load versus admin")
        self.artistWallet=  getAccount(artist).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
    }
    
    execute {

        let art <-  self.client.mintArt(artist: artist, artistName: artistName, artName: artName, content:content, description: description)

        self.client.setDropLength(dropLength)
        self.client.setExtentionPeriod(dropLength)
        self.client.createDrop(
           nft:  <- art,
           editions: editions,
           minimumBidIncrement: minimumBidIncrement,
           minimumBidUniqueIncrement: minimumBidUniqueIncrement,
           startTime: startTime,
           startPrice: startPrice,
           vaultCap: self.artistWallet
       )

       let content=self.client.getContent()
       log(content.contents.keys)

       let wallet=self.client.getFlowWallet()
       log(wallet.balance)


    }
}


