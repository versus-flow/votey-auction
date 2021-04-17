package main

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/davecgh/go-spew/spew"
)

func main() {

	flow := gwtf.NewGoWithTheFlowDevNet()

	value := flow.ScriptFromFile("get_active_auction").AccountArgument("versus").RunReturns()
	spew.Dump(value)
}
