package main

import (
	"bufio"
	"encoding/base64"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"

	"github.com/bjartek/go-with-the-flow/gwtf"
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
	flow := gwtf.NewGoWithTheFlowDevNet()

	account, ok := os.LookupEnv("account")
	if !ok {
		fmt.Println("account is not present")
		os.Exit(1)
	}

	imageFile, ok := os.LookupEnv("image")
	if !ok {
		imageFile = "bull.png"
	}

	image := fileAsImageData(imageFile)
	flow.TransactionFromFile("setup/mint_art").
		SignProposeAndPayAs("admin").
		RawAccountArgument(account).
		StringArgument("ExampleArtist"). //artist name
		StringArgument("Example title"). //name of art
		StringArgument(image).           //imaage
		StringArgument("Description").
		RunPrintEventsFull()

}
