
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import Content from "./Content.cdc"

//A NFT contract to store art
pub contract Art: NonFungibleToken {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath
    pub let MinterPrivatePath: PrivatePath
    pub let AdministratorPublicPath: PublicPath
    pub let AdministratorStoragePath:StoragePath

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Created(id: UInt64, metadata: Metadata)
    pub event Editioned(id: UInt64, from: UInt64, edition: UInt64, maxEdition: UInt64)

    //The public interface can show metadata and the content for the Art piece
    pub resource interface Public {
        pub let id: UInt64
        pub let metadata: Metadata
        pub fun content() : String?
    }

    pub struct Metadata {
        pub let name: String
        pub let artist: String
        pub let artistAddress:Address
        pub let description: String
        pub let type: String
        pub let edition: UInt64
        pub let maxEdition: UInt64


        init(name: String, 
            artist: String,
            artistAddress:Address, 
            description: String, 
            type: String, 
            edition: UInt64,
            maxEdition: UInt64) {
                self.name=name
                self.artist=artist
                self.artistAddress=artistAddress
                self.description=description
                self.type=type
                self.edition=edition
                self.maxEdition=maxEdition
        }

    }

     pub struct Royalty{
        pub let wallet:Capability<&{FungibleToken.Receiver}> 
        pub let cut: UFix64

        init(wallet:Capability<&{FungibleToken.Receiver}>, cut: UFix64 ){
           self.wallet=wallet
           self.cut=cut
        }
    }

    pub resource NFT: NonFungibleToken.INFT, Public {
        pub let id: UInt64

        //content can either be embedded in the NFT as and URL or a pointer to a Content collection to be stored onChain
        //a pointer will be used for all editions of the same Art when it is editioned 
        pub let contentCapability:Capability<&Content.Collection>?
        pub let contentId: UInt64?
        pub let url: String?
        pub let metadata: Metadata
        pub let royalty: {String: Royalty}

        init(
            initID: UInt64, 
            metadata: Metadata,
            contentCapability:Capability<&Content.Collection>?, 
            contentId: UInt64?, 
            url: String?,
            royalty:{String: Royalty}) {

            self.id = initID
            self.metadata=metadata
            self.contentCapability=contentCapability
            self.contentId=contentId
            self.url=url
            self.royalty=royalty
        }

        //return the content for this NFT
        pub fun content() : String {
            if self.url != nil {
                return self.url!
            }

            let contentCollection= self.contentCapability!.borrow()!
            //not sure banging it here will work but we can try
            return contentCollection.content(self.contentId!)!
        }
    }

 
    //Standard NFT collectionPublic interface that can also borrowArt as the correct type
    pub resource interface CollectionPublic {

        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowArt(id: UInt64): &{Art.Public}?
    }


    pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
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
        pub fun borrowArt(id: UInt64): &{Art.Public}? {
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

 

    pub struct ArtData {
        pub let metadata: Art.Metadata
        pub let id: UInt64
        init(metadata: Art.Metadata, id: UInt64) {
            self.metadata= metadata
            self.id=id
        }
    }



    pub fun getContentForArt(address:Address, artId:UInt64) : String? {

        let account=getAccount(address)
        if let artCollection= account.getCapability(self.CollectionPublicPath).borrow<&{Art.CollectionPublic}>()  {
            return artCollection.borrowArt(id: artId)!.content()
        }
        return nil
    }

    // We cannot return the content here since it will be too big to run in a script
    pub fun getArt(address:Address) : [ArtData] {

        var artData: [ArtData] = []
        let account=getAccount(address)

        if let artCollection= account.getCapability(self.CollectionPublicPath).borrow<&{Art.CollectionPublic}>()  {
            for id in artCollection.getIDs() {
                var art=artCollection.borrowArt(id: id) 
                artData.append(ArtData(
                    metadata: art!.metadata,
                    id: id))
            }
        }
        return artData
    } 

    pub resource Minter {
        pub fun createArtWithContent(
            name: String, 
            artist:String, 
            artistAddress:Address,
            description: String, 
            url: String, 
            type: String,
            royalty: {String: Royalty}) : @Art.NFT {
            var newNFT <- create NFT(
                initID: Art.totalSupply,
                metadata: Metadata(
                    name: name, 
                    artist: artist,
                    artistAddress: artistAddress, 
                    description:description,
                    type:type,
                    edition:1,
                    maxEdition:1
                ),
                contentCapability:nil,
                contentId:nil,
                url:url, 
                royalty:royalty
            )
            emit Created(id: Art.totalSupply, metadata: newNFT.metadata)

            Art.totalSupply = Art.totalSupply + UInt64(1)
            return <- newNFT


        }


        pub fun createArtWithPointer(
            name: String, 
            artist: String, 
            artistAddress:Address, 
            description: String, 
            type: String, 
            contentCapability:Capability<&Content.Collection>, 
            contentId: UInt64,
            royalty: {String: Royalty}) : @Art.NFT{
            
            var newNFT <- create NFT(
                initID: Art.totalSupply,
                metadata: Metadata(
                    name: name, 
                    artist: artist,
                    artistAddress: artistAddress, 
                    description:description,
                    type:type,
                    edition:1,
                    maxEdition:1
                ),
                contentCapability:contentCapability, 
                contentId:contentId,
                url:nil,
                royalty:royalty
            )
            emit Created(id: Art.totalSupply, metadata: newNFT.metadata)

            Art.totalSupply = Art.totalSupply + UInt64(1)
            return <- newNFT
        }

        pub fun makeEdition(original: &NFT, edition: UInt64, maxEdition:UInt64) : @Art.NFT {
            var newNFT <- create NFT(
            initID: Art.totalSupply,
            metadata: Metadata(
                name: original.metadata.name,
                artist:original.metadata.artist,
                artistAddress:original.metadata.artistAddress,
                description:original.metadata.description,
                type:original.metadata.type,
                edition: edition,
                maxEdition:maxEdition
            ),
            contentCapability: original.contentCapability,
            contentId:original.contentId,
            url:original.url,
            royalty:original.royalty
            )
            emit Created(id: Art.totalSupply, metadata: newNFT.metadata)
            emit Editioned(id: Art.totalSupply, from: original.id, edition:edition, maxEdition:maxEdition)

            Art.totalSupply = Art.totalSupply + UInt64(1)
            return <- newNFT
        }
 
         
    }

     //The interface used to add a Administrator capability to a client
    pub resource interface AdministratorClient {
        pub fun addCapability(_ cap: Capability<&Minter>)
    }

   
    //The versus admin resource that a client will create and store, then link up a public VersusAdminClient
    pub resource Administrator: AdministratorClient {

        access(self) var server: Capability<&Minter>?

        init() {
            self.server = nil
        }

         pub fun addCapability(_ cap: Capability<&Minter>) {
            pre {
                cap.check() : "Invalid server capablity"
                self.server == nil : "Server already set"
            }
            self.server = cap
        }

        pub fun createArtWithContent(
            name: String, 
            artist:String, 
            artistAddress:Address, 
            description: String, 
            url: String, 
            type: String,
            royalty: {String: Royalty}) : @Art.NFT {

            pre {
                self.server != nil: 
                    "Cannot create art if server is not set"
            }
            return <- self.server!.borrow()!.createArtWithContent(
                name: name, 
                artist: artist, 
                artistAddress: artistAddress, 
                description: description,
                url: url, 
                type: type,
                royalty:royalty)
           

        }
        pub fun createArtWithPointer(
            name: String, 
            artist: String, 
            artistAddress:Address, 
            description: String, 
            type: String, 
            contentCapability:Capability<&Content.Collection>, 
            contentId: UInt64,
            royalty: {String: Royalty}) : @Art.NFT{

            pre {
                self.server != nil: 
                    "Cannot create art if server is not set"
            }
            return <- self.server!.borrow()!.createArtWithPointer(
                name: name, 
                artist: artist, 
                artistAddress: artistAddress, 
                description: description,
                type: type,
                contentCapability:contentCapability, 
                contentId:contentId,
                royalty:royalty
            )
        }

        pub fun makeEdition(original: &NFT, edition: UInt64, maxEdition:UInt64) : @Art.NFT {
            pre {
                self.server != nil: 
                    "Cannot create art if server is not set"
            }
            return <- self.server!.borrow()!.makeEdition(original: original, edition:edition, maxEdition:maxEdition)
        }
    }

    //make it possible for a user that wants to be a versus admin to create the client
    pub fun createAdminClient(): @Administrator {
        return <- create Administrator()
    }
    

	init() {
        // Initialize the total supply
        self.totalSupply = 0
        self.CollectionPublicPath=/public/VersusArtCollection
        self.CollectionStoragePath=/storage/VersusArtCollection
        self.AdministratorPublicPath= /public/artAdminClient
        self.AdministratorStoragePath=/storage/artAdminClient
        self.MinterStoragePath=/storage/artAdmin
        self.MinterPrivatePath=/private/artAdmin

        self.account.save(<- create Minter(), to: self.MinterStoragePath)
        self.account.link<&Minter>(self.MinterPrivatePath, target: self.MinterStoragePath)

        emit ContractInitialized()
	}
}

