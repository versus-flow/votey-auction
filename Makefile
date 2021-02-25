all: demo

.PHONY: demo
demo: deploy
	go run ./examples/demo/main.go

.PHONY: clean
clean:
	rm -Rf flowdb

.PHONY:mint
mint:
	go run ./examples/mint/main.go

.PHONY: emulator
emulator: clean
	flow emulator start -v --persist

.PHONY: testnet
testnet:
	go run ./examples/testnet/main.go

.PHONY: deploy
deploy:
	flow project deploy 