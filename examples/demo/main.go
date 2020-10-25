package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/onflow/cadence"
)

//NB! start from root dir with makefile
func main() {
	emptyMap := map[string][]string{}

	flow := gwtf.NewGoWithTheFlowEmulator()
	fmt.Println("Demo of Versus@Flow")
	fmt.Scanln()
	flow.DeployContract("NonFungibleToken")
	flow.DeployContract("DemoToken")
	flow.DeployContract("Art")
	flow.DeployContract("Auction")
	flow.DeployContract("Versus")

	fmt.Println()
	fmt.Println()
	fmt.Println("MarketplaceCut: 15%, drop length: 5 ticks")
	fmt.Scanln()
	flow.CreateAccount("marketplace")
	gwtf.PrintEvents(flow.TransactionFromFile("setup/actor").
		SignProposeAndPayAs("marketplace").
		UFix64Argument("0.0").
		Run(), emptyMap)

	gwtf.PrintEvents(flow.TransactionFromFile("setup/versus").
		SignProposeAndPayAs("marketplace").
		UFix64Argument("0.15").      //cut percentage,
		Argument(cadence.UInt64(5)). //drop length
		Argument(cadence.UInt64(5)). //minimumBlockRemainingAfterBidOrTie
		Run(), emptyMap)

	fmt.Println()
	fmt.Println()
	fmt.Println("Create a drop in versus that is already started with 10 editions")
	fmt.Scanln()
	flow.CreateAccount("artist")
	gwtf.PrintEvents(flow.TransactionFromFile("setup/actor").SignProposeAndPayAs("artist").UFix64Argument("0.0").Run(), emptyMap)

	gwtf.PrintEvents(flow.TransactionFromFile("setup/drop").
		SignProposeAndPayAs("marketplace").
		AccountArgument("artist").                                                                      //marketplace location
		UFix64Argument("10.01").                                                                        //start price
		Argument(cadence.NewUInt64(11)).                                                                //start block
		StringArgument("Vincent Kamp").                                                                 //artist name
		StringArgument("when?").                                                                        //name of art
		StringArgument("https://ipfs.io/ipfs/QmURySCXsDh5tZUVVVNSnV1L8nxjVAoyChShGkvZ9NWF9A").          //image
		StringArgument("Here's a lockdown painting I did of a super cool guy and pal, @jburrowsactor"). //description
		Argument(cadence.NewUInt64(10)).                                                                //number of editions to use for the editioned auction
		UFix64Argument("5.0").                                                                          //min bid increment
		Run(), emptyMap)

	flow.ScriptFromFile("get_active_auction").AccountArgument("marketplace").Run()

	fmt.Println()
	fmt.Println()
	fmt.Println("Setup a buyer and make him bid on the unique auction")
	fmt.Scanln()
	flow.CreateAccount("buyer1")

	gwtf.PrintEvents(flow.TransactionFromFile("setup/actor").SignProposeAndPayAs("buyer1").UFix64Argument("100.0").Run(), emptyMap) //tokens to mint

	gwtf.PrintEvents(flow.TransactionFromFile("buy/bid").
		SignProposeAndPayAs("buyer1").
		AccountArgument("marketplace").
		Argument(cadence.UInt64(1)). //id of drop
		Argument(cadence.UInt64(1)). //id of auction to bid on
		UFix64Argument("10.01").     //amount to bid
		Run(), emptyMap)

	fmt.Println()
	fmt.Println()
	fmt.Println("Go to website to bid there")
	fmt.Scanln()
	fmt.Println("Tick the clock to make the auction end and settle it")
	fmt.Scanln()

	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").Argument(cadence.UInt64(1)).Run()
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").Argument(cadence.UInt64(1)).Run()
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").Argument(cadence.UInt64(1)).Run()
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").Argument(cadence.UInt64(1)).Run()
	flow.TransactionFromFile("tick").SignProposeAndPayAs("marketplace").Argument(cadence.UInt64(1)).Run()

	gwtf.PrintEvents(flow.TransactionFromFile("buy/settle").SignProposeAndPayAs("marketplace").Argument(cadence.UInt64(1)).Run(), emptyMap)

	flow.ScriptFromFile("check_account").AccountArgument("buyer1").StringArgument("buyer1").Run()
	flow.ScriptFromFile("check_account").AccountArgument("buyer2").StringArgument("buyer2").Run()
	flow.ScriptFromFile("check_account").AccountArgument("artist").StringArgument("artist").Run()
	flow.ScriptFromFile("check_account").AccountArgument("marketplace").StringArgument("marketplace").Run()
}