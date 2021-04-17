package main

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
)

//NB! start from root dir with makefile
func main() {

	flow := gwtf.NewGoWithTheFlowDevNet()
	flow.TransactionFromFile("remove_contract").SignProposeAndPayAs("testnet-account").StringArgument("Versus").RunPrintEventsFull()

}
