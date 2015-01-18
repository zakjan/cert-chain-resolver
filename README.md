# cert-chain-resolver

SSL certificate chain resolver

## Dependencies

- OpenSSL
- curl

## Usage

```
./resolve.sh input.pem output.pem
```

All certificates are in Base64-encoded PEM format.

## Description

This tool can help you fix the *incomplete certificate chain* issue, also reported as *Extra download* by [Qualys SSL Server Test](https://www.ssllabs.com/ssltest/).

![Incomplete certificate chain](incomplete-chain.png)

All operating systems contain a set of default trusted root certificates. But CAs usually don't use their root certificate to sign customer certificates. Instead of they use so called intermediate certificates, because they can be rotated more frequently.

Your certificate contains a special *Authority Information Access* extension ([RFC-3280](http://tools.ietf.org/html/rfc3280)) with URL to issuer's certificate. Most browsers can use the AIA extension to download missing intermediate certificate to complete the certificate chain. This is the exact meaning of *Extra download* message. But some clients (mobile browsers, OpenSSL) don't support this extension, so they report your certificate as untrusted.

Your server should always send a complete chain, which means concatenated all certificates from your certificate to the trusted root certificate (exclusive, in this order), to prevent such issues. Note, the trusted root certificate should not be there.

You should be able to fetch intermediate certificates from the issuer and concat them together by yourself, this tool helps you to automatize it.
