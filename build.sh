#!/bin/sh

set -eu


cd cert-chain-resolver

go build -o ../out/cert-chain-resolver
