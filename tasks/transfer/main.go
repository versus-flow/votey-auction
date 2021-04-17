package main

import (
	"fmt"
	"os"

	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/mitchellh/go-homedir"
)

func main() {


	flowConfigFile, _ := homedir.Expand("~/.flow-testnet.json")
	flow := gwtf.NewGoWithTheFlow(flowConfigFile)

	account, ok := os.LookupEnv("account")
	if !ok {
		fmt.Println("account is not present")
		os.Exit(1)
	}

	amount, ok := os.LookupEnv("amount")
	if !ok {
		amount = "1000.0"
	}

	flow.TransactionFromFile("setup/transfer_flow").
		SignProposeAndPayAsService().
		UFix64Argument(amount).
		RawAccountArgument(account).
		RunPrintEventsFull()
}
