#!/usr/bin/env sh

set -e # fail on unhandled error
set -u # fail on undefined variable


TESTS_DIR="$(dirname $0)"
CMD="$TESTS_DIR/../resolve.sh"

# it should download all intermediate CA certs for PEM input
$CMD "$TESTS_DIR/input.crt" "$TESTS_DIR/output.crt"
diff "$TESTS_DIR/output.crt" "$TESTS_DIR/output.expected.crt"
rm "$TESTS_DIR/output.crt"

# it should download all intermediate CA certs for DER input
$CMD "$TESTS_DIR/input.der.crt" "$TESTS_DIR/output.crt"
diff "$TESTS_DIR/output.crt" "$TESTS_DIR/output.expected.crt"
rm "$TESTS_DIR/output.crt"
