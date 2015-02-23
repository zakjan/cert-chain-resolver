#!/usr/bin/env sh

set -e # fail on unhandled error
set -u # fail on undefined variable


DIR="$(dirname $0)"
CMD="$DIR/../src/resolve.sh"


# it should download all intermediate CA certs - Comodo, PEM leaf, 2x DER intermediate
$CMD "$DIR/comodo.crt" "$DIR/output.crt"
diff "$DIR/output.crt" "$DIR/comodo.bundle.crt"
rm "$DIR/output.crt"

# it should download all intermediate CA certs - Comodo, DER leaf, 2x DER intermediate
$CMD "$DIR/comodo.der.crt" "$DIR/output.crt"
diff "$DIR/output.crt" "$DIR/comodo.bundle.crt"
rm "$DIR/output.crt"

# it should download all intermediate CA certs - GoDaddy, PEM leaf, PEM intermediate
$CMD "$DIR/godaddy.crt" "$DIR/output.crt"
diff "$DIR/output.crt" "$DIR/godaddy.bundle.crt"
rm "$DIR/output.crt"
