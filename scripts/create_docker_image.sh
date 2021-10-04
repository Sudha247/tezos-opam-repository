#! /bin/sh

set -e

script_dir="$(cd "$(dirname "$0")" && echo "$(pwd -P)/")"
repo_dir="$(dirname "$script_dir")"
cd "$repo_dir"

image_name="${1:-tezos_build_deps}"
image_version="${2:-latest}"
arch="${3:?}"

## may pull cache...
docker pull "registry.gitlab.com/tezos/opam-repository:master" || true > /dev/null 2>&1

"$script_dir"/create_docker_image.runtime-dependencies.sh \
             "$image_name" \
             "runtime-dependencies--$image_version"

"$script_dir"/create_docker_image.runtime-prebuild-dependencies.sh \
             "$image_name" \
             "runtime-prebuild-dependencies--$image_version" \
             "$image_name:runtime-dependencies--$image_version" \
             "$arch"

"$script_dir"/create_docker_image.runtime-build-dependencies.sh \
             "$image_name" \
             "runtime-build-dependencies--$image_version" \
             "$image_name:runtime-prebuild-dependencies--$image_version"

"$script_dir"/create_docker_image.runtime-build-test-dependencies.sh \
             "$image_name" \
             "runtime-build-test-dependencies--$image_version" \
             "$image_name:runtime-build-dependencies--$image_version"

