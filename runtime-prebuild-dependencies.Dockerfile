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

FROM ${BUILD_IMAGE}

ARG OCAML_VERSION
ARG RUST_VERSION

USER root
RUN apk --no-cache add \
        build-base bash perl xz m4 git curl tar rsync patch jq \
        ncurses-dev gmp-dev libev-dev opam \
        openssl-dev \
        hidapi-dev libffi-dev cargo

# Check versions of other interpreters/compilers
RUN test $(rustc --version | cut -d' ' -f2) = ${RUST_VERSION}

### Begin Rust dependencies compilation
COPY rust rust
RUN RUSTFLAGS='-C target-feature=-crt-static' cargo build --release --manifest-path ./rust/Cargo.toml

# librustzcash
RUN cp rust/target/release/librustzcash.a /usr/lib/
RUN cp rust/librustzcash/include/librustzcash.h /usr/include/

# rustc-bls12-381
RUN cp rust/rustc-bls12-381/include/rustc_bls12_381.h /usr/include/
RUN cp rust/target/release/librustc_bls12_381.a /usr/lib/

RUN rm -rf rust
### End Rust dependencies compilation

USER tezos
WORKDIR /home/tezos

COPY --chown=tezos:nogroup repo opam-repository/

COPY --chown=tezos:nogroup \
      packages/ocaml \
      packages/ocaml-config \
      packages/ocaml-base-compiler \
      packages/base-bigarray \
      packages/base-bytes \
      packages/base-unix \
      packages/base-threads \
      opam-repository/packages/

RUN cd opam-repository && opam admin cache

RUN mkdir ~/.ssh && \
    chmod 700 ~/.ssh && \
    git config --global user.email "ci@tezos.com" && \
    git config --global user.name "Tezos CI" && \
    opam init --disable-sandboxing --no-setup --yes \
              --compiler ocaml-base-compiler.${OCAML_VERSION} \
              tezos /home/tezos/opam-repository

COPY --chown=tezos:nogroup packages opam-repository/packages

RUN cd opam-repository && \
    opam admin cache && \
    opam update && \
    opam install opam-depext && \
    opam clean

ENTRYPOINT [ "opam", "exec", "--" ]
CMD [ "/bin/sh" ]