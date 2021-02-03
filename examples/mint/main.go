package main

import (
	"fmt"
	"os"

	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/onflow/cadence"
)

func main() {

	flow := gwtf.NewGoWithTheFlowEmulator()

	account, ok := os.LookupEnv("ACCOUNT")
	if !ok {
		fmt.Println("REDIS_HOST is not present")
		os.Exit(1)

	}

	amount, ok := os.LookupEnv("AMOUNT")
	if !ok {
		fmt.Println("REDIS_HOST is not present")
		os.Exit(1)
	} else {
		amount = "100.0"
	}

	flow.TransactionFromFile("setup/mint_tokens").SignProposeAndPayAsService().Argument(cadence.String(account)).UFix64Argument(amount).RunPrintEventsFull()

}
