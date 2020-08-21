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

//NB! start from root dir with makefile
func main() {
	flow := tooling.NewFlowConfigLocalhost()

	flow.DeployContract(nonFungibleToken)
	flow.DeployContract(demoToken)
	flow.DeployContract(art)
	flow.DeployContract(auction)
	flow.DeployContract(versus)

	//We create the accounts and set up the stakeholdres in our scenario

	//Marketplace will own a marketplace and get a cut for each sale, this account does not own any NFT
	flow.CreateAccount(marketplace)
	flow.SendTransactionWithArguments("setup/actor", marketplace, ufix("0.0"))
	flow.SendTransactionWithArguments("setup/versus", marketplace,
		ufix("0.15"),      //cut percentage,
		cadence.UInt64(5), //drop length
		cadence.UInt64(5)) //minimumBlockRemainingAfterBidOrTie

	//The artist owns NFTs and sells in the marketplace
	flow.CreateAccount(artist)
	flow.SendTransactionWithArguments("setup/actor", artist, ufix("0.0"))

}
