#!/bin/sh

set -eu


if [ -d out ]; then
    rm -r out
fi
mkdir out


cd cert-chain-resolver

for GOOS in linux darwin windows; do
    GOARCH="amd64"

    echo "Building ${GOOS}_${GOARCH}"

    OUT="cert-chain-resolver_${GOOS}_${GOARCH}"
    if [ "$GOOS" == "windows" ]; then
        OUT="${OUT}.exe"
    fi

    GOOS="$GOOS" GOARCH="$GOARCH" go build -o "../out/$OUT"
done
