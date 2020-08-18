// This transaction adds an empty Vault to Account 2
// and mints new NFTs which are deposited into
// the NFT collection on Account 1.

// Signer: Account 2 - 0x179b6b1cb6755e31

import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0x01cf0e2f2f715450
import DemoToken from 0x179b6b1cb6755e31
import Art from 0xf3fcd2c1a78f5eee


transaction(recipient: Address, name: String, artist: String, url: String, description: String,  edition: Int, maxEdition: Int, ){

    // private reference to this account's minter resource
    let minterRef: &Art.NFTMinter
    
    prepare(acct: AuthAccount) {
        // borrow a reference to the NFTMinter in storage
        self.minterRef = acct.borrow<&Art.NFTMinter>(from: /storage/ArtMinter)
            ?? panic("Could not borrow owner's vault minter reference")
        
    }

    execute {
        // Get the recipient's public account object

        // get the collection reference for the receiver
        // getting the public capability and borrowing the reference from it
        let receiverCap = getAccount(recipient).getCapability(/public/ArtCollection)!

        let receiverRef = receiverCap.borrow<&{NonFungibleToken.CollectionPublic}>()
                                   ?? panic("unable to borrow nft receiver reference")

        // mint an NFT and deposit it in the receiver's collection

        let metadata: {String: String} = {
            "name" : name, 
            "artist" : artist,
            "artistAddress" : recipient.toString(),
            "url" : url,
            "description": description, 
            "edition" : edition.toString(), 
            "maxEdition": maxEdition.toString()
        }

        self.minterRef.mintNFT(recipient: receiverRef, metadata: metadata)
            

        log("New NFT(s) minted for account 1")
    }
}
 