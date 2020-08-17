// Rocks are a simple NFT for experimenting with Cadence.
// The contract uses the NonFungibleToken standard from
// https://github.com/onflow/flow-nft/contracts/ and
// includes a method that sets the NFT metaData "type"
// to a type of rock based on the current block height

// Flow Playground (Not Working with Block.height)
// https://play.onflow.org/0634e572-cd43-4d5c-95f8-3dde5a17f370

import NonFungibleToken from 0x01cf0e2f2f715450

// Contract Deployment:
// Acct 1 - 0x01cf0e2f2f715450 - onflow/NonFungibleToken.cdc
// Acct 2 - 0x179b6b1cb6755e31 - demo-token.cdc
// Acct 3 - 0xf3fcd2c1a78f5eee - rocks.cdc
// Acct 4 - 0xe03daebed8ca0615 - auction.cdc
//
pub contract Rocks: NonFungibleToken {

    // totalSupply of Rocks NFTs
    pub var totalSupply: UInt64

    // rockTypes metadata options for Rocks NFTs
    pub var rockTypes: {Int: String}

    // The event that emits when the contract has been initialized
    pub event ContractInitialized()

    // Event that emits when a Rock has been withdrawn from a collection
    pub event Withdraw(id: UInt64, from: Address?)

    // Event that emits when a Rock has been deposited to a collection
    pub event Deposit(id: UInt64, to: Address?)

    // The Rock NFT resource
    pub resource NFT: NonFungibleToken.INFT {
        
        // the Rock's ID
        pub let id: UInt64

        // a dictionary for storing the Rock's meta data
        pub var metadata: {String: String}

        init(initID: UInt64, rockType: String) {
            
            // Set the initial ID
            self.id = initID

            // Set the rock type to the provided value
            self.metadata = {
                "type": rockType
            }
        }

        // getRockType returns the rock type as a string
        pub fun getRockType(): String {
            return self.metadata["type"]
                ?? panic("Rock has no rock type!")
        }
    }

    // PublicCollectionMethods is a custom interface that allows us to
    // access the public fields and methods for our Rocks Collection
    pub resource interface PublicCollectionMethods {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowRock(id: UInt64): &Rocks.NFT?
        pub fun getRockTypeOptions(): [String]
        pub fun getMintedRockTypes(): {UInt64: String}
        pub fun getRockTypeCount(): {String: UInt64}
        
    }

    // Collection is a resource that contains the Rock NFTs and provides secure methods for the deposit,
    // withdrawal and management of the Rocks in the collection
    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, PublicCollectionMethods {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with a 'UInt64' ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init() {
            self.ownedNFTs <- {}
        }

        // withdraw removes an NFT from the Collection and provides it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit takes an NFT and adds it to the collections dictionary
        // adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Rocks.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        // borrowRock gets an authorized reference to and NFT in the collection
        // and returns it to the caller as a reference to the Rocks.NFT if it exists.
        // The method returns nil if the provided token id doesn't exist in the collection
        pub fun borrowRock(id: UInt64): &Rocks.NFT? {
            if self.ownedNFTs[id] != nil {
                let RockRef = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return RockRef as! &Rocks.NFT
            } else {
                return nil
            }
        }

        pub fun getRockTypeOptions(): [String] {
            return Rocks.rockTypes.values
        }

        pub fun getMintedRockTypes(): {UInt64: String} {
            let rockIDs = self.getIDs()
            var mintedRockTypes: {UInt64: String} = {}

            for id in rockIDs {
                let rockRef = self.borrowRock(id: id)
                    ?? panic("No Rock available at this ID")

                let rockType = rockRef.getRockType()

                mintedRockTypes[id] = rockType
            }

            return mintedRockTypes
        }

        pub fun getRockTypeCount(): {String: UInt64} {
            let rockTypeOptions = self.getRockTypeOptions()
            let mintedRockTypes = self.getMintedRockTypes().values
            
            var rockTypeCount: {String: UInt64} = {}

            for option in rockTypeOptions {
                rockTypeCount[option] = UInt64(0)
                
                for rockType in mintedRockTypes {
                    if option == rockType {
                        rockTypeCount[option] = rockTypeCount[option]! + UInt64(1)
                    }
                }
            }

            return rockTypeCount
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty Collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
    pub resource NFTMinter {

        // setRockType takes the block height as an agrument and
        // uses some simple math to pick a rock type for the asset.
        // The rock type is returned to the calling context as a string.
        //
        access(self) fun setRockType(blockHeight: UInt64): String {
            // Set the initial rock type to 1 - most common
            var rockType = Rocks.rockTypes[1]
            
            // Setup a multidimensional array to hold both the key
            // multiplier used to determine the rock type's rarity
            let rarityRules: [[Int]] = []
            
            // For each key in Rocks.rockTypes...
            for key in Rocks.rockTypes.keys {
                // ... if the key is greater than 1 ...
                if key > 1 {
                    // .. append the multiplier and key to
                    // the rarityRules array as a new index
                    rarityRules.append([(key * key) * 2, key])
                }    
            }

            // For each rule in rarityRules...
            for rule in rarityRules {
                let step = rule[0] // Get the multiplier
                let type = rule[1] // Get the rock type
                
                // If the block height is divisible by the multiplier...
                if (blockHeight % UInt64(step) == UInt64(0)) {
                    // .. change the rock type
                    rockType = Rocks.rockTypes[type]
                }
            }

            return rockType 
                ?? panic("Unable to return a rock type!")
        }

        // mintNFT mints a new NFT with a new ID and deposits it into the recipients 
        // Collection using their Collection reference
        pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}) {

            // get the current block
            let currentBlock = getCurrentBlock()

            // use the current block height to set the rock type
            let rockType = self.setRockType(blockHeight: currentBlock.height)

            // Create a new NFT
            var newNFT <- create NFT(initID: Rocks.totalSupply, rockType: rockType)

            // Deposit it in the recipient's Collection using their reference
            recipient.deposit(token: <-newNFT)

            // Update the total supply count
            Rocks.totalSupply = Rocks.totalSupply + UInt64(1)
        }
    }

    init() {
        // initialize the totalSupply
        self.totalSupply = 0

        self.rockTypes = {
            1: "coal",
            2: "jet",
            3: "pyrite",
            4: "diamond"
        }

        // create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: /storage/RockCollection)

        // create a public capability for the Collection
        self.account.link<&{NonFungibleToken.CollectionPublic}>(
            /public/RockCollection,
            target: /storage/RockCollection
        )

        // create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: /storage/RockMinter)

        emit ContractInitialized()
    }
}
 