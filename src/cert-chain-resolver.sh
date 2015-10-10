#!/bin/sh

# SSL certificate chain resolver
#
# https://github.com/zakjan/cert-chain-resolver
#
# Copyright (c) 2015 Jan Žák (http://zakjan.cz)
# The MIT License (MIT).

alias error="echo >&2"
alias command_exists="type >/dev/null 2>&1"


cert_is_der() {
  ! grep -e "-----" >/dev/null
}

cert_normalize_to_pem() {
  # bash variables can't contain binary data with null-bytes, so it needs to be stored encoded, and decoded before use
  local CERT="$(openssl base64)"
  if echo "$CERT" | openssl base64 -d | cert_is_der; then
    echo "$CERT" | openssl base64 -d | openssl x509 -inform der -outform pem
  else
    echo "$CERT" | openssl base64 -d | openssl x509 -inform pem -outform pem # output only the first certificate
  fi
}

cert_pem_to_text() {
  # certificate is parsed from OpenSSL text output. dirty solution, but it works
  openssl x509 -inform pem -noout -text
}

cert_get_subject() {
  cert_pem_to_text | awk 'BEGIN {FS="Subject: "} NF==2 {print $2}'
}

cert_get_issuer_url() {
  cert_pem_to_text | awk 'BEGIN {FS="CA Issuers - URI:"} NF==2 {print $2}'
}



usage() {
  error "SSL certificate chain resolver"
  error
  error "Usage: ./cert-chain-resolver.sh [OPTION]... [INPUT_FILE]"
  error
  error "Read input from INPUT_FILE or stdin, in either DER or PEM format."
  error "Write output to stdout in PEM format, both leaf and intermediate certificates."
  error
  error "    -d|--der"
  error
  error "        output DER format"
  error
  error "    -i|--intermediate-only"
  error
  error "        output intermediate certificates only, without leaf certificate"
  error "        use for Apache < 2.4.8, AWS"
  error
  error "    -o|--output OUTPUT_FILE"
  error
  error "        write output to OUTPUT_FILE"
}

check_dependencies() {
  if ! command_exists wget; then
    error "Error: wget is required"
    return 1
  fi

  if ! command_exists openssl; then
    error "Error: openssl is required"
    return 1
  fi
}

parse_opts() {
  INPUT_FILENAME="/dev/stdin"
  OUTPUT_FILENAME="/dev/stdout"
  OUTPUT_DER_FORMAT=
  OUTPUT_INTERMEDIATE_ONLY=

  while [ $# -gt 0 ]; do
    case "$1" in
      -d|--der) OUTPUT_DER_FORMAT=1; shift;;
      -i|--intermediate-only) OUTPUT_INTERMEDIATE_ONLY=1; shift;;
      -o|--output) OUTPUT_FILENAME="$2"; shift 2;;
      -h|--help) usage; return 1;;
      -*) error "Unknown option $1"; error "See --help for accepted options"; return 1;;
      *) break;;
    esac
  done

  if [ -n "$1" ]; then
    INPUT_FILENAME="$1"
  fi

  if [ -n "$2" ]; then
    OUTPUT_FILENAME="$2"
  fi
}

main() {
  if ! check_dependencies; then
    exit 1
  fi

  if ! parse_opts "$@"; then
    exit 1
  fi

  > "$OUTPUT_FILENAME" # clear output file


  # extract the first certificate from input file, to make this script idempotent; normalize to PEM
  CURRENT_CERT=$(cat "$INPUT_FILENAME" | cert_normalize_to_pem)

  # loop over certificate chain using AIA extension, CA Issuers field
  I=0
  while true; do
    # get certificate subject
    CURRENT_SUBJECT=$(echo "$CURRENT_CERT" | cert_get_subject)
    error "$((I+1)): $CURRENT_SUBJECT"

    # append certificate to result
    if [ "$I" -gt 0 ] || [ -z "$OUTPUT_INTERMEDIATE_ONLY" ]; then
      if [ -n "$OUTPUT_DER_FORMAT" ]; then
        echo "$CURRENT_CERT" | openssl x509 -inform pem -outform der >> "$OUTPUT_FILENAME"
      else
        echo "$CURRENT_CERT" >> "$OUTPUT_FILENAME"
      fi
    fi

    # get issuer's certificate URL
    ISSUER_CERT_URL=$(echo "$CURRENT_CERT" | cert_get_issuer_url)
    if [ -z "$ISSUER_CERT_URL" ]; then
      break
    fi

    # download issuer's certificate, normalize to PEM
    CURRENT_CERT=$(wget -q -O - "$ISSUER_CERT_URL" | cert_normalize_to_pem)

    I=$((I+1))
  done


  error "Certificate chain complete."
  error "Total $((I+1)) certificate(s) found."
}

main "$@"
