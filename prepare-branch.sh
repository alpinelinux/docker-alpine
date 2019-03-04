#!/bin/sh -e


prepare() {
	local branch="$1"
	local dir=$(mktemp -d /tmp/docker-brew-alpine-XXXXXX)
	docker build -t docker-brew-alpine-fetch .
	docker run --user $(id -u) --rm -it -v $dir:/out docker-brew-alpine-fetch $branch /out
	echo "=> Verifying checksums"
	( cd $dir && sha512sum -c checksums.sha512)
	echo "=> temp dir: $dir"
	echo "=> To create git branch run:"
	echo ""
	echo "  $0 branch $branch $dir"
	echo ""
}

branch() {
	local branch="$1"
	local dir="$2"
	local version=$(cat $dir/VERSION)
	echo "=> Creating branch for release $version from $dir"

	if [ -n "$(git status --porcelain)" ]; then
		echo "=> git status is not clean. Aborting"
		git status --porcelain
		exit 1
	fi

	git checkout master
	git branch -D "$branch" || true
	git checkout --orphan "$branch"
	git rm --cached -r .
	rm -fr ./*
	mv "$dir"/* .
	rmdir "$dir"
	git add *
	git commit -m "Update Alpine $branch - $version"

	echo "=> Branch created:"
	git log
	echo ""
	echo "=> To upload release do:"
	echo ""
	echo "  git push -f origin $branch"
	echo ""
}

help() {
	cat <<EOF
Usage: $0 COMMAND [OPTS]

Commands:

 prepare [BRANCH]   - fetch release latest minirootfs to a temp directory and
                      create Dockerfiles

 branch BRANCH DIR  - update git branch with previously prepared temp
                      directory

EOF
}

cmd=$1
shift

branch=${1:-edge}
dir="$2"

case "$cmd" in
	prepare) prepare "$branch";;
	branch)  branch "$branch" "$dir";;
	*) help $0;;
esac



