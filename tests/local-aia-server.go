// Package localAIA spins up a http server serving the contents of the
// test directory so that we can serve our own AIA certificates locally.
package main

import (
	"fmt"
	"net/http"
)

func main() {
	fs := http.FileServer(http.Dir("tests"))
	http.Handle("/", fs)

	err := http.ListenAndServe(":http", nil)

	if err != nil {
		fmt.Println(err)
	}
}
