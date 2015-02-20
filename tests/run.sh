#!/usr/bin/env sh

set -e # fail on unhandled error
set -u # fail on undefined variable


TESTS_DIR="$(dirname $0)"
CMD="$TESTS_DIR/../resolve.sh"


# it should download all intermediate CA certs - Comodo, PEM leaf, 2x DER intermediate
$CMD "$TESTS_DIR/comodo.crt" "$TESTS_DIR/output.crt"
diff "$TESTS_DIR/output.crt" "$TESTS_DIR/comodo.bundle.crt"
rm "$TESTS_DIR/output.crt"

# it should download all intermediate CA certs - Comodo, DER leaf, 2x DER intermediate
$CMD "$TESTS_DIR/comodo.der.crt" "$TESTS_DIR/output.crt"
diff "$TESTS_DIR/output.crt" "$TESTS_DIR/comodo.bundle.crt"
rm "$TESTS_DIR/output.crt"

# it should download all intermediate CA certs - GoDaddy, PEM leaf, PEM intermediate
$CMD "$TESTS_DIR/godaddy.crt" "$TESTS_DIR/output.crt"
diff "$TESTS_DIR/output.crt" "$TESTS_DIR/godaddy.bundle.crt"
rm "$TESTS_DIR/output.crt"
