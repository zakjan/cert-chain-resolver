# SSL certificate chain resolver

[![CircleCI](https://img.shields.io/circleci/project/zakjan/cert-chain-resolver.svg)](https://circleci.com/gh/zakjan/cert-chain-resolver)
[![Licence](https://img.shields.io/badge/licence-MIT-blue.svg)](https://tldrlegal.com/license/mit-license)

This shell script downloads all intermediate CA certificates for a given SSL server certificate. It can help you fix the *incomplete certificate chain* issue, also reported as *Extra download* by [Qualys SSL Server Test](https://www.ssllabs.com/ssltest/).

## Dependencies

- wget
- OpenSSL

## Usage

```
SSL certificate chain resolver

Usage: ./cert-chain-resolver.sh [OPTION]... [INPUT_FILE]

Read input from INPUT_FILE or stdin, in either DER or PEM format.
Write output to stdout in PEM format, both leaf and intermediate certificates.

    -d|--der
        output DER format

    -i|--intermediate-only

        output intermediate certificates only, without leaf certificate

    -o|--output OUTPUT_FILE
        write output to OUTPUT_FILE
```

## Example

```
$ grep 'CERTIFICATE' input.crt
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----

$ ./cert-chain-resolver.sh -o output.crt input.crt
1: OU=Domain Control Validated, OU=PositiveSSL Wildcard, CN=*.xxx.com
2: C=GB, ST=Greater Manchester, L=Salford, O=COMODO CA Limited, CN=COMODO RSA Domain Validation Secure Server CA
3: C=GB, ST=Greater Manchester, L=Salford, O=COMODO CA Limited, CN=COMODO RSA Certification Authority

Certificate chain complete.
Total 3 certificate(s) written.
Verified successfully.

$ grep 'CERTIFICATE' output.crt
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
```

## Tests

```
tests/run.sh
```

## Background

![Incomplete certificate chain](images/incomplete-chain.png)

All operating systems contain a set of default trusted root certificates. But CAs usually don't use their root certificate to sign customer certificates. Instead of they use so called intermediate certificates, because they can be rotated more frequently.

A certificate can contain a special *Authority Information Access* extension ([RFC-3280](http://tools.ietf.org/html/rfc3280)) with URL to issuer's certificate. Most browsers can use the AIA extension to download missing intermediate certificate to complete the certificate chain. This is the exact meaning of the *Extra download* message. But some clients (mobile browsers, OpenSSL) don't support this extension, so they report such certificate as untrusted.

A server should always send a complete chain, which means concatenated all certificates from the certificate to the trusted root certificate (exclusive, in this order), to prevent such issues. Note, the trusted root certificate should not be there, as it is already included in the system’s root certificate store.

You should be able to fetch intermediate certificates from the issuer and concat them together by yourself, this script helps you automatize it by looping over certificate's AIA extension field.

## Other implementations

- [https://certificatechain.io/](https://certificatechain.io/) (webservice)
- [freekmurze/ssl-certificate-chain-resolver](https://github.com/freekmurze/ssl-certificate-chain-resolver) (PHP)

## Licence

The MIT License (MIT). See [LICENCE](LICENCE) file for more information. [TL;DR](https://tldrlegal.com/license/mit-license)

If you use my code in some interesting project, I'd be happy to know about it.
