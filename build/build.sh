#!/bin/bash
# Runs inside the Docker build container.
set -e

echo ""
echo "[*] VenomOS Build System — Stage ${VENOM_STAGE:-1}"
echo ""

BUILD_SRC="/venomOS/build"
BUILD_DIR="/tmp/venomos-build"

echo "[*] Staging build config to $BUILD_DIR (container filesystem)..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cp -a "$BUILD_SRC/auto" "$BUILD_DIR/"
rsync -a --exclude='includes.chroot/opt/venomOS/tools' "$BUILD_SRC/config/" "$BUILD_DIR/config/"

cd "$BUILD_DIR"
echo "[*] Working directory: $(pwd)"
echo ""

# Replace lb chroot_resolv with a Docker-aware version.
# Docker bind-mounts /etc/resolv.conf into the container read-only; lb's default
# script tries to mv/cp/chmod it and fails with EPERM on every subsequent call.
# Our replacement: unmount any bind before touching the file, and make all
# operations non-fatal so lb continues even if the file stays bind-mounted.
RESOLV_SCRIPT="/usr/lib/live/build/chroot_resolv"
if [ -f "$RESOLV_SCRIPT" ]; then
    echo "[*] Replacing lb chroot_resolv with Docker-safe version..."
    cat > "$RESOLV_SCRIPT" << 'RESOLV_EOF'
#!/bin/sh
# Docker-safe chroot_resolv.
# A postinst (systemd-resolved/resolvconf) bind-mounts over chroot/etc/resolv.conf
# during the package install phase; subsequent lb calls cannot mv/cp/chmod it.
# Fix: drain any stacked bind mounts with umount -l before touching the file.
set +e
ACTION="${1:-install}"
STAGE=".build/chroot_resolv"
mkdir -p .build

case "$ACTION" in
    install)
        while mountpoint -q chroot/etc/resolv.conf 2>/dev/null; do
            umount -l chroot/etc/resolv.conf 2>/dev/null || break
        done
        if [ -e chroot/etc/resolv.conf ] || [ -L chroot/etc/resolv.conf ]; then
            mv -f chroot/etc/resolv.conf chroot/etc/resolv.conf.orig 2>/dev/null \
                || rm -f chroot/etc/resolv.conf 2>/dev/null
        fi
        if [ -f /etc/resolv.conf ]; then
            cp /etc/resolv.conf chroot/etc/resolv.conf 2>/dev/null
        fi
        if [ ! -s chroot/etc/resolv.conf ]; then
            printf 'nameserver 8.8.8.8\nnameserver 1.1.1.1\n' > chroot/etc/resolv.conf 2>/dev/null
        fi
        chmod 0644 chroot/etc/resolv.conf 2>/dev/null
        touch "$STAGE"
        ;;
    remove)
        while mountpoint -q chroot/etc/resolv.conf 2>/dev/null; do
            umount -l chroot/etc/resolv.conf 2>/dev/null || break
        done
        rm -f chroot/etc/resolv.conf 2>/dev/null
        if [ -e chroot/etc/resolv.conf.orig ] || [ -L chroot/etc/resolv.conf.orig ]; then
            mv -f chroot/etc/resolv.conf.orig chroot/etc/resolv.conf 2>/dev/null
        fi
        rm -f "$STAGE"
        ;;
esac
exit 0
RESOLV_EOF
    chmod +x "$RESOLV_SCRIPT"
    echo "[*] Replacement applied."
fi

# Patch lb binary_grub-efi to skip 32-bit EFI on amd64.
# Trixie's amd64 archive doesn't ship grub-efi-ia32-bin, so the default lb
# script fails on `Check_package` and on `gen_efi_boot_img "i386-efi"` (which
# is conditionally invoked when a signed amd64 grub is present). For modern
# 64-bit-only EFI we just need to skip both.
EFI_SCRIPT="/usr/lib/live/build/binary_grub-efi"
if [ -f "$EFI_SCRIPT" ]; then
    echo "[*] Patching lb binary_grub-efi to skip 32-bit EFI..."
    sed -i '/grub-efi-ia32-bin/d' "$EFI_SCRIPT"
    sed -i 's|gen_efi_boot_img "i386-efi" "ia32" "debian-live/i386"|: # 32-bit EFI disabled (no grub-efi-ia32-bin in trixie)|g' "$EFI_SCRIPT"
    echo "[*] Patch applied."
fi

echo "[*] Cleaning previous build artifacts..."
lb clean --purge 2>/dev/null || true

echo "[*] Initializing live-build configuration..."
bash auto/config

echo "[*] Building ISO — this will take 20-40 minutes..."
mkdir -p /output
set +e
lb build 2>&1 | tee /tmp/lb-build.log
LB_EXIT=${PIPESTATUS[0]}
set -e

cp /tmp/lb-build.log /output/build.log 2>/dev/null || true

# Fallback: if lb build still failed on resolv.conf, run lb binary directly.
# The chroot is fully built at this point — lb binary just needs to squash it.
if [ $LB_EXIT -ne 0 ]; then
    if tail -15 /tmp/lb-build.log | grep -q "resolv.conf"; then
        echo "[*] Resolv.conf issue persists — running lb binary directly..."
        mkdir -p "$BUILD_DIR/.build"
        touch "$BUILD_DIR/.build/bootstrap"
        touch "$BUILD_DIR/.build/chroot"
        set +e
        lb binary 2>&1 | tee -a /tmp/lb-build.log
        LB_EXIT=${PIPESTATUS[0]}
        set -e
        cp /tmp/lb-build.log /output/build.log 2>/dev/null || true
    else
        echo "[-] Build failed — unrecognized error."
        tail -20 /tmp/lb-build.log
        exit 1
    fi
fi

if [ $LB_EXIT -ne 0 ]; then
    echo "[-] Binary stage failed."
    tail -20 /tmp/lb-build.log
    exit 1
fi

if ls "$BUILD_DIR"/*.iso 1>/dev/null 2>&1; then
    ISO=$(ls "$BUILD_DIR"/*.iso | head -1)
    ISONAME=$(basename "$ISO")
    SIZE=$(du -h "$ISO" | cut -f1)
    echo ""
    echo "[+] ============================="
    echo "[+] Build successful!"
    echo "[+] ISO: $ISONAME ($SIZE)"
    echo "[+] ============================="
    # Use dd with a fixed 4 MiB buffer instead of cp. cp uses sendfile/splice
    # which can ENOMEM when copying multi-gigabyte files across the
    # container -> WSL -> NTFS -> OneDrive boundary (kernel writeback can't
    # drain fast enough and the page cache fills). dd bs=4M conv=fsync
    # writes in small chunks and forces a sync at the end.
    echo "[*] Copying ISO to /output (dd, 4 MiB chunks)..."
    dd if="$ISO" of="/output/$ISONAME" bs=4M conv=fsync status=none
    echo "[+] ISO copied to /output/$ISONAME"
else
    echo "[-] Build failed — no ISO produced."
    echo "[-] Check /output/build.log for details."
    exit 1
fi
