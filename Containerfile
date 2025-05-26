FROM debian:bookworm-slim AS wget-build
ARG TLS_TYPE=openssl
ENV LC_ALL=C
ENV CFLAGS="-O2 -pipe -flto -fstack-protector-strong -fstack-clash-protection -fcf-protection -Wl,-z,defs -Wl,-z,now -Wl,-z,relro"
ENV ZSTD_VER=1.5.7
ENV CARES_VER=1.34.5
RUN set -eux \
 && apt-get -y update \
 && apt-get -y --no-install-recommends upgrade \
 && apt-get -y --no-install-recommends install \
 libssl-dev gnutls-dev build-essential git bzip2 \
 bash rsync gcc zlib1g-dev autoconf autoconf-archive \
 flex make automake gettext libidn-dev autopoint \
 texinfo gperf ca-certificates wget pkg-config \
 libpsl-dev libidn2-dev libluajit-5.1-dev libgpgme-dev libpcre2-dev
RUN cd /tmp \
 && wget "https://github.com/facebook/zstd/releases/download/v${ZSTD_VER}/zstd-${ZSTD_VER}.tar.gz" \
 && tar xf zstd-${ZSTD_VER}.tar.gz \
 && cd zstd-${ZSTD_VER} \
 && make \
 && make install
RUN cd /tmp \
 && wget "https://github.com/c-ares/c-ares/releases/download/v${CARES_VER}/c-ares-${CARES_VER}.tar.gz" \
 && tar xf c-ares-${CARES_VER}.tar.gz \
 && cd c-ares-${CARES_VER} \
 && ./configure \
 && make \
 && make install
RUN ldconfig
COPY . /tmp/wget
RUN cd /tmp/wget \
 && ./bootstrap \
 && ./configure --with-ssl="${TLS_TYPE}" --with-cares --disable-nls \
 && make -j$(nproc) \
 && src/wget --help | grep -iE "gnu|warc|lua|dns|host|resolv"
FROM scratch
COPY --from=wget-build /tmp/wget/src/wget /wget
COPY --from=wget-build /usr/local/lib /usr/local/lib
