# runtime + build dependencies
#
# This image includes
# - runtime dependencies (libraries linked at load time of the process)
# - non-opam build-dependencies (rust dependencies)
# - cache for opam build-dependencies
# - opam build-dependencies
#
# This image is intended for
# - building tezos from source
# - building the runtime-build-test-dependencies image


ARG BUILD_IMAGE

# hadolint ignore=DL3006
FROM ${BUILD_IMAGE}

# use alpine /bin/ash and set pipefail.
# see https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

USER tezos
WORKDIR /home/tezos

# hadolint ignore=SC2046
RUN opam depext --update --yes $(opam list --all --short | grep -v ocaml-option-) && \
    opam install --yes $(opam list --all --short | grep -v ocaml-option-)
