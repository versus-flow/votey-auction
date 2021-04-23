package main

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
)

func main() {

	flow := gwtf.NewGoWithTheFlowDevNet()

	flow.TransactionFromFile("buy/settle_first").SignProposeAndPayAs("admin").RunPrintEventsFull()

}
