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
		Event("A.467694dd28ef0a12.Versus.Bid").
		Event("A.467694dd28ef0a12.Versus.LeaderChanged").
		Event("A.467694dd28ef0a12.Versus.Settle").
		Event("A.467694dd28ef0a12.Versus.DropExtended").
		Event("A.467694dd28ef0a12.Versus.DropCreated")

	_, err := eb.Run()
	if err != nil {
		panic(err)
	}
}
