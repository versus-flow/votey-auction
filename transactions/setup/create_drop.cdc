import NonFungibleToken from 0x01cf0e2f2f715450
import FungibleToken from 0xee82856bf20e2aa6
import DemoToken from 0x179b6b1cb6755e31
import Auction from 0xe03daebed8ca0615
import Versus from 0x045a1763c93006ca
import Art from 0xf3fcd2c1a78f5eee

transaction(versus: Address, 
    uniqueId: UInt64, 
    minEditionId: UInt64, 
    maxEditionId:UInt64, 
    startPrice: UFix64, 
    startBlock: UInt64) {


    let vaultCap: Capability<&{FungibleToken.Receiver}>
    let accountCollectionRef:&NonFungibleToken.Collection
    let publicCollectionCap:Capability<&{NonFungibleToken.CollectionPublic}>

    prepare(account: AuthAccount) {


         // borrow a reference to the entire NFT Collection functionality (for withdrawing)
        self.accountCollectionRef = account.borrow<&NonFungibleToken.Collection>(from: /storage/ArtCollection)!

        // get the public Capability for the signer's NFT collection (for the auction)
        self.publicCollectionCap = account.getCapability<&{NonFungibleToken.CollectionPublic}>(/public/ArtCollection)!
        if !self.publicCollectionCap.check()  {
           panic("Unable to borrow the CollectionPublic capability")
        }


        self.vaultCap = account.getCapability<&{FungibleToken.Receiver}>(/public/DemoTokenReceiver)!
        if !self.vaultCap.check() {
            panic("Unable to borrow the Vault Receiver capability")
         }

       
    }

    execute {

        //get the auctionCollectionReference to add the item to
        let versusRef = getAccount(versus).getCapability(/public/Versus)!
                         .borrow<&{Versus.PublicDrop}>()
                         ?? panic("Could not borrow seller's sale reference")

            // withdraw the NFT from the collection that you want to sell
            // and move it into the transaction's context
            let uniqueItem <- self.accountCollectionRef.withdraw(withdrawID: uniqueId)
            let editionCollecion <- Art.createEmptyCollection()

            var currentId=minEditionId
            while(currentId <= maxEditionId){
                editionCollecion.deposit(token: <- self.accountCollectionRef.withdraw(withdrawID:currentId))
                currentId=currentId+UInt64(1)
            }

            versusRef.createDrop(
                uniqueArt: <- uniqueItem,
                editionsArt: <- editionCollecion,
                minimumBidIncrement: UFix64(5),
                startBlock: startBlock,
                startPrice: startPrice,
                collectionCap: self.publicCollectionCap,
                vaultCap: self.vaultCap
            )
    }
}
 