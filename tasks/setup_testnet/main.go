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

	flow.TransactionFromFile("setup/transfer_flow").
		SignProposeAndPayAsService().
		UFix64Argument("1000.0").
		AccountArgument("versus").
		RunPrintEventsFull()

	flow.TransactionFromFile("setup/transfer_flow").
		SignProposeAndPayAsService().
		UFix64Argument("100.0").
		AccountArgument("admin").
		RunPrintEventsFull()

}
