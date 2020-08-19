package main

import (
	"github.com/onflow/cadence"
	"github.com/versus-flow/go-flow-tooling/tooling"
)

const nonFungibleToken = "NonFungibleToken"
const demoToken = "DemoToken"
const art = "Art"
const versus = "Versus"
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

func createArt(flow *tooling.FlowConfig, edition uint64, maxEdition uint64) {
	flow.SendTransactionWithArguments("setup/mint_art", art,
		flow.FindAddress(artist),      //artist that owns the art
		cadence.NewString("Name"),     //name of art
		cadence.NewString("John Doe"), //artist name
		cadence.NewString("https://cdn.discordapp.com/attachments/744365120268009472/744964330663051364/image0.png"), //url
		cadence.NewString("This is the description"),                                                                 //description
		cadence.NewUInt64(edition),    //edition
		cadence.NewUInt64(maxEdition)) //maxEdition
}

func bid(flow *tooling.FlowConfig, account string, auctionID int, amount string) {

	flow.CreateAccount(account)
	flow.SendTransaction("setup/create_demotoken_vault", account)
	flow.SendTransaction("setup/create_nft_collection", account)
	flow.SendTransactionWithArguments("setup/mint_demotoken", demoToken,
		flow.FindAddress(account),
		ufix("100.0")) //tokens to mint
	flow.SendTransactionWithArguments("buy/bid", account,
		flow.FindAddress(marketplace),
		cadence.UInt64(1),         //id of drop
		cadence.UInt64(auctionID), //id of auction to bid on
		ufix(amount))              //amount to bid
}

// TODO create a script to check if account exist. or just use go flowConfig for that?
//TODO; Add sleep if started with storyteller mode?
//fmt.Println("Press the Enter Key to continue!")
//fmt.Scanln() // wai
func main() {
	flow := tooling.NewFlowConfigLocalhostWithGas(2000)

	flow.DeployContract(nonFungibleToken)
	// TODO: Could this minter be in init of demoToken? Do we have any scenario where somebody else should mint art?
	flow.DeployContract(demoToken)
	flow.SendTransaction("setup/create_demotoken_minter", demoToken)

	flow.DeployContract(art)
	flow.DeployContract(auction)
	flow.DeployContract(versus)

	//We create the accounts and set up the stakeholdres in our scenario

	//Marketplace will own a marketplace and get a cut for each sale, this account does not own any NFT
	flow.CreateAccount(marketplace)
	flow.SendTransaction("setup/create_demotoken_vault", marketplace)
	flow.SendTransactionWithArguments("setup/create_versus_collection", marketplace,
		ufix("0.15"),      //cut percentage,
		cadence.UInt64(5), //drop length
		cadence.UInt64(5)) //minimumBlockRemainingAfterBidOrTie

	//The artist owns NFTs and sells in the marketplace
	flow.CreateAccount(artist)
	flow.SendTransaction("setup/create_demotoken_vault", artist)
	flow.SendTransaction("setup/create_nft_collection", artist)

	var maxEditions uint64 = 10
	//Create the unique art piece
	createArt(flow, 1, 1) // this will be index 0
	//Create 10 editions
	var i uint64
	for i = 1; i <= maxEditions; i++ {
		createArt(flow, i, maxEditions) //these will be index i
	}

	flow.SendTransactionWithArguments("setup/create_drop", artist,
		flow.FindAddress(marketplace), //marketplace locaion
		cadence.NewUInt64(0),          //id of unique item
		cadence.NewUInt64(1),          //id of start of edition items in storage
		cadence.NewUInt64(10),         //if of last edition item in storage
		ufix("10.0"),                  //start price
		cadence.NewUInt64(25))         //start block

	bid(flow, buyer1, 1, "10.0")
	flow.SendTransactionWithArguments("tick", marketplace, cadence.NewUInt64(1))
	flow.SendTransactionWithArguments("tick", marketplace, cadence.NewUInt64(1))
	flow.SendTransactionWithArguments("tick", marketplace, cadence.NewUInt64(1))
	flow.SendTransactionWithArguments("tick", marketplace, cadence.NewUInt64(1))
	flow.SendTransactionWithArguments("tick", marketplace, cadence.NewUInt64(1))
	flow.SendTransactionWithArguments("tick", marketplace, cadence.NewUInt64(1))

	//bid(flow, buyer2, 2, "30.0")

	flow.SendTransactionWithArguments("buy/settle", marketplace, cadence.UInt64(1))
	flow.RunScript("check_account", flow.FindAddress(marketplace), cadence.NewString("marketplace"))
	flow.RunScript("check_account", flow.FindAddress(buyer1), cadence.NewString("buyer1"))
	flow.RunScript("check_account", flow.FindAddress(buyer2), cadence.NewString("buyer2"))
	flow.RunScript("check_account", flow.FindAddress(artist), cadence.NewString("artist"))

	/*
		//We try to settle the account but the acution has not ended yet
		flow.SendTransactionWithArguments("buy/settle", marketplace, cadence.UInt64(1))

		//now the auction has ended and we can settle

		//check the status of all the accounts involved in this scenario
		flow.RunScript("check_account", flow.FindAddress(marketplace), cadence.NewString("marketplace"))
		flow.RunScript("check_account", flow.FindAddress(artist), cadence.NewString("artist"))
		flow.RunScript("check_account", flow.FindAddress(buyer1), cadence.NewString("buyer1"))
		flow.RunScript("check_account", flow.FindAddress(buyer2), cadence.NewString("buyer2"))

	*/
}
