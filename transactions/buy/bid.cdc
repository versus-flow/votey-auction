// This transaction uses the signers Vault tokens to purchase an NFT
// from the Sale collection of account 1.

// Signer - Account 2 - 0x179b6b1cb6755e31

import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0x01cf0e2f2f715450
import Auction from 0xe03daebed8ca0615

transaction(marketplace: Address, auctionId: UInt64, bidAmount: UFix64) {
    // reference to the buyer's NFT collection where they
    // will store the bought NFT

    let vaultCap: Capability<&{FungibleToken.Receiver}>
    let collectionCap: Capability<&{NonFungibleToken.CollectionPublic}> 
    // Vault that will hold the tokens that will be used
    // to buy the NFT
    let temporaryVault: @FungibleToken.Vault

    prepare(account: AuthAccount) {

        // get the references to the buyer's Vault and NFT Collection receiver
        self.collectionCap = account.getCapability<&{NonFungibleToken.CollectionPublic}>(/public/ArtCollection)!
        if !self.collectionCap.check() {
           panic("Unable to borrow a reference to the NFT collection")
        }

        self.vaultCap = account.getCapability<&{FungibleToken.Receiver}>(/public/DemoTokenReceiver)!
        if !self.vaultCap.check() {
           panic("Could not find demoVaultCap")
        }
                    
        let vaultRef = account.borrow<&FungibleToken.Vault>(from: /storage/DemoTokenVault)
            ?? panic("Could not borrow owner's Vault reference")

        // withdraw tokens from the buyer's Vault
        self.temporaryVault <- vaultRef.withdraw(amount: bidAmount)
    }

    execute {
        // get the read-only account storage of the seller
        let seller = getAccount(marketplace)

        // get the reference to the seller's sale
        let auctionRef = seller.getCapability(/public/NFTAuction)!
                         .borrow<&{Auction.AuctionPublic}>()
                         ?? panic("Could not borrow seller's sale reference")

        auctionRef.placeBid(id: auctionId, bidTokens: <- self.temporaryVault, vaultCap: self.vaultCap, collectionCap: self.collectionCap)
    }
}
 