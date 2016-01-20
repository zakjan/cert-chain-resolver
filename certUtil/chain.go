package certUtil

import (
	"crypto/x509"
	"io/ioutil"
	"net/http"
)

func FetchCertificateChain(cert *x509.Certificate) ([]*x509.Certificate, error) {
	var certs []*x509.Certificate

	certs = append(certs, cert)

	for certs[len(certs)-1].IssuingCertificateURL != nil {
		parentURL := certs[len(certs)-1].IssuingCertificateURL[0]

		resp, err := http.Get(parentURL)
		if resp != nil {
			defer resp.Body.Close()
		}
		if err != nil {
			return nil, err
		}

		data, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return nil, err
		}

		cert, err := DecodeCertificate(data)
		if err != nil {
			return nil, err
		}

		certs = append(certs, cert)
	}

	return certs, nil
}
