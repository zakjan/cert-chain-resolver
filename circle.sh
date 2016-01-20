#!/usr/bin/env bash

set -eu


dependencies() {
    go get github.com/Masterminds/glide
    glide install
}

build() {
    go build -o out/cert-chain-resolver
}

test() {
    go test ./...
    tests/run.sh
}

release() {
    NAME="cert-chain-resolver"
    GOARCH="amd64"

    rm -rf out
    mkdir out

    for GOOS in linux darwin windows; do
        echo "Building ${GOOS}_${GOARCH}"

        OUT="${NAME}_${GOOS}_${GOARCH}"
        if [ "$GOOS" = "windows" ]; then
            OUT="${OUT}.exe"
        fi

        GOOS="$GOOS" GOARCH="$GOARCH" go build -o "out/${OUT}"
    done
}


case "$1" in
    dependencies)
        dependencies;;
    build)
        build;;
    test)
        test;;
    release)
        release;;
esac
