#!/bin/sh -e

branch=${1:-edge}

dir=$(mktemp -d /tmp/docker-brew-alpine-XXXXXX)
docker build -t docker-brew-alpine-fetch .
docker run --user $(id -u) --rm -it -v $dir:/out docker-brew-alpine-fetch $branch /out
( cd $dir && sha512sum -c checksums.sha512)

echo "COMPLETED"
echo "=> Temp dir: $dir"

