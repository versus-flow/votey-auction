//todo, update this when the contract is updated on testnet
//a copy of the drop transaction on testnet
//testnet
import FungibleToken from 0x9a0766d93b6608b7
import NonFungibleToken from 0x631e88ae7f1d7c20
import Content, Art, Auction, Versus from 0x467694dd28ef0a12


//This transaction will setup a drop in a versus auction
transaction(
    artist: Address, 
    startPrice: UFix64, 
    startTime: UFix64,
    artistName: String, 
    artName: String, 
    //TODO: change to content
    content: String, 
    description: String, 
    editions: UInt64,
    minimumBidIncrement: UFix64, 
    minimumBidUniqueIncrement:UFix64
    ) {


    let artistWallet: Capability<&{FungibleToken.Receiver}>
    let versusWallet: Capability<&{FungibleToken.Receiver}>
    let versus: &Versus.DropCollection
    let contentCapability: Capability<&Content.Collection>

    prepare(account: AuthAccount) {

        self.versus= account.borrow<&Versus.DropCollection>(from: Versus.CollectionStoragePath)!
        self.contentCapability=account.getCapability<&Content.Collection>(Content.CollectionPrivatePath)
        self.versusWallet=  account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        self.artistWallet=  getAccount(artist).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
    }
    
    execute {

        var contentItem  <- Content.createContent(content)
        let contentId= contentItem.id
        self.contentCapability.borrow()!.deposit(token: <- contentItem)

        
        let royalty = {
            "artist" : Art.Royalty(wallet: self.artistWallet, cut: 0.05), 
            "minter" : Art.Royalty(wallet: self.versusWallet, cut: 0.025)
        }
        let art <- self.artAdmin.createArtWithPointer(
            name: artName,
            artist:artistName,
            artistAddress : artist,
            description: description,
            type: "png",
            contentCapability: self.contentCapability,
            contentId: contentId,
            royalty: royalty
        )

        self.versus.createDrop(
           nft:  <- art,
           editions: editions,
           minimumBidIncrement: minimumBidIncrement,
           minimumBidUniqueIncrement: minimumBidUniqueIncrement,
           startTime: startTime,
           startPrice: startPrice,
           vaultCap: self.artistWallet
       )
    }
}


