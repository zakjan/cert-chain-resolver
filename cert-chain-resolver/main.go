package main

import (
	"fmt"
	"os"
)

func run() error {
	options, err := GetOptions()
	if err != nil {
		return err
	}

	cert, err := ReadCertificate(options.InputReader)
	if err != nil {
		return err
	}

	certs, err := ResolveCertificateChain(cert)
	if err != nil {
		return err
	}

	for i, cert := range certs {
		fmt.Fprintf(os.Stderr, "%d: %s\n", i+1, cert.Subject.CommonName)
	}
	fmt.Fprintf(os.Stderr, "Certificate chain complete.\n")
	fmt.Fprintf(os.Stderr, "Total %d certificate(s) found.\n", len(certs))

	err = WriteCertificate(options.OutputWriter, certs, options)
	if err != nil {
		return err
	}

	return nil
}

func main() {
	err := run()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
