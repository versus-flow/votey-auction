package main

import (
	"github.com/onflow/cadence"
	"github.com/versus-flow/go-flow-tooling/tooling"
)

const nonFungibleToken = "NonFungibleToken"
const demoToken = "DemoToken"
const rocks = "Rocks"
const auction = "Auction"

func main() {
	flow := tooling.NewFlowConfigLocalhost()

	flow.DeployContract(nonFungibleToken)
	flow.DeployContract(demoToken)
	flow.DeployContract(rocks)
	flow.DeployContract(auction)

	// Setup DemoToken account with an NFT Collection and an Auction Collection
	flow.SendTransaction("setup/create_nft_collection", demoToken)
	flow.SendTransaction("setup/create_auction_collection", demoToken)

	// Setup Rocks account with DemoToken Vault
	flow.SendTransaction("setup/create_demotoken_vault", rocks)

	// Setup Auction Account with empty DemoToken Vault and Rock Collection
	flow.SendTransaction("setup/create_demotoken_vault", auction)
	flow.SendTransaction("setup/create_nft_collection", auction)

	// Setup NonFungibleToken Account with empty DemoToken Vault and Rock Collection
	flow.SendTransaction("setup/create_demotoken_vault", nonFungibleToken)
	flow.SendTransaction("setup/create_nft_collection", nonFungibleToken)

	// set up the demotoken minter for the demoTokenAccount
	flow.SendTransaction("setup/create_demotoken_minter", demoToken)

	tokensToMint, err := cadence.NewUFix64("100.0")
	if err != nil {
		panic(err)
	}

	flow.SendTransactionWithArguments("setup/mint_demotoken", demoToken, flow.FindAddress(rocks), tokensToMint)
	flow.SendTransactionWithArguments("setup/mint_demotoken", demoToken, flow.FindAddress(demoToken), tokensToMint)
	flow.SendTransactionWithArguments("setup/mint_demotoken", demoToken, flow.FindAddress(auction), tokensToMint)
	flow.SendTransactionWithArguments("setup/mint_demotoken", demoToken, flow.FindAddress(nonFungibleToken), tokensToMint)

	//mint 10 rock nfts into demoToken collection
	flow.SendTransactionWithArguments("setup/mint_nfts", rocks, flow.FindAddress(demoToken), cadence.NewInt(10))

	// Check the balances are properly setup for the auction demo
	//flow.RunScript("check_setup")

	//The DemoToken owns an auction and the nonFingibleToken account wants to sell there
	flow.SendTransactionWithArguments("list/add_nfts_to_auction", demoToken)

	// Check the auction sale data for the DemoToken account
	//flow.RunScript("check_sales_listings")

	flow.SendTransaction("buy/bid", rocks)

	//flow.RunScript("check_sales_listings")

	//flow.RunScript("check_setup")

	flow.SendTransaction("buy/settle", demoToken)
	flow.SendTransaction("buy/settle", demoToken)
	flow.SendTransaction("buy/settle", demoToken)

	//flow.RunScript("check_sales_listings")

	//flow.RunScript("check_setup")

	flow.RunScript("check_account", flow.FindAddress(nonFungibleToken))
	flow.RunScript("check_account", flow.FindAddress(rocks))
	flow.RunScript("check_account", flow.FindAddress(auction))
	flow.RunScript("check_account", flow.FindAddress(demoToken))

	// this should panic - "auction has already completed"
	// flow.SendTransaction("buy/bid", rocks)
}
