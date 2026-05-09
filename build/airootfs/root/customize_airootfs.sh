#!/bin/bash
# VenomOS airootfs customization script
# Runs inside the chroot during archiso build
set -e

echo "[*] VenomOS: Customizing airootfs..."

# ── Users ─────────────────────────────────────────────────────────────────────
# Some post-install hooks segfault in the chroot and may not create groups.
# Create any missing groups before useradd so it doesn't fail silently.
for grp in wheel audio video optical storage network docker; do
    getent group "$grp" &>/dev/null || groupadd "$grp"
done

useradd -m venom || true
for grp in wheel audio video optical storage network docker; do
    usermod -aG "$grp" venom 2>/dev/null || true
done

# chpasswd uses PAM which isn't fully initialised in the archiso chroot;
# set password hashes directly via usermod to avoid the failure.
usermod -p "$(openssl passwd -6 'live')" venom
usermod -p "$(openssl passwd -6 'venom')" root

# Passwordless sudo for venom
echo "venom ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/venom
chmod 440 /etc/sudoers.d/venom

# ── Shell ─────────────────────────────────────────────────────────────────────
# Populate /etc/shells so zsh is recognised, then set shell via usermod
# (usermod -s does not check /etc/shells; chsh does)
grep -qx '/bin/zsh' /etc/shells 2>/dev/null || echo '/bin/zsh' >> /etc/shells
usermod -s /bin/zsh venom
usermod -s /bin/zsh root

# Copy skel to venom home
cp -r /etc/skel/. /home/venom/ 2>/dev/null || true
cp -r /etc/skel/. /root/ 2>/dev/null || true
chown -R venom:venom /home/venom

# ── Hostname ──────────────────────────────────────────────────────────────────
echo "venomOS" > /etc/hostname
cat > /etc/hosts << 'EOF'
127.0.0.1   localhost
127.0.1.1   venomOS
::1         localhost
EOF

# ── Services ──────────────────────────────────────────────────────────────────
systemctl enable NetworkManager
systemctl enable tor
systemctl enable dnscrypt-proxy
systemctl enable docker
systemctl enable sshd
# Mask systemd-resolved so it can never start (disable alone is not enough;
# NetworkManager can re-enable it). dnscrypt-proxy owns port 53 instead.
systemctl disable systemd-resolved 2>/dev/null || true
systemctl mask systemd-resolved 2>/dev/null || true

# ── DNS — route through dnscrypt-proxy ───────────────────────────────────────
# mkarchiso bind-mounts the host's /etc/resolv.conf into the chroot so packages
# can be downloaded — rm -f fails with "Device or resource busy" on that mount.
# Instead we install a one-shot systemd service that fixes resolv.conf at runtime
# (after the bind mount is gone) before dnscrypt-proxy starts.
cat > /etc/systemd/system/venomos-dns-fix.service << 'SVCEOF'
[Unit]
Description=VenomOS: replace resolv.conf symlink for dnscrypt-proxy
DefaultDependencies=no
Before=dnscrypt-proxy.service network-pre.target
After=local-fs.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c 'chattr -i /etc/resolv.conf 2>/dev/null; rm -f /etc/resolv.conf; printf "nameserver 127.0.0.1\noptions edns0 single-request-reopen\n" > /etc/resolv.conf; chattr +i /etc/resolv.conf 2>/dev/null'

[Install]
WantedBy=multi-user.target
SVCEOF
systemctl enable venomos-dns-fix

# ── Stealth — MAC randomization ───────────────────────────────────────────────
chmod +x /etc/NetworkManager/dispatcher.d/99-macspoof 2>/dev/null || true

# ── Tor configuration ─────────────────────────────────────────────────────────
cat >> /etc/tor/torrc << 'EOF'

# VenomOS Tor config
SocksPort 9050
SocksPort 9150
DNSPort 5353
TransPort 9040
AutomapHostsOnResolve 1
EOF

# ── Proxychains — Tor by default ──────────────────────────────────────────────
cat > /etc/proxychains.conf << 'EOF'
strict_chain
proxy_dns
remote_dns_subnet 224
tcp_read_time_out 15000
tcp_connect_time_out 8000

[ProxyList]
socks5 127.0.0.1 9050
EOF

