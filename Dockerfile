FROM debian:unstable-slim

ARG CALIBRE_VERSION

# Otherwize you will get an interactive setup session
ENV DEBIAN_FRONTEND=noninteractive

RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
 && apt-get install -y \
        ca-certificates \
        libegl1 \
        libfontconfig1 \
        libglx0 \
        libopengl0 \
        libxcb-cursor0 \
        libxcb-icccm4 \
        libxcb-image0 \
        libxcb-keysyms1 \
        libxcb-render-util0 \
        libxcb-xinerama0 \
        libxkbcommon-x11-0 \
        locales \
        python3 \
        python3-pip \
        qt6ct \
        vim-tiny \
        wget \
        xz-utils \
 && apt-get install -y --no-install-recommends \
        dillo \
        fonts-noto-cjk \
        kde-cli-tools \
        libnss3-dev \
        libxcomposite-dev \
        libxdamage-dev \
        libxi6 \
        libxkbfile-dev \
        libxrandr-dev \
        libxrender1 \
        libxtst6 \
        xdg-desktop-portal-dev \
        xdg-desktop-portal-xapp \
        xdg-utils \
        xfonts-intl-arabic \
        xfonts-intl-asian \
        xfonts-intl-chinese \
        xfonts-intl-european \
        xfonts-intl-japanese \
        xfonts-intl-phonetic \
        xpdf \
 && apt-get autoclean \
 && apt-get clean
 
RUN mkdir -vp /usr/share/desktop-directories/
    # register for pdf
RUN xdg-mime default xpdf.desktop application/pdf

# set the locale to en_US.UTF-8
RUN locale-gen && \
    /usr/sbin/update-locale LC_ALL=C.utf8

WORKDIR /tmp/build/
RUN --mount=type=cache,target=/tmp/build/,sharing=locked \
     wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sh /dev/stdin version=${CALIBRE_VERSION}

COPY calibre_backups/calibre_backup.sh /usr/local/bin/calibre_backup.sh

WORKDIR /opt/Books

# Set `calibre` as the entrypoint for the image
# ENTRYPOINT ["calibre"]

# Mandatory Labels
LABEL org.opencontainers.image.vendor=slash5toaster \
      org.opencontainers.image.authors=slash5toaster@gmail.com \
      org.opencontainers.image.ref.name=calibre \
      org.opencontainers.image.version=7.24.0

#### End of File, if this is missing the file has been truncated
