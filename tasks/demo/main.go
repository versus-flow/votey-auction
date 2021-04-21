package main

import (
	"bufio"
	"encoding/base64"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/davecgh/go-spew/spew"
	"github.com/onflow/cadence"
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

	now := time.Now()
	t := now.Unix() - 5
	timeString := strconv.FormatInt(t, 10) + ".0"

	//GWTF has no future anymore?
	//flow := gwtf.NewGoWithTheFlow("./versus-flow.json")
	flow := gwtf.NewGoWithTheFlowEmulator()
	//fmt.Scanln()
	fmt.Println("Demo of Versus@Flow")
	//flow.CreateAccountWithContracts("accounts", "NonFungibleToken", "Content", "Art", "Auction", "Versus")

	flow.CreateAccount("marketplace", "artist", "buyer1", "buyer2")

	fmt.Println()
	fmt.Println()
	fmt.Println("MarketplaceCut: 15%, drop length: 5 ticks")
	//fmt.Scanln()

	flow.TransactionFromFile("setup/mint_tokens").SignProposeAndPayAsService().AccountArgument("artist").UFix64Argument("100.0").RunPrintEventsFull()
	flow.TransactionFromFile("setup/mint_tokens").SignProposeAndPayAsService().AccountArgument("marketplace").UFix64Argument("100.0").RunPrintEventsFull()

	//create the versusAdminClientAndSomeOtherCollections
	flow.TransactionFromFile("setup/versus1").
		SignProposeAndPayAs("marketplace").
		RunPrintEventsFull()

	//link in the server in the versus client
	flow.TransactionFromFile("setup/versus2").
		SignProposeAndPayAsService().
		AccountArgument("marketplace").
		RunPrintEventsFull()

	//set up versus
	flow.TransactionFromFile("setup/versus3").
		SignProposeAndPayAs("marketplace").
		UFix64Argument("0.15"). //cut percentage,
		RunPrintEventsFull()

	//fmt.Scanln()

	image := fileAsImageData("bull.png")
	fmt.Println()
	fmt.Println()
	fmt.Println("Create a drop in versus that is already started with 10 editions")
	//fmt.Scanln()
	flow.TransactionFromFile("setup/drop").
		SignProposeAndPayAs("marketplace").
		AccountArgument("artist").                                                                      //marketplace location
		UFix64Argument("10.00").                                                                        //start price
		UFix64Argument(timeString).                                                                     //start time
		StringArgument("Vincent Kamp").                                                                 //artist name
		StringArgument("when?").                                                                        //name of art
		StringArgument(image).                                                                          //imaage
		StringArgument("Here's a lockdown painting I did of a super cool guy and pal, @jburrowsactor"). //description
		Argument(cadence.NewUInt64(10)).                                                                //number of editions to use for the editioned auction
		UFix64Argument("5.0").                                                                          //min bid increment
		UFix64Argument("10.0").                                                                         //min bid increment unique
		UFix64Argument("5.0").                                                                          //duration
		RunPrintEventsFull()

	fmt.Println("Get active auctions")
	//fmt.Scanln()
	flow.ScriptFromFile("get_active_auction").AccountArgument("marketplace").Run()

	fmt.Println()
	fmt.Println()
	fmt.Println("Setup a buyer and make him bid on the unique auction")
	//fmt.Scanln()

	flow.TransactionFromFile("setup/mint_tokens").SignProposeAndPayAsService().AccountArgument("buyer1").UFix64Argument("1000.0").RunPrintEventsFull()

	flow.TransactionFromFile("buy/bid").
		SignProposeAndPayAs("buyer1").
		AccountArgument("marketplace").
		Argument(cadence.UInt64(1)).  //id of drop
		Argument(cadence.UInt64(11)). //id of unique auction auction to bid on
		UFix64Argument("10.00").      //amount to bid
		RunPrintEventsFull()

	fmt.Println()
	fmt.Println()
	fmt.Println("Go to website to bid there")
	value := flow.ScriptFromFile("drop_status").AccountArgument("marketplace").UInt64Argument(1).RunReturns()
	spew.Dump(value)
	fmt.Scanln()
	fmt.Println("Tick the clock to make the auction end and settle it")
	time.Sleep(1 * time.Second)
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").Argument(cadence.UInt64(1)).Run()
	time.Sleep(1 * time.Second)
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").Argument(cadence.UInt64(1)).Run()
	time.Sleep(1 * time.Second)
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").Argument(cadence.UInt64(1)).Run()
	time.Sleep(1 * time.Second)
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").Argument(cadence.UInt64(1)).Run()
	time.Sleep(1 * time.Second)
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").Argument(cadence.UInt64(1)).Run()
	fmt.Println("settle")
	fmt.Scanln()
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").Argument(cadence.UInt64(1)).Run()
	flow.TransactionFromFile("buy/settle").SignProposeAndPayAs("marketplace").Argument(cadence.UInt64(1)).RunPrintEventsFull()

	flow.ScriptFromFile("check_account").AccountArgument("buyer1").Run()
	flow.ScriptFromFile("check_account").AccountArgument("buyer2").Run()
	flow.ScriptFromFile("check_account").AccountArgument("artist").Run()
	flow.ScriptFromFile("check_account").AccountArgument("marketplace").Run()

	flow.TransactionFromFile("setup/destroy_versus").SignProposeAndPayAs("marketplace").Argument(cadence.NewUInt64(1)).RunPrintEventsFull()
}
