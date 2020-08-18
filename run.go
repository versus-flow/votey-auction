package main

import (
	"github.com/onflow/cadence"
	"github.com/versus-flow/go-flow-tooling/tooling"
)

const nonFungibleToken = "NonFungibleToken"
const demoToken = "DemoToken"
const art = "Art"
const auction = "Auction"
const marketplace = "Marketplace"
const artist = "Artist"
const buyer1 = "Buyer1"
const buyer2 = "Buyer2"

func ufix(input string) cadence.UFix64 {
	amount, err := cadence.NewUFix64(input)
	if err != nil {
		panic(err)
	}
	return amount
}

//TODO; Add sleep if started with storyteller mode?
//fmt.Println("Press the Enter Key to continue!")
//fmt.Scanln() // wai
func main() {
	flow := tooling.NewFlowConfigLocalhost()

	flow.DeployContract(nonFungibleToken)
	// TODO: Could this minter be in init of demoToken? Do we have any scenario where somebody else should mint art?
	flow.DeployContract(demoToken)
	flow.SendTransaction("setup/create_demotoken_minter", demoToken)

	flow.DeployContract(art)
	flow.DeployContract(auction)

	//We create the accounts and set up the stakeholdres in our scenario

	//Marketplace will own a marketplace and get a cut for each sale, this account does not own any NFT
	flow.CreateAccount(marketplace)
	flow.SendTransaction("setup/create_demotoken_vault", marketplace)
	flow.SendTransaction("setup/create_auction_collection", marketplace)

	//The artist owns NFTs and sells in the marketplace
	flow.CreateAccount(artist)
	flow.SendTransaction("setup/create_demotoken_vault", artist)
	flow.SendTransaction("setup/create_nft_collection", artist)

	//Mint 1 new Art piece and add the for sale with a start price of 10.0
	flow.SendTransactionWithArguments("setup/mint_art", art,
		flow.FindAddress(artist),      //artist that owns the art
		cadence.NewString("Name"),     //name of art
		cadence.NewString("John Doe"), //artist name
		cadence.NewString("https://cdn.discordapp.com/attachments/744365120268009472/744964330663051364/image0.png"), //url
		cadence.NewString("This is the description"),                                                                 //description
		cadence.NewInt(1), //edition
		cadence.NewInt(1)) //maxEdition

	flow.SendTransactionWithArguments("list/add_nft_to_auction", artist,
		flow.FindAddress(marketplace), //marketplace locaion
		cadence.NewUInt64(0),          //tokenID
		ufix("10.0"),                  //minimum bid
		cadence.NewUInt64(10))         //auction length

	//Buyer1 bid on NFTS and hope to grow his NFT collection, Starts out with 100 tokens and no NFTS
	flow.CreateAccount(buyer1)
	flow.SendTransaction("setup/create_demotoken_vault", buyer1)
	flow.SendTransaction("setup/create_nft_collection", buyer1)
	flow.SendTransactionWithArguments("setup/mint_demotoken", demoToken,
		flow.FindAddress(buyer1),
		ufix("100.0")) //tokens to mint

	//Buyer2 bid on NFTS and hope to grow his NFT collection, Starts out with 100 tokens and no NFTS
	flow.CreateAccount(buyer2)
	flow.SendTransaction("setup/create_demotoken_vault", buyer2)
	flow.SendTransaction("setup/create_nft_collection", buyer2)
	flow.SendTransactionWithArguments("setup/mint_demotoken", demoToken,
		flow.FindAddress(buyer2),
		ufix("100.0")) //token to mint

	//Buyer1 places a bid for 20 tokens on auctionItem1
	flow.SendTransactionWithArguments("buy/bid", buyer1,
		flow.FindAddress(marketplace),
		cadence.UInt64(1), //id of auction to bid on
		ufix("20.0"))      //amount to bid

	//We try to settle the account but the acution has not ended yet
	flow.SendTransactionWithArguments("buy/settle", marketplace, cadence.UInt64(1))

	//now the auction has ended and we can settle
	flow.SendTransactionWithArguments("buy/settle", marketplace, cadence.UInt64(1))

	//check the status of all the accounts involved in this scenario
	flow.RunScript("check_account", flow.FindAddress(marketplace), cadence.NewString("marketplace"))
	flow.RunScript("check_account", flow.FindAddress(artist), cadence.NewString("artist"))
	flow.RunScript("check_account", flow.FindAddress(buyer1), cadence.NewString("buyer1"))
	flow.RunScript("check_account", flow.FindAddress(buyer2), cadence.NewString("buyer2"))

}
