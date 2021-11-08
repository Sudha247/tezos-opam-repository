# runtime + prebuild dependencies
#
# This image includes
# - runtime dependencies (libraries linked at load time of the process)
# - non-opam build-dependencies (rust dependencies)
# - cache for opam build-dependencies
#
# This image is intended for
# - testing the buildability of tezos opam packages
# - building the runtime-build-dependencies and runtime-build-test-dependencies image

ARG BUILD_IMAGE

# hadolint ignore=DL3006
FROM ${BUILD_IMAGE}

ARG OCAML_VERSION
ARG RUST_VERSION

# use alpine /bin/ash and set pipefail.
# see https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

# Adds static packages of hidapi and libusb built by `scripts/libusb-hidapi.sh`
# in `runtime-prebuild-dependencies` image.
WORKDIR /
COPY _docker_build/keys /etc/apk/keys/
COPY _docker_build/*/*.apk ./

USER root
# FIXME: ? it is true that without version, the image is not reproducible.
# hadolint ignore=DL3018
RUN apk --no-cache add \
        build-base bash perl xz m4 git curl tar rsync patch jq \
        ncurses-dev opam openssl-dev cargo \
        hidapi-0.9.0-r2.apk \
        hidapi-dev-0.9.0-r2.apk \
        libusb-1.0.24-r2.apk \
        libusb-dev-1.0.24-r2.apk

# Check versions of other interpreters/compilers
RUN test "$(rustc --version | cut -d' ' -f2)" = ${RUST_VERSION}

USER tezos
WORKDIR /home/tezos

RUN mkdir ~/.ssh && \
    chmod 700 ~/.ssh && \
    git config --global user.email "ci@tezos.com" && \
    git config --global user.name "Tezos CI"

COPY --chown=tezos:nogroup repo opam-repository/
COPY --chown=tezos:nogroup packages opam-repository/packages
COPY --chown=tezos:nogroup \
      packages/ocaml \
      packages/ocaml-config \
      packages/ocaml-base-compiler \
      packages/ocaml-options-vanilla \
      packages/base-bigarray \
      packages/base-bytes \
      packages/base-unix \
      packages/base-threads \
      opam-repository/packages/


WORKDIR /home/tezos/opam-repository


# hadolint ignore=SC2046
RUN opam init --disable-sandboxing --no-setup --yes \
              --compiler ocaml-base-compiler.${OCAML_VERSION} \
              tezos /home/tezos/opam-repository && \
    opam admin cache && \
    opam update && \
    opam install opam-depext && \
    opam depext --update --yes $(opam list --all --short | grep -v ocaml-option-) && \
    opam clean

ENTRYPOINT [ "opam", "exec", "--" ]
CMD [ "/bin/sh" ]
