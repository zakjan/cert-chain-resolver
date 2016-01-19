package main

import (
	"bufio"
	"crypto/x509"
	"encoding/pem"
	"errors"
	"io"
	"io/ioutil"
)

func ParseCertificate(data []byte) (*x509.Certificate, error) {
	block, rest := pem.Decode(data)

	if block != nil {
		data = block.Bytes
	} else {
		// accept DER input
		data = rest
	}

	certs, err := x509.ParseCertificates(data)
	if err != nil {
		return nil, errors.New("Invalid certificate.")
	}
	if len(certs) < 1 {
		return nil, errors.New("No certificate.")
	}

	// return only the first certificate from input, to make this app idempotent
	cert := certs[0]

	return cert, nil
}

func ReadCertificate(reader io.Reader) (*x509.Certificate, error) {
	data, err := ioutil.ReadAll(reader)
	if err != nil {
		return nil, err
	}

	cert, err := ParseCertificate(data)
	if err != nil {
		return nil, err
	}

	return cert, nil
}

func WriteCertificate(writer io.Writer, certs []*x509.Certificate, options Options) error {
	bufWriter := bufio.NewWriter(writer)

	for i, cert := range certs {
		if options.OutputIntermediateOnly == true && i == 0 {
			continue
		}

		if options.OutputDerFormat == false {
			block := pem.Block{
				Type:  "CERTIFICATE",
				Bytes: cert.Raw,
			}

			err := pem.Encode(bufWriter, &block)
			if err != nil {
				return err
			}
		} else {
			bufWriter.Write(cert.Raw)
		}
	}

	err := bufWriter.Flush()
	if err != nil {
		return err
	}

	return nil
}
