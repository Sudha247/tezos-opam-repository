# runtime dependencies
#
# This image includes
# - runtime dependencies (libraries linked at load time of the process)
#
# This image is intended for
# - distributing the tezos binaries in
# - building the runtime-prebuild-dependencies, runtime-build-dependencies, and runtime-build-test-dependencies images


ARG BUILD_IMAGE

# hadolint ignore=DL3006
FROM ${BUILD_IMAGE}

# Metadata
LABEL org.label-schema.vendor="Nomadic Labs" \
      org.label-schema.url="https://www.nomadic-labs.com" \
      org.label-schema.name="Tezos" \
      org.label-schema.description="Tezos node" \
      org.label-schema.vcs-url=https://gitlab.com/tezos/tezos \
      org.label-schema.docker.schema-version="1.0" \
      distro.style="apk" \
      distro="alpine" \
      distro.long="alpine-$alpine_version" \
      operatingsystem="linux"

USER root

# hadolint ignore=DL3018
RUN apk --no-cache add libev gmp sudo hidapi libffi gcc libc-dev

COPY zcash-params /usr/share/zcash-params

RUN adduser -S tezos && \
    echo 'tezos ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/tezos && \
    chmod 440 /etc/sudoers.d/tezos && \
    chown root:root /etc/sudoers.d/tezos && \
    sed -i.bak 's/^Defaults.*requiretty//g' /etc/sudoers && \
    mkdir -p /var/run/tezos/node /var/run/tezos/client && \
    chown -R tezos /var/run/tezos

USER tezos
ENV USER=tezos

WORKDIR /home/tezos
