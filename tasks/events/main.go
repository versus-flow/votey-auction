package main

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
)

func main() {

	// cronjob ready, read blockHeight from file
	g := gwtf.NewGoWithTheFlow("/Users/bjartek/.flow-dev.json")

	//fetch the current block height
	eb := g.SendEventsTo("beta").
		TrackProgressIn("/Users/bjartek/.flow-dev.events").
		Event("A.bc08417e9d472f2e.Versus.Bid").
		Event("A.bc08417e9d472f2e.Versus.LeaderChanged").
		Event("A.bc08417e9d472f2e.Versus.Settle").
		Event("A.bc08417e9d472f2e.Versus.DropExtended").
		Event("A.bc08417e9d472f2e.Versus.DropCreated")

	_, err := eb.Run()
	if err != nil {
		panic(err)
	}
}
