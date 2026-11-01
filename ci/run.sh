#!/usr/bin/env bash
# The whole pipeline for one commit, in a Debian container (as root): install the build
# dependencies, build the .deb and the tarball, build the unfixed control, run the tests as
# a normal user. The release workflow runs exactly this; so can a local podman run.
#
# Usage: ci/run.sh <screen repo> <commit> <control commit> <version tag> <out dir>
set -euo pipefail
here=$(dirname "$(realpath "$0")")
repo=$1 commit=$2 control=$3 tag=$4 out=$(realpath -m "$5")

export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q --no-install-recommends build-essential debhelper dpkg-dev \
	libcrypt-dev libncurses-dev libpam0g-dev texinfo autoconf automake git python3 \
	ca-certificates > /dev/null
git config --global --add safe.directory '*'

"$here/build.sh" "$repo" "$commit" "$tag" "$out"
"$here/build-control.sh" "$repo" "$control" "$out/control/screen"

id tester > /dev/null 2>&1 || useradd -m tester
chmod -R a+rX "$out" "$here"
runuser -u tester -- "$here/test.sh" "$out/screen.bin" "$out/control/screen" 2>&1 | tee "$out/test.log"
