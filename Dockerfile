FROM --platform=$BUILDPLATFORM alpine:3.23 AS base-build

ARG CALIBRE_VERSION

RUN --mount=type=cache,target=/etc/apk/cache,sharing=locked \
    --mount=type=cache,target=/var/cache/apk,sharing=locked \
    apk update \
 && apk add \
        bubblewrap \
        ca-certificates \
        dillo \
        kde-cli-tools \
        gcompat \
        libxcomposite-dev \
        libxdamage-dev \
        libxkbfile-dev \
        libxrandr-dev \
        python3 \
        vim \
        wget \
        xdg-desktop-portal-dev \
        xdg-desktop-portal-xapp \
        xdg-utils \
        xpdf \
 && apk cache clean

FROM base-build
RUN mkdir -vp /usr/share/desktop-directories/

WORKDIR /tmp/build/
RUN --mount=type=cache,target=/tmp/build/,sharing=locked \
     wget -c -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sh /dev/stdin version=${CALIBRE_VERSION} \
     || exit 1

# register for pdf
RUN xdg-mime default calibre-ebook-viewer.desktop application/pdf

# test that calibre got installed properly
RUN type calibre || exit 1 \
 && calibre --version

COPY calibre_backups/calibre_backup.sh /usr/local/bin/calibre_backup.sh

WORKDIR /opt/Books

# Set `calibre` as the entrypoint for the image
# ENTRYPOINT ["calibre"]

# Mandatory Labels
LABEL org.opencontainers.image.vendor=slash5toaster \
      org.opencontainers.image.authors=slash5toaster@gmail.com \
      org.opencontainers.image.ref.name=calibre \
      org.opencontainers.image.version=9.4.0

#### End of File, if this is missing the file has been truncated