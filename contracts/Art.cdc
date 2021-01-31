//This contract is on purpose pretty simple, it does not have a minter on anything
//It should probably not be as loose permission wise at it is now.

import NonFungibleToken, Content from 0x01cf0e2f2f715450

pub contract Art: NonFungibleToken {

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Created(id: UInt64, name: String)

    pub resource interface Public {
        pub let id: UInt64
        pub let name: String
        pub let artistAddress:String
        pub let description: String
        pub let type: String
        pub let edition: UInt64
        pub let maxEdition: UInt64

        pub fun content() : String?
    }

    pub resource NFT: NonFungibleToken.INFT, Public {
        pub let id: UInt64
        //move all metadata to a struct except content including editions
        pub let name: String
        pub let artistAddress:String
        pub let description: String
        pub let type: String
        pub let contentCapability:Capability<&Content.Collection>?
        pub let contentId: UInt64?
        pub let url: String?
        pub let edition: UInt64
        pub let maxEdition: UInt64
        init(
            initID: UInt64, 
            name: String, 
            artistAddress:String, 
            description: String, 
            type: String, 
            contentCapability:Capability<&Content.Collection>?, 
            contentId: UInt64?, 
            url: String?, 
            edition: UInt64,
            maxEdition: UInt64) {

            self.id = initID
            self.name=name
            self.artistAddress=artistAddress
            self.description=description
            self.type=type
            self.contentCapability=contentCapability
            self.contentId=contentId
            self.url=url
            self.edition=edition
            self.maxEdition=maxEdition
        }

        pub fun content() : String {
            if self.url != nil {
                return self.url!
            }

            let contentCollection= self.contentCapability!.borrow()!
            //not sure banging it here will work but we can try
            return contentCollection.content(self.contentId!)!
        }

        //TODO: this should probably not be here? or create an interface that does not expose it?
        pub fun makeEdition(edition: UInt64, maxEdition:UInt64) : @Art.NFT {
            var newNFT <- create NFT(
            initID: Art.totalSupply,
            name: self.name, 
            artistAddress: self.artistAddress, 
            description:self.description,
            type:self.type,
            contentCapability:self.contentCapability,
            contentId:self.contentId,
            url:self.url,
            edition: edition,
            maxEdition:maxEdition
            )
            emit Created(id: Art.totalSupply, name: self.name.concat(" edition ").concat(edition.toString()))

            Art.totalSupply = Art.totalSupply + UInt64(1)
            return <- newNFT
        }
    }

    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Art.NFT

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

        // borrowArt returns a borrowed reference to a Art 
        // so that the caller can read data and call methods from it.
        //
        // Parameters: id: The ID of the NFT to get the reference for
        //
        // Returns: A reference to the NFT
        pub fun borrowArt(id: UInt64): &Art.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &Art.NFT
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }


    pub fun createArtWithPointer(name: String, artistAddress:String, description: String, type: String, contentCapability:Capability<&Content.Collection>, contentId: UInt64) : @Art.NFT{
        
        var newNFT <- create NFT(
            initID: Art.totalSupply,
            name: name, 
            artistAddress: artistAddress, 
            description:description,
            type:type,
            contentCapability:contentCapability, 
            contentId:contentId,
            url:nil,
            edition:1,
            maxEdition:1
        )
        emit Created(id: Art.totalSupply, name: name)

        Art.totalSupply = Art.totalSupply + UInt64(1)
        return <- newNFT
    }

         

    pub fun createArtWithContent(name: String, artistAddress:String, description: String, url: String, type: String) : @Art.NFT {
         var newNFT <- create NFT(
            initID: Art.totalSupply,
            name: name, 
            artistAddress: artistAddress, 
            description:description,
            type:type,
            contentCapability:nil,
            contentId:nil,
            url:url, 
            edition:1,
            maxEdition:1
        )
        emit Created(id: Art.totalSupply, name: name)

        Art.totalSupply = Art.totalSupply + UInt64(1)
        return <- newNFT


    }

	init() {
        // Initialize the total supply
        self.totalSupply = 0
        emit ContractInitialized()
	}
}

