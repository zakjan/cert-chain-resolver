#!/usr/bin/env bash

set -eu


NAME="${CIRCLE_PROJECT_REPONAME}"


dependencies() {
    go get github.com/Masterminds/glide
    glide install

    GO_PROJECT_HOME="/home/ubuntu/.go_workspace/src/$(glide name)"

    mkdir -p "$GO_PROJECT_HOME"
    rsync -a --delete . "$GO_PROJECT_HOME"
}

build() {
    go build -o "out/${NAME}"
}

test() {
    go test $(glide novendor)
    tests/run.sh
}

release() {
    rm -rf out
    mkdir out

    GOARCH="amd64"

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
