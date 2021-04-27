#!/usr/bin/env bash

set -eu


dependencies() {
    go mod download
}

build() {
    go build
}

test() {
    go test ./...
    tests/run.sh
}

release() {
    mkdir out

    GOARCH="amd64"

    for GOOS in linux darwin windows; do
        echo "Building ${GOOS}_${GOARCH}"

        DIR="${CIRCLE_PROJECT_REPONAME}_${GOOS}_${GOARCH}"
        OUT="out/${DIR}/${CIRCLE_PROJECT_REPONAME}"
        if [ "${GOOS}" = "windows" ]; then
            OUT="${OUT}.exe"
        fi

        GOOS="${GOOS}" GOARCH="${GOARCH}" go build -o "${OUT}"

        cd out
        tar -czf "${DIR}.tar.gz" "${DIR}"
        rm -rf "${DIR}"
        cd ..
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
