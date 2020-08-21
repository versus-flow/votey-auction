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
	flow.SendTransactionWithArguments("tick", marketplace, cadence.NewUInt64(1))
	flow.SendTransactionWithArguments("tick", marketplace, cadence.NewUInt64(1))
	flow.SendTransactionWithArguments("tick", marketplace, cadence.NewUInt64(1))
	flow.SendTransactionWithArguments("tick", marketplace, cadence.NewUInt64(1))
	flow.SendTransactionWithArguments("tick", marketplace, cadence.NewUInt64(1))
	flow.SendTransactionWithArguments("buy/settle", marketplace, cadence.UInt64(1))
}
