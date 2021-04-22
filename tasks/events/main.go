package main

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
)

func main() {

	// cronjob ready, read blockHeight from file
	g := gwtf.NewGoWithTheFlow(".flow-dev.json")

	//fetch the current block height
	eb := g.SendEventsTo("beta").
		TrackProgressIn(".flow-dev.events").
		Event("A.e193e719ae2b5853.Versus.Bid").
		Event("A.e193e719ae2b5853.Versus.LeaderChanged").
		Event("A.e193e719ae2b5853.Versus.Settle").
		Event("A.e193e719ae2b5853.Versus.DropExtended").
		Event("A.e193e719ae2b5853.Versus.DropCreated")

	_, err := eb.Run()
	if err != nil {
		panic(err)
	}
}
