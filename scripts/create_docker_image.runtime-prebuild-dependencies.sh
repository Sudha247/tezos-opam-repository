#! /bin/sh

set -e

script_dir="$(cd "$(dirname "$0")" && echo "$(pwd -P)/")"
repo_dir="$(dirname "$script_dir")"
cd "$repo_dir"

. "$script_dir"/version.sh

image_name="${1:-tezos_runtime-prebuild-dependencies}"
image_version="${2:-latest}"
runtime_dependencies_image="${3:?}"
arch="${4:?}"

"$script_dir"/build-libusb-hidapi.sh libusb "${arch}"
"$script_dir"/build-libusb-hidapi.sh hidapi "${arch}"

echo
echo "### Building runtime-prebuild-dependencies image $arch"
echo "### (includes: non-opam deps, cache of not-installed opam deps)"
echo

docker build \
       -f runtime-prebuild-dependencies.Dockerfile \
       --build-arg BUILD_IMAGE="${runtime_dependencies_image}" \
       --build-arg OCAML_VERSION=${ocaml_version} \
       --build-arg RUST_VERSION=${rust_version} \
       -t "$image_name:$image_version" \
       $repo_dir

