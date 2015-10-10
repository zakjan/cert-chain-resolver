#!/bin/sh

set -u


DIR="$(dirname $0)"
CMD="$DIR/../src/cert-chain-resolver.sh"
TEMP_FILE="$(mktemp)"


(
  set -e

  # it should output certificate bundle in PEM format with Comodo, PEM leaf, 2x DER intermediate
  $CMD -o "$TEMP_FILE" "$DIR/comodo.crt"
  diff "$TEMP_FILE" "$DIR/comodo.bundle.crt"

  # it should output certificate bundle in PEM format with Comodo, DER leaf, 2x DER intermediate
  $CMD -o "$TEMP_FILE" "$DIR/comodo.der.crt"
  diff "$TEMP_FILE" "$DIR/comodo.bundle.crt"

  # it should output certificate bundle in PEM format with GoDaddy, PEM leaf, PEM intermediate
  $CMD -o "$TEMP_FILE" "$DIR/godaddy.crt"
  diff "$TEMP_FILE" "$DIR/godaddy.bundle.crt"

  # it should output certificate bundle in DER format
  $CMD -d -o "$TEMP_FILE" "$DIR/comodo.crt"
  diff "$TEMP_FILE" "$DIR/comodo.bundle.der.crt"

  # it should output certificate chain in PEM format
  $CMD -i -o "$TEMP_FILE" "$DIR/comodo.crt"
  diff "$TEMP_FILE" "$DIR/comodo.chain.crt"

  # it should output certificate chain in DER format
  $CMD -d -i -o "$TEMP_FILE" "$DIR/comodo.crt"
  diff "$TEMP_FILE" "$DIR/comodo.chain.der.crt"

  # it should output certificate bundle in PEM format, backward compatible
  $CMD "$DIR/comodo.crt" "$TEMP_FILE"
  diff "$TEMP_FILE" "$DIR/comodo.bundle.crt"
)
STATUS=$?


rm -f "$TEMP_FILE"

exit $STATUS
