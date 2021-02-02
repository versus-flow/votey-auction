all: demo

.PHONY: demo
demo:
	go run ./examples/demo/main.go

.PHONY: clean
clean:
	rm -Rf flowdb

.PHONY: emulator
emulator: clean
	flow emulator start -v --persist
