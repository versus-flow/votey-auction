package main

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
)

/*
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
*/

func main() {

	flow := gwtf.NewGoWithTheFlowDevNet()

	//create the AdminPublicAndSomeOtherCollections
	flow.TransactionFromFile("setup/versus1_testnet").
		SignProposeAndPayAs("admin").
		RunPrintEventsFull()

	//link in the server in the versus client
	flow.TransactionFromFile("setup/versus2_testnet").
		SignProposeAndPayAs("versus").
		AccountArgument("admin").
		RunPrintEventsFull()

}
