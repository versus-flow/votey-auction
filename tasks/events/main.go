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
		Event("A.6bb8a74d4db97b46.Versus.Bid").
		Event("A.6bb8a74d4db97b46.Versus.LeaderChanged").
		Event("A.6bb8a74d4db97b46.Versus.Settle").
		Event("A.6bb8a74d4db97b46.Versus.DropExtended").
		Event("A.6bb8a74d4db97b46.Versus.DropCreated")

	_, err := eb.Run()
	if err != nil {
		panic(err)
	}
}
