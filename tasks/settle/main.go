package main

import (
	"fmt"
	"os"
	"strconv"

	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/mitchellh/go-homedir"
	"github.com/onflow/cadence"
)

func main() {


	flowConfigFile, _ := homedir.Expand("~/.flow-testnet.json")
	flow := gwtf.NewGoWithTheFlow(flowConfigFile)
	dropID, ok := os.LookupEnv("drop")
	if !ok {
		fmt.Println("drop is not present")
		os.Exit(1)
	}

	drop, err := strconv.ParseInt(dropID, 10, 64)
	if err != nil {
		fmt.Println("could not parse drop as number")
	}

	flow.TransactionFromFile("buy/settle_testnet").SignProposeAndPayAs("versus").Argument(cadence.UInt64(drop)).RunPrintEventsFull()

}
