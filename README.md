# cert-chain-resolver

SSL certificate chain resolver

## Dependencies

- OpenSSL
- curl

## Usage

```
./resolve.sh input-cert-filename output-chained-cert-filename
```

All certificates are in Base64-encoded PEM format.

## Description

This tool can help you with incomplete certificate chain issue, reported as *Extra download* by [Qualys SSL Server Test](https://www.ssllabs.com/ssltest/).

![Incomplete certificate chain](incomplete-chain.png)

Your system contains a set of default root certificates. But CAs usually don't use their root certificate to sign customer certificates. Instead of they use so called intermediate certificates, because they can be rotated more frequently.

You certificate contains a special *Authority Information Access* extension ([RFC-3280](http://tools.ietf.org/html/rfc3280)) with URL to issuer's certificate. Most of browsers can use the AIA extenstion to download missing intermediate certificate to complete the certificate chain. This is the exact meaning of *Extra download* issue. But some clients (mobile browsers, OpenSSL) don't support this extension, so they report your certificate as untrusted.

Your server should always send a complete chain, it means it should send all certificates from your certificate to the trusted root certificate (exclusive, in this order), to prevent such issues.

You should be able to download intermediate certificates from your certificate issuer and concat them together by yourself, this tool helps you to automatize it.

## TODO

- fail on private key file, accept only public key file
- fail on multiple certificates in input file
