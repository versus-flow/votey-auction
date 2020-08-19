// This transaction uses the signers Vault tokens to purchase an NFT
// from the Sale collection of account 1.

// Signer - Account 2 - 0x179b6b1cb6755e31

import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0x01cf0e2f2f715450
import Versus from 0x045a1763c93006ca

transaction(dropId: UInt64) {
    // reference to the buyer's NFT collection where they
    // will store the bought NFT

    let versusRef: &Versus.DropCollection
    prepare(account: AuthAccount) {

        self.versusRef = account.borrow<&Versus.DropCollection>(from: /storage/Versus) ?? panic("Could not get versus storage")
    }

    execute {
        
            self.versusRef.settle(dropId)
        }
    }
 