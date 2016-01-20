#!/usr/bin/env bash

set -eu


dependencies() {
    rsync -a --delete . "/home/ubuntu/.go_workspace/src/github.com/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}"

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
    NAME="${CIRCLE_PROJECT_REPONAME}"
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
