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
		EventIgnoringFields("A.d5ee212b0fa4a319.Versus.Bid", []string{"auctionId", "dropId"}).
		EventIgnoringFields("A.d5ee212b0fa4a319.Versus.LeaderChanged", []string{"dropId"}).
		Event("A.d5ee212b0fa4a319.Versus.Settle")

	_, err := eb.Run()
	if err != nil {
		panic(err)
	}
}
