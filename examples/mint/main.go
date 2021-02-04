package main

import (
	"encoding/hex"
	"fmt"
	"os"

	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/onflow/cadence"
)

func main() {

	flow := gwtf.NewGoWithTheFlowEmulator()

	account, ok := os.LookupEnv("account")
	if !ok {
		fmt.Println("account is not present")
		os.Exit(1)
	}

	amount, ok := os.LookupEnv("amount")
	if !ok {
		amount = "100.0"
	}

	accountHex, err := hex.DecodeString(account)
	if err != nil {
		panic(err)
	}
	accountArg := cadence.BytesToAddress(accountHex)
	flow.TransactionFromFile("setup/mint_tokens").SignProposeAndPayAsService().Argument(accountArg).UFix64Argument(amount).RunPrintEventsFull()
}
