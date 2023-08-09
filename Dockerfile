FROM debian:unstable-slim

# Update OS to apply latest vulnerability fix
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y \
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
        qt6ct \
        python3 \
        wget \
        xz-utils \
 && apt-get autoclean \
 && apt-get clean

# for netskope clients locally
COPY usr/local/share/ca-certificates/netskoperoot.crt /usr/local/share/ca-certificates/netskoperoot.crt
RUN /usr/sbin/update-ca-certificates

RUN wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sh /dev/stdin

# Set `calibre` as the entrypoint for the image
# ENTRYPOINT ["calibre"]

# Mandatory Labels
LABEL project=slash5toaster
LABEL org.opencontainers.image.authors="slash5toaster@gmail.com"
LABEL name=calibre
LABEL version=6.24.0
LABEL generate_apptainer_image=true
LABEL production=false

#### End of File, if this is missing the file has been truncated