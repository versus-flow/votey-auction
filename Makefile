all: demo

#run the demo script on devnet
.PHONY: demo
demo: deploy
	go run ./tasks/demo/main.go

.PHONY: marketplace
marketplace: deploy
	go run ./tasks/marketplace/main.go

#this goal deployes all the contracts to emulator
.PHONY: deploy
deploy:
	flow project deploy  -n emulator


#this goal mints new flow tokens on emulator takes an account(Addres) env and can take an amount(int:100) env
.PHONY:mint
mint:
	go run ./tasks/mint/main.go


#this goal transfers funds on testnet required an account(Address) env and can take an amount(int:100) env
.PHONY: transfer
transfer:
	go run ./tasks/transfer/main.go

#this goal settles and drop on testnet requires a drop(int) argument
.PHONY: settle
settle:
	go run ./tasks/settle_first/main.go

#this goal creates and example drop on testnet, requires drop(string) env that will be used as NFT name suffix
.PHONY: drop
drop:
	go run ./tasks/drop/main.go

.PHONY: setup-testnet
setup-testnet:
	go run ./tasks/setup_testnet/main.go

#set up the marketplace on testnet
.PHONY: testnet
testnet: deploy-testnet
	go run ./tasks/testnet/main.go

#this goal deployes all the contracts to emulator
.PHONY: deploy-testnet
deploy-testnet: setup-testnet
	flow project deploy  -n testnet -f ~/.flow-dev.json

.PHONY: get-drop
get-drop:
	go run ./tasks/get_drop/main.go

.PHONY: art
art:
	go run ./tasks/mint_art/main.go
