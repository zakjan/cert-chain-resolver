#!/usr/bin/env sh

set -u


DIR="$(dirname $0)"
CMD="$DIR/../src/cert-chain-resolver.sh"
TEMP_FILE="$(mktemp)"


(
  set -e

  # it should download all intermediate CA certs - Comodo, PEM leaf, 2x DER intermediate
  $CMD -o "$TEMP_FILE" "$DIR/comodo.crt"
  diff "$TEMP_FILE" "$DIR/comodo.bundle.crt"

  # it should download all intermediate CA certs - Comodo, DER leaf, 2x DER intermediate
  $CMD -o "$TEMP_FILE" "$DIR/comodo.der.crt"
  diff "$TEMP_FILE" "$DIR/comodo.bundle.crt"

  # it should download all intermediate CA certs - GoDaddy, PEM leaf, PEM intermediate
  $CMD -o "$TEMP_FILE" "$DIR/godaddy.crt"
  diff "$TEMP_FILE" "$DIR/godaddy.bundle.crt"
)
STATUS=$?


rm -f "$TEMP_FILE"

exit $STATUS
