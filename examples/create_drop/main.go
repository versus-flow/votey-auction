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

func main() {
	flow := tooling.NewFlowConfigLocalhost()
	flow.SendTransactionWithArguments("setup/drop", marketplace,
		flow.FindAddress(artist),      //marketplace locaion
		ufix("10.0"),                  //start price
		cadence.NewUInt64(12),         //start block
		cadence.NewString("John Doe"), //artist name
		cadence.NewString("Name"),     //name of art
		cadence.NewString("https://cdn.discordapp.com/attachments/744365120268009472/744964330663051364/image0.png"), //url
		cadence.NewString("This is the description"),
		cadence.NewUInt64(10), //number of editions to use for the editioned auction
		ufix("5.0"))           //minimum bid incremen
	flow.RunScript("check_account", flow.FindAddress(marketplace), cadence.NewString("marketplace"))
}
