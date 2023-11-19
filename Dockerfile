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
        libfontconfig \
        libfontconfig1 \
        libglx0 \
        libopengl0 \
        libxcb-icccm4 \
        libxcb-image0 \
        libxcb-keysyms1 \
        libxcb-render-util0 \
        libxcb-xinerama0 \
        libxkbcommon-x11-0 \
        python3 \
        python3-pip \
        qt6ct \
        wget \
        xz-utils \
 && apt-get install -y --no-install-recommends \
        fonts-noto-cjk \
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
 && apt-get autoclean \
 && apt-get clean

 RUN mkdir -vp /usr/share/desktop-directories/

RUN wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sh /dev/stdin version=${CALIBRE_VERSION}

COPY calibre_backups/calibre_backup.sh /usr/local/bin/calibre_backup.sh

# Set `calibre` as the entrypoint for the image
# ENTRYPOINT ["calibre"]

# Mandatory Labels
LABEL project=slash5toaster
LABEL org.opencontainers.image.authors="slash5toaster@gmail.com"
LABEL name=calibre
LABEL version=7.0.0
LABEL generate_apptainer_image=true
LABEL production=true

#### End of File, if this is missing the file has been truncated