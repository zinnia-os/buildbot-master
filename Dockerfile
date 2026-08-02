FROM buildbot/buildbot-master:master

ARG XBPS_STATIC_VERSION=0.60.4_1
ARG XBPS_STATIC_SHA256=603b3c55e9cabd5af79b461b929b14e1556a443c97b5714d188681c2172d9e28

ADD https://repo-default.voidlinux.org/static/xbps-static-static-${XBPS_STATIC_VERSION}.x86_64-musl.tar.xz /tmp/xbps-static.tar.xz

RUN echo "${XBPS_STATIC_SHA256}  /tmp/xbps-static.tar.xz" | sha256sum -c - \
    && mkdir /tmp/xbps-static \
    && tar -xJf /tmp/xbps-static.tar.xz -C /tmp/xbps-static ./usr/bin/xbps-rindex.static \
    && install -m 0755 /tmp/xbps-static/usr/bin/xbps-rindex.static /usr/local/bin/xbps-rindex \
    && rm -rf /tmp/xbps-static /tmp/xbps-static.tar.xz

COPY --chmod=0755 publish-xbps-repository.sh /usr/local/bin/publish-xbps-repository
