#!/bin/sh

set -u


DIR="$(dirname $0)"
CMD="${DIR}/../cert-chain-resolver"
TEMP_FILE="$(mktemp)"


(
    set -e

    echo 'it should output certificate bundle in PEM format (Comodo, PEM leaf, 2x DER intermediate)'
    $CMD -o "$TEMP_FILE" "$DIR/comodo.crt"
    diff "$TEMP_FILE" "$DIR/comodo.bundle.crt"

    echo 'it should output certificate bundle in PEM format (Comodo, DER leaf, 2x DER intermediate)'
    $CMD -o "$TEMP_FILE" "$DIR/comodo.der.crt"
    diff "$TEMP_FILE" "$DIR/comodo.bundle.crt"

    echo 'it should output certificate bundle in PEM format (GoDaddy, PEM leaf, PEM intermediate)'
    $CMD -o "$TEMP_FILE" "$DIR/godaddy.crt"
    diff "$TEMP_FILE" "$DIR/godaddy.bundle.crt"

    echo 'it should output certificate bundle in PEM format (zedat.fu-berlin.de, multiple issuer URLs)'
    $CMD -o "$TEMP_FILE" "$DIR/zedat.crt"
    diff "$TEMP_FILE" "$DIR/zedat.bundle.crt"

    echo 'it should output certificate bundle in DER format (Comodo, PEM leaf, 2x DER intermediate)'
    $CMD -d -o "$TEMP_FILE" "$DIR/comodo.crt"
    diff "$TEMP_FILE" "$DIR/comodo.bundle.der.crt"

    echo 'it should output certificate chain in PEM format (Comodo, PEM leaf, 2x DER intermediate)'
    $CMD -i -o "$TEMP_FILE" "$DIR/comodo.crt"
    diff "$TEMP_FILE" "$DIR/comodo.chain.crt"

    echo 'it should output certificate chain in DER format (Comodo, PEM leaf, 2x DER intermediate)'
    $CMD -d -i -o "$TEMP_FILE" "$DIR/comodo.crt"
    diff "$TEMP_FILE" "$DIR/comodo.chain.der.crt"

    echo 'it should output certificate bundle in PEM format with root CA from system (Comodo, PEM leaf, 2x DER intermediate)'
    $CMD -s -o "$TEMP_FILE" "$DIR/comodo.crt"
    diff "$TEMP_FILE" "$DIR/comodo.withca.crt"

    echo 'it should output certificate bundle in PEM format with root CA from system (zedat.fu-berlin.de, multiple issuer URLs)'
    $CMD -s -o "$TEMP_FILE" "$DIR/zedat.crt"
    diff "$TEMP_FILE" "$DIR/zedat.withca.bundle.crt"

    echo 'it should output certificate bundle in PEM format (DST Root CA X3, PKCS#7 leaf)'
    $CMD -o "$TEMP_FILE" "$DIR/dstrootcax3.p7c"
    diff "$TEMP_FILE" "$DIR/dstrootcax3.pem"

    echo 'it should output certificate bundle in PEM format with input from stdin and output to stdout (Comodo, PEM leaf, 2x DER intermediate)'
    $CMD < "$DIR/comodo.crt" > "$TEMP_FILE"
    diff "$TEMP_FILE" "$DIR/comodo.bundle.crt"

    echo 'it should detect invalid certificate'
    (
        set +e
        ! echo "xxx" | $CMD
    )

    # build and start the webserver to serve the certificates
    go build -o  "${DIR}/http-server" "${DIR}/http-server.go"
    "${DIR}/http-server" "${DIR}" &
    PID="$!"
    sleep 1

    echo 'it should correctly detect root certificates to prevent infinite traversal loops when the root certificate also has an AIA Certification Authority Issuer record'
    $CMD -o "$TEMP_FILE" "$DIR/self-issued.crt"
    diff "$TEMP_FILE" "$DIR/self-issued.bundle.crt"

    # stop the webserver
    kill "$PID"
)
STATUS="$?"


rm -f "$TEMP_FILE"

exit "$STATUS"
