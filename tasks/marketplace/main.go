package main

import (
	"bufio"
	"encoding/base64"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"

	"github.com/bjartek/go-with-the-flow/gwtf"
)

func fileAsImageData(path string) string {
	f, _ := os.Open("./" + path)

	defer f.Close()

	// Read entire JPG into byte slice.
	reader := bufio.NewReader(f)
	content, _ := ioutil.ReadAll(reader)

	contentType := http.DetectContentType(content)

	// Encode as base64.
	encoded := base64.StdEncoding.EncodeToString(content)

	return "data:" + contentType + ";base64, " + encoded
}

//NB! start from root dir with makefile
func main() {

	//GWTF has no future anymore?
	//flow := gwtf.NewGoWithTheFlow("./versus-flow.json")
	flow := gwtf.NewGoWithTheFlowEmulator()
	//fmt.Scanln()
	fmt.Println("Demo of Versus@Flow")
	//flow.CreateAccountWithContracts("accounts", "NonFungibleToken", "Content", "Art", "Auction", "Versus")

	flow.CreateAccount("marketplace", "artist", "buyer1", "buyer2")
	flow.TransactionFromFile("setup/mint_tokens").SignProposeAndPayAsService().AccountArgument("artist").UFix64Argument("1000.0").RunPrintEventsFull()
	flow.TransactionFromFile("setup/mint_tokens").SignProposeAndPayAsService().AccountArgument("marketplace").UFix64Argument("1000.0").RunPrintEventsFull()
	flow.TransactionFromFile("setup/mint_tokens").SignProposeAndPayAsService().AccountArgument("buyer1").UFix64Argument("1000.0").RunPrintEventsFull()

	//create the AdminPublicAndSomeOtherCollections
	flow.TransactionFromFile("setup/versus1").
		SignProposeAndPayAs("marketplace").
		RunPrintEventsFull()

	//link in the server in the versus client
	flow.TransactionFromFile("setup/versus2").
		SignProposeAndPayAsService().
		AccountArgument("marketplace").
		RunPrintEventsFull()

	flow.TransactionFromFile("setup/art_collection").SignProposeAndPayAs("artist").RunPrintEventsFull()
	flow.TransactionFromFile("setup/art_collection").SignProposeAndPayAs("buyer1").RunPrintEventsFull()

	image := fileAsImageData("bull.png")
	flow.TransactionFromFile("setup/mint_art").
		SignProposeAndPayAs("marketplace").
		AccountArgument("artist").
		StringArgument("Vincent Kamp").                                                                 //artist name
		StringArgument("when?").                                                                        //name of art
		StringArgument(image).                                                                          //imaage
		StringArgument("Here's a lockdown painting I did of a super cool guy and pal, @jburrowsactor"). //description
		RunPrintEventsFull()

	/*
		flow.TransactionFromFile("setup/setup_marketplace_with_art").
			SignProposeAndPayAs("artist").
			UInt64Argument(0).       //artId
			UFix64Argument("10.00"). //price
			RunPrintEventsFull()

		flow.TransactionFromFile("buy/marketplace").
			SignProposeAndPayAs("buyer1").
			AccountArgument("artist").
			UInt64Argument(0).
			UFix64Argument("10.0").
			RunPrintEventsFull()

	*/
}
