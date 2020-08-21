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
	auctionID := 1
	amount := "10.0"
	flow.SendTransactionWithArguments("buy/bid", buyer1,
		flow.FindAddress(marketplace),
		cadence.UInt64(1),         //id of drop
		cadence.UInt64(auctionID), //id of auction to bid on
		ufix(amount))              //amount to bid
}
