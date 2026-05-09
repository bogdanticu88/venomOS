FROM archlinux:latest

RUN pacman -Sy --noconfirm \
    archiso \
    git \
    curl \
    wget \
    rsync \
    squashfs-tools \
    dosfstools \
    mtools \
    libisoburn \
    efibootmgr \
    grub \
    && pacman -Scc --noconfirm

# Add BlackArch repo
RUN curl -O https://blackarch.org/strap.sh && \
    chmod +x strap.sh && \
    echo "y" | bash strap.sh || true && \
    rm -f strap.sh

WORKDIR /venomOS/build

CMD ["/bin/bash", "build.sh"]
