#!/bin/sh -e

branch=${1:-edge}

dir=$(mktemp -d /tmp/docker-brew-alpine-XXXXXX)
docker build -t docker-brew-alpine-fetch .
docker run --user $(id -u) --rm -it -v $dir:/out docker-brew-alpine-fetch $branch /out

(
	cd $dir
	sha512sum -c checksums.sha512

	for img in */*.tar.gz; do
		arch=${img%%/*}
		rootfs=${img##*/}
		cat > $arch/Dockerfile <<-EOF
			FROM scratch
			ADD ${rootfs} /
			CMD ["/bin/sh"]
		EOF
	done
)

echo "COMPLETED"
echo "=> Temp dir: $dir"

