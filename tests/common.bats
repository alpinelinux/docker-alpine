#!/usr/bin/env bats

: ${BRANCH:=edge}
VER=${BRANCH#v}
TAG=${VER}-test

setup() {
  docker history alpine:$TAG >/dev/null 2>&1
}

@test "version is correct $VER" {
  case $BRANCH in
  edge) skip;;
  esac
  run docker run alpine:$TAG sh -c '. ./etc/os-release; echo ${VERSION_ID%.*}'
  [ $status -eq 0 ]
  [ "${lines[0]}" = "$VER" ]
}

@test "package installs cleanly" {
  run docker run alpine:$TAG apk add --no-cache bash
  [ $status -eq 0 ]
}

@test "timezone" {
  run docker run alpine:$TAG date +%Z
  [ $status -eq 0 ]
  [ "$output" = "UTC" ]
}

@test "repository list is correct" {
  run docker run alpine:$TAG cat /etc/apk/repositories
  [ $status -eq 0 ]
  [ "${lines[0]}" = "http://dl-cdn.alpinelinux.org/alpine/$BRANCH/main" ]
  [ "${lines[1]}" = "http://dl-cdn.alpinelinux.org/alpine/$BRANCH/community" ]
  [ "${lines[2]}" = "" ]
}

@test "cache is empty" {
  run docker run alpine:$TAG sh -c "ls -1 /var/cache/apk | wc -l"
  [ $status -eq 0 ]
  [ "$output" = "0" ]
}

@test "root password is disabled with default su" {
  run docker run --user nobody alpine:$TAG su
  [ $status -eq 1 ]
}

@test "root login is disabled" {
  run docker run alpine:$TAG awk -F: '$1=="root"{print $2}' /etc/shadow
  [ $status -eq 0 ]
  [ "$output" = "!" ]
}

@test "/dev/null should be missing" {
  run sh -c "docker export $(docker create alpine:$TAG) | tar -t dev/null"
  [ "$output" != "dev/null" ]
  [ $status -ne 0 ]
}