# ── Hardening ─────────────────────────────────────────────────────────────────
cat > /etc/sysctl.d/99-venomos.conf << 'EOF'
net.ipv4.ip_forward = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.tcp_syncookies = 1
net.ipv6.conf.all.disable_ipv6 = 1
kernel.dmesg_restrict = 1
kernel.yama.ptrace_scope = 1
kernel.kptr_restrict = 2
net.ipv4.conf.all.rp_filter = 1
EOF

# ── MOTD ─────────────────────────────────────────────────────────────────────
cat > /etc/motd << 'EOF'

 __   _____ _  _  ___  __  __  ___  ___
 \ \ / / __| \| |/ _ \|  \/  |/ _ \/ __|
  \ V /| _|| .` | (_) | |\/| | (_) \__ \
   \_/ |___|_|\_|\___/|_|  |_|\___/|___/

  VenomOS 1.0 — Intelligence. Precision. Persistence.
  Run 'venom-help' to see available tools.
  Run 'sudo venom-setup' to install personal tools.

EOF

# ── VenomOS bin permissions ───────────────────────────────────────────────────
mkdir -p /opt/venomOS/{bin,tools,vms,isos}
chmod +x /opt/venomOS/bin/* 2>/dev/null || true
for cmd in venom-setup venom-help venom-vm venom-install; do
    [ -f "/opt/venomOS/bin/$cmd" ] && \
        ln -sf "/opt/venomOS/bin/$cmd" "/usr/local/bin/$cmd"
done

# ── Fastfetch VenomOS config ──────────────────────────────────────────────────
mkdir -p /etc/fastfetch
cat > /etc/fastfetch/config.jsonc << 'FFEOF'
{
  "logo": {
    "type": "builtin",
    "source": "arch",
    "color": { "1": "green", "2": "green" }
  },
  "modules": [
    "title",
    "separator",
    { "type": "os",     "key": "  OS     " },
    { "type": "kernel", "key": "  Kernel " },
    { "type": "uptime", "key": "  Uptime " },
    { "type": "shell",  "key": "  Shell  " },
    { "type": "cpu",    "key": "  CPU    " },
    { "type": "memory", "key": "  Memory " },
    "break",
    "colors"
  ]
}
FFEOF

# ── Initramfs safety net ─────────────────────────────────────────────────────
echo "[*] /boot directory:"
ls -la /boot/ 2>&1 || true
echo "[*] Kernel modules:"
ls /usr/lib/modules/ 2>&1 || true

# In Docker's overlay FS the linux package may not write to /boot.
# The same vmlinuz is always present under the modules tree — copy it there.
KMOD_VER=$(ls /usr/lib/modules/ 2>/dev/null | sort -V | tail -1)

# depmod generates modules.devname, modules.alias, modules.dep etc.
# These are normally created by the linux post-install hook, which segfaults
# in Docker's overlay chroot. Without modules.devname, udev cannot probe
# the CD-ROM by UUID at boot (archiso hook fails with "Device not found").
if [ -n "$KMOD_VER" ]; then
    echo "[*] Running depmod to generate module dependency files..."
    depmod -a "$KMOD_VER" 2>&1 || echo "[!] depmod failed"
fi

if [ -n "$KMOD_VER" ] && [ ! -f /boot/vmlinuz-linux ]; then
    KMOD_VMLINUZ="/usr/lib/modules/${KMOD_VER}/vmlinuz"
    if [ -f "$KMOD_VMLINUZ" ]; then
        echo "[*] Copying kernel from $KMOD_VMLINUZ → /boot/vmlinuz-linux"
        install -Dm644 "$KMOD_VMLINUZ" /boot/vmlinuz-linux
    else
        echo "[!] vmlinuz not found in modules either — searching..."
        find /usr/lib/modules -name "vmlinuz*" 2>/dev/null || true
    fi
fi

if [ -f /boot/vmlinuz-linux ]; then
    if [ ! -f /boot/initramfs-linux.img ]; then
        echo "[*] Running mkinitcpio to generate initramfs..."
        mkinitcpio -P 2>&1 || echo "[!] mkinitcpio failed"
    else
        echo "[*] initramfs already present"
    fi
else
    echo "[!] No vmlinuz found — archiso will fail to build boot image"
fi

echo "[+] VenomOS airootfs customization complete."
