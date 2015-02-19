#!/usr/bin/env sh

# Copyright (c) 2015 Jan Žák (http://zakjan.cz)
# The MIT License (MIT).

set -e # fail on unhandled error
set -u # fail on undefined variable
# set -x # debug


alias command_exists="type >/dev/null 2>&1"

if command_exists curl; then
  alias download_file="curl -s"
elif command_exists wget; then
  alias download_file="wget -q -O -"
else
  echo "Error: curl or wget is required"
  exit 1
fi

if ! command_exists openssl; then
  echo "Error: openssl is required"
  exit 1
fi

cert_is_pem() {
  grep -e "-----" >/dev/null
}

# normalize to PEM
cert_to_pem() {
  # bash variables can't contain binary data with null-bytes, so it needs to be stored encoded, and decoded before use
  CERT=$(openssl base64)
  if ! echo "$CERT" | openssl base64 -d | cert_is_pem; then
    echo "$CERT" | openssl base64 -d | openssl x509 -inform der
  else
    echo "$CERT" | openssl base64 -d | openssl x509
  fi
}

# certificate is parsed from OpenSSL text output. dirty solution, but it works
cert_pem_to_text() {
  openssl x509 -noout -text
}

cert_get_subject() {
  cert_pem_to_text | awk 'BEGIN{FS="Subject: "} NF==2{print $2}'
}

cert_get_issuer_url() {
  cert_pem_to_text | awk 'BEGIN{FS="CA Issuers - URI:"} NF==2{print $2}'
}


# run!
if [ $# != 2 ]; then
  echo "SSL certificate chain resolver"
  echo
  echo "Usage: $0 input.crt output.crt"
  echo
  echo "Input certificate can be in either DER or PEM format."
  echo "Output certificate is in PEM format."
  exit
fi

FILENAME="$1"
OUTPUT_FILENAME="$2"

> "$OUTPUT_FILENAME" # clear output file


# extract the first certificate from input file, to make this script idempotent; normalize to PEM
CURRENT_CERT=$(cat "$FILENAME" | cert_to_pem)

# loop over certificate chain using AIA extension, CA Issuers field
I=0
while true; do
  # get certificate subject
  CURRENT_SUBJECT=$(echo "$CURRENT_CERT" | cert_get_subject)
  echo "$((I+1)): $CURRENT_SUBJECT"

  # append certificate to result
  echo "$CURRENT_CERT" >> "$OUTPUT_FILENAME"

  # get issuer's certificate URL
  PARENT_URL=$(echo "$CURRENT_CERT" | cert_get_issuer_url)
  if [ -z "$PARENT_URL" ]; then
    break
  fi

  # download issuer's certificate, normalize to PEM
  CURRENT_CERT=$(download_file "$PARENT_URL" | cert_to_pem)

  I=$((I+1))
done


echo
echo "Certificate chain complete."
echo "Total $((I+1)) certificate(s) written."

# verify the certificate chain
if ! openssl verify -untrusted "$OUTPUT_FILENAME" "$OUTPUT_FILENAME" > /dev/null; then
  echo "Error: verification failed"
  exit 1
fi
echo "Verified successfully."
