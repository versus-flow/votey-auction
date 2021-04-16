package main

import (
	"bufio"
	"encoding/base64"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/mitchellh/go-homedir"
	"github.com/onflow/cadence"
)

func fileAsImageData(path string) string {
	f, _ := os.Open("./" + path)

	defer f.Close()

	// Read entire JPG into byte slice.
	reader := bufio.NewReader(f)
	content, _ := ioutil.ReadAll(reader)

	contentType := http.DetectContentType(content)

	// Encode as base64.
	encoded := base64.StdEncoding.EncodeToString(content)

	return "data:" + contentType + ";base64, " + encoded
}

func main() {
	number, ok := os.LookupEnv("number")
	if !ok {
		fmt.Println("number is not present")
		os.Exit(1)
	}

	flowConfigFile, _ := homedir.Expand("~/.flow-testnet.json")
	flow := gwtf.NewGoWithTheFlow(flowConfigFile)

	now := time.Now()
	t := now.Unix()
	timeString := strconv.FormatInt(t, 10) + ".0"

	image := fileAsImageData("bull.png")

	flow.TransactionFromFile("setup/drop_testnet").
		SignProposeAndPayAs("versus").
		AccountArgument("artist").             //artist address
		UFix64Argument("1.00").               //start price
		UFix64Argument(timeString).            //start time
		StringArgument("Kinger9999").          //artist name
		StringArgument("CryptoBull" + number). //name of art
		StringArgument(image).                 //imaage
		StringArgument("An Angry bull").
		Argument(cadence.NewUInt64(10)). //number of editions to use for the editioned auction
		UFix64Argument("5.0").           //min bid increment
		UFix64Argument("10.0").           //min bid increment unique
		RunPrintEventsFull()

}
