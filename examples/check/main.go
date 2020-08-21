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
	flow.RunScript("check_account", flow.FindAddress(marketplace), cadence.NewString("marketplace"))
	flow.RunScript("check_account", flow.FindAddress(buyer1), cadence.NewString("buyer1"))
	flow.RunScript("check_account", flow.FindAddress(buyer2), cadence.NewString("buyer2"))
	flow.RunScript("check_account", flow.FindAddress(artist), cadence.NewString("artist"))

}
