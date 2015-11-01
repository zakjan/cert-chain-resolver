#!/bin/sh

set -eu


cd cert-chain-resolver

for GOOS in linux darwin windows; do
    GOARCH="amd64"

    echo "Building ${GOOS}_${GOARCH}"

    OUT="cert-chain-resolver"
    if [ "$GOOS" == "windows" ]; then
        OUT="${OUT}.exe"
    fi

    GOOS="$GOOS" GOARCH="$GOARCH" go build -o "../out/${GOOS}_${GOARCH}/${OUT}"
done
