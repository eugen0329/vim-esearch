FROM alpine:3.10

RUN set -eux; \
    apk add --no-cache --update \
    # For BATS itself
      bash git \
    # bats --pretty support
      ncurses \
    # Tests
      gcc make wget tar musl-dev; \
    # we don't use bats/bats to be able to control base OS version
    git clone https://github.com/bats-core/bats-core /opt/bats/; \
    ln -s /opt/bats/bin/bats /usr/sbin/bats; \
    rm -rfv /opt/bats/.git;

WORKDIR /provision/test

ENTRYPOINT ["/bin/bash"]
