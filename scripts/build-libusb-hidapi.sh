#!/bin/sh

# This script downloads, modify and build libusb and hidapi.
# This script will no longer be needed once the upstream patches
# (which add static binaries) are available in Alpine.
# Those patches are already merged and will be available in the
# next version of Alpine.

# fail in case of error
set -e

script_dir="$(cd "$(dirname "$0")" && echo "$(pwd -P)/")"
repo_dir="$(dirname "$script_dir")"

cd "$repo_dir"

# avoid shellcheck error
alpine_version=

#shellcheck disable=SC1090
. "$script_dir/version.sh"

# cleanup in case of error
cleanup () {
    set +e
    rm -rf "$tmp_dir"
    if [ -n "$container" ]; then docker rm "$container"; fi
    docker rmi "$tmp_image" || true

}
trap cleanup EXIT INT

# these are the script arguments
library="${1:?}"
arch="${2:?}"

# if build_dir is not defined _docker_build is used as default.
build_dir="${build_dir:-_docker_build}"

# tmp_image is the name of the temporary docker image that we use to build
# the alpine package
tmp_image="tezos_build_deps/$library-docker_image"
tmp_dir=$(mktemp -dt "tezos.$library.XXXXXXXX")

# since we want to recreate the same packages as in the distribution
# we also have to download the associated patches that are referred in
# package description.

# the only different is to add `--enable-static` to the build command.

if [ "$library" = "libusb" ]; then

  # download package description
  wget --continue \
    "https://git.alpinelinux.org/aports/plain/main/$library/APKBUILD?h=$alpine_version-stable" \
    -O "${tmp_dir}/APKBUILD.$library"

  # download associated patch 1
  wget --continue \
    "https://git.alpinelinux.org/aports/plain/main/libusb/f38f09da98acc63966b65b72029b1f7f81166bef.patch?h=$alpine_version-stable" \
    -O "${tmp_dir}/f38f09da98acc63966b65b72029b1f7f81166bef.patch"

  # download associated patch 2
  wget --continue \
    "https://git.alpinelinux.org/aports/plain/main/libusb/f6d2cb561402c3b6d3627c0eb89e009b503d9067.patch?h=$alpine_version-stable" \
    -O "${tmp_dir}/f6d2cb561402c3b6d3627c0eb89e009b503d9067.patch"

  #shellcheck disable=SC2016
  sed 's/--disable-static/--enable-static/' \
    "${tmp_dir}/APKBUILD.$library" > "${tmp_dir}/APKBUILD"

fi

if [ "$library" = "hidapi" ]; then
#shellcheck disable=SC2154
#alpine-version is declared in version.sh

  # download package description
  wget --continue \
    "https://git.alpinelinux.org/aports/plain/community/hidapi/APKBUILD?h=$alpine_version-stable" \
    -O "${tmp_dir}/APKBUILD.$library"

  # download associated patch 1
  wget --continue \
    "https://git.alpinelinux.org/aports/plain/community/hidapi/autoconf-270.patch?h=$alpine_version-stable" \
    -O "${tmp_dir}/autoconf-270.patch"

  #shellcheck disable=SC2016
  sed 's/--disable-static/--enable-static/' \
    "${tmp_dir}/APKBUILD.$library" > "${tmp_dir}/APKBUILD"

fi

# we use a docker to compile the alpine package
# alpinelinux/docker-abuild contains the entire compilation toolchain.
cat << EOF > "$tmp_dir/Dockerfile"
FROM alpinelinux/docker-abuild
ENV PACKAGER "Tezos <ci@tezos.com>"
WORKDIR /home/builder/
RUN abuild-keygen -a -i
COPY * ./
RUN abuild -r
EOF

printf "\n### Building %s...\n" "$library"

docker build \
       --cache-from "$tmp_image" \
       -t "$tmp_image" \
       "$tmp_dir"

mkdir -p "$build_dir"

# we copy the result of the compilation outside of the container
container=$(docker create "$tmp_image")
docker cp -L "$container:/etc/apk/keys" "$build_dir"
docker cp -L "$container:/home/builder/packages/home/$arch/" "$build_dir"

cleanup
