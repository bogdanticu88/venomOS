FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    live-build \
    debootstrap \
    squashfs-tools \
    xorriso \
    isolinux \
    syslinux-common \
    grub-pc-bin \
    grub-efi-amd64-bin \
    grub-efi-amd64-signed \
    shim-signed \
    mtools \
    dosfstools \
    curl \
    wget \
    git \
    rsync \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /venomOS/build

CMD ["/bin/bash", "build.sh"]
