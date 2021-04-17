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
		fmt.Println("drop is not present")
		os.Exit(1)
	}

	flow.TransactionFromFile("setup/setup_art").SignProposeAndPayAs(account).RunPrintEventsFull()

}
