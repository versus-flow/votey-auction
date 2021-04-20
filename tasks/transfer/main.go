package main

import (
	"fmt"
	"os"

	"github.com/bjartek/go-with-the-flow/gwtf"
)

func main() {

	flow := gwtf.NewGoWithTheFlowDevNet()

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
