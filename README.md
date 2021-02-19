# Versus Flow Auction Contract

This is a git repo for the cadence contrats for versus@flow. Follow the guide below to set it up and test locally in the terminal.

## Prerequisites

1. Ensure Go is [installed on your machine](https://golang.org/dl/) `recommended version 1.13^`
2. [Install the Flow CLI](https://docs.onflow.org/docs/cli) 
3. Run `$ git clone https://github.com/versus-flow/auction-flow-contract` in a terminal window
4. Change to the project directory `cd auction-flow-contract`
5. Rename `flow.sample.json` to `flow.json`: `$ mv flow.sample.json flow.json`

## How to run the sample

Start two terminals. Both from the root directory.
 - `flow emualator start -v --persist`
- `make demo`

## What happends in the sample

1. install all the contracts
2. setup an artist with a wallet to receive his share
2. setup a marketplace and put a single 1 vs 10 auction active. Marketplace cut is 15%
3. setup bidder1 
4. have bidder1 bid on the auction
5. if you want to you can now start the webpage from the https://github.com/versus-flow/versus-action-website repo to explore the web side 
6. tick the clock and settle the auction
7. settle the auction
8. check all the accounts


## Deploy to testnet

create a file flow-dev.json
put your service account into the service field. account created with faucet

