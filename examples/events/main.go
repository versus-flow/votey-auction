package main

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
)

func main() {

	// cronjob ready, read blockHeight from file
	g := gwtf.NewGoWithTheFlow("/Users/bjartek/.flow-dev.json")

	//fetch the current block height
	eb := g.SendEventsTo("gwtf").
		TrackProgressIn("/Users/bjartek/.flow-dev.events").
		Event("A.1ff7e32d71183db0.Versus.Bid")

	_, err := eb.Run()
	if err != nil {
		panic(err)
	}
}
