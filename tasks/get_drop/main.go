package main

import (
	"fmt"
	"os"
	"strconv"

	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/onflow/cadence"
)

func main() {
	dropID, ok := os.LookupEnv("drop")
	if !ok {
		fmt.Println("drop is not present")
		os.Exit(1)
	}

	drop, err := strconv.ParseUint(dropID, 10, 64)
	if err != nil {
		fmt.Println("could not parse drop as number")
	}
	flow := gwtf.NewGoWithTheFlowDevNet()

	result := flow.ScriptFromFile("drop_status").UInt64Argument(drop).RunReturns()
	resultStruct := result.(cadence.Struct)
	names := resultStruct.StructType.Fields
	
	for i, field := range resultStruct.Fields {
		fmt.Printf("%v=%v\n", names[i].Identifier, field)

	}

}
