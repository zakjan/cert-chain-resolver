#!/bin/sh

# SSL certificate chain resolver
#
# https://github.com/zakjan/cert-chain-resolver
#
# Copyright (c) 2015 Jan Žák (http://zakjan.cz)
# The MIT License (MIT).


alias command_exists="type >/dev/null 2>&1"
alias echoerr="echo >&2"


cert_normalize_to_pem() {
  # bash variables can't contain binary data with null-bytes, so it needs to be stored encoded, and decoded before use
  local INPUT="$(openssl base64)"

  if CERT=$(echo "$INPUT" | openssl base64 -d | openssl x509 -inform pem -outform pem 2>/dev/null); then
    echo "$CERT"
    return
  fi

  if CERT=$(echo "$INPUT" | openssl base64 -d | openssl x509 -inform der -outform pem 2>/dev/null); then
    echo "$CERT"
    return
  fi

  echoerr "Invalid certificate"
  return 1
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
  echoerr "SSL certificate chain resolver"
  echoerr
  echoerr "Usage: ./cert-chain-resolver.sh [OPTION]... [INPUT_FILE]"
  echoerr
  echoerr "Read certificate from stdin, or INPUT_FILE if specified. The input certificate can be in either DER or PEM format."
  echoerr "Write certificate bundle to stdout in PEM format, with both leaf and intermediate certificates."
  echoerr
  echoerr "    -d|--der"
  echoerr
  echoerr "        output DER format"
  echoerr
  echoerr "    -i|--intermediate-only"
  echoerr
  echoerr "        output intermediate certificates only, without leaf certificate"
  echoerr
  echoerr "    -o|--output OUTPUT_FILE"
  echoerr
  echoerr "        write output to OUTPUT_FILE"
}

check_dependencies() {
  if ! command_exists wget; then
    echoerr "Error: wget is required"
    return 1
  fi

  if ! command_exists openssl; then
    echoerr "Error: openssl is required"
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
      -*) echoerr "Unknown option $1"; echoerr "See --help for accepted options"; return 1;;
      *) break;;
    esac
  done

  if [ -n "$1" ]; then
    INPUT_FILENAME="$1"
  elif [ -t 0 ]; then
    # stdin is not available
    usage
    return 1
  fi

  # Retained for backward compatibility
  if [ -n "$2" ]; then
    OUTPUT_FILENAME="$2"
  fi
}

main() {
  if ! check_dependencies; then
    return 1
  fi

  if ! parse_opts "$@"; then
    return 1
  fi

  local CURRENT_CERT
  local CURRENT_SUBJECT
  local ISSUER_CERT_URL

  > "$OUTPUT_FILENAME" # clear output file

  # extract the first certificate from input file, to make this script idempotent; normalize to PEM
  if ! CURRENT_CERT=$(cat "$INPUT_FILENAME" | cert_normalize_to_pem); then
    return 1
  fi

  # loop over certificate chain using AIA extension, CA Issuers field
  I=0
  while true; do
    # get certificate subject
    CURRENT_SUBJECT=$(echo "$CURRENT_CERT" | cert_get_subject)
    echoerr "$((I+1)): $CURRENT_SUBJECT"

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
    if ! CURRENT_CERT=$(wget -q -O - "$ISSUER_CERT_URL" | cert_normalize_to_pem); then
      return 1
    fi

    I=$((I+1))
  done

  echoerr "Certificate chain complete."
  echoerr "Total $((I+1)) certificate(s) found."
}

main "$@"
