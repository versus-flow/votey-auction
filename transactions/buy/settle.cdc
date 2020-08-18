// This transaction uses the signers Vault tokens to purchase an NFT
// from the Sale collection of account 1.

// Signer - Account 2 - 0x179b6b1cb6755e31

import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0x01cf0e2f2f715450
import Auction from 0xe03daebed8ca0615

transaction(auctionId: UInt64) {
    // reference to the buyer's NFT collection where they
    // will store the bought NFT

    let vaultCap: &Auction.AuctionCollection 

    prepare(account: AuthAccount) {

        self.vaultCap = account.borrow<&Auction.AuctionCollection>(from: /storage/NFTAuction)
            ?? panic("Could not borrow owner's auction collection")
    }

    execute {
        
        self.vaultCap.settleAuction(auctionId)
    }
}
 