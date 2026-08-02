#!/bin/sh

set -eu

if [ "$#" -ne 4 ]; then
    echo "usage: $0 REPOSITORY PRIVATE_KEY SIGNED_BY ARCH" >&2
    exit 2
fi

repository=$1
private_key=$2
signed_by=$3
architecture=$4

umask 022
mkdir -p "$repository"

make_repository_readable() {
    chmod -R a+rX "$repository"
}
trap make_repository_readable EXIT HUP INT TERM

if [ ! -r "$private_key" ]; then
    echo "repository signing key is not readable: $private_key" >&2
    exit 1
fi

exec 9>"$repository/.publish.lock"
flock 9

set -- "$repository"/*.xbps
if [ ! -e "$1" ]; then
    echo "repository contains no XBPS packages: $repository" >&2
    exit 1
fi

XBPS_ARCH=invalid XBPS_TARGET_ARCH="$architecture" \
    xbps-rindex --add --force "$@"
XBPS_ARCH=invalid XBPS_TARGET_ARCH="$architecture" \
    xbps-rindex --privkey "$private_key" --sign --signedby "$signed_by" \
    "$repository"
XBPS_ARCH=invalid XBPS_TARGET_ARCH="$architecture" \
    xbps-rindex --privkey "$private_key" --sign-pkg "$@"
