#!/usr/bin/env bash

set -eu


dependencies() {
    go get github.com/Masterminds/glide
    glide install

    GO_PROJECT_HOME="/home/ubuntu/.go_workspace/src/$(glide name)"

    mkdir -p "$GO_PROJECT_HOME"
    rsync -a --delete . "$GO_PROJECT_HOME"
}

build() {
    go build
}

test() {
    go test $(glide novendor)
    tests/run.sh
}

release() {
    mkdir out

    GOARCH="amd64"

    for GOOS in linux darwin windows; do
        echo "Building ${GOOS}_${GOARCH}"

        DIR="out/${CIRCLE_PROJECT_REPONAME}_${GOOS}_${GOARCH}"
        OUT="${DIR}/${CIRCLE_PROJECT_REPONAME}"
        if [ "$GOOS" = "windows" ]; then
            OUT="${OUT}.exe"
        fi

        GOOS="$GOOS" GOARCH="$GOARCH" go build -o "$OUT"

        tar -czf "$DIR.tar.gz" "$DIR"
        rm -rf "$DIR"
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
