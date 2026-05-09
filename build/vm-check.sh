#!/bin/bash
# VenomOS verification check script — executed inside the VM via virtio share
# No set -e: 'which' exits 1 when tool not found, we handle that explicitly

OUT=/mnt/hs/results.txt
exec > "$OUT" 2>&1

echo "=== VenomOS Verification Results ==="
echo "Date: $(date)"
echo "Kernel: $(uname -r)"
echo ""

echo "--- System ---"
echo "whoami:   $(whoami)"
echo "hostname: $(hostname)"
echo "uname:    $(uname -r)"
echo ""

echo "--- Services ---"
for svc in NetworkManager tor dnscrypt-proxy docker; do
    svc_status=$(systemctl is-active "$svc" 2>/dev/null || echo unknown)
    echo "  $svc: $svc_status"
done
echo ""

echo "--- Security Tools ---"
for t in nmap sqlmap hashcat hydra john aircrack-ng wifite nikto gobuster feroxbuster dnsenum theharvester whatweb; do
    p=$(which "$t" 2>/dev/null)
    if [ -n "$p" ]; then
        echo "  $t: $p"
    else
        echo "  $t: NOT FOUND"
    fi
done
echo ""

echo "--- Metasploit ---"
if which msfconsole >/dev/null 2>&1; then
    echo "  msfconsole: $(which msfconsole)"
else
    echo "  msfconsole: NOT FOUND"
fi
echo ""

echo "--- Shell / Terminal ---"
zsh --version 2>/dev/null | head -1 || echo "zsh: not found"
tmux -V 2>/dev/null || echo "tmux: not found"
echo ""

echo "--- VenomOS Bin Tools ---"
for t in venom-help venom-setup venom-vm venom-install; do
    if which "$t" >/dev/null 2>&1; then
        echo "  $t: $(which $t)"
    else
        echo "  $t: NOT FOUND"
    fi
done
echo ""

echo "--- Proxychains ---"
for pc in proxychains4 proxychains; do
    if which "$pc" >/dev/null 2>&1; then
        echo "  $pc: $(which $pc)"
        break
    fi
done
cat /etc/proxychains.conf 2>/dev/null | grep -v '^#' | grep -v '^$' | head -5 || echo "no proxychains.conf"
echo ""

echo "--- Tor / DNS ---"
echo "  /etc/resolv.conf:"
cat /etc/resolv.conf 2>/dev/null | head -5 || true
echo ""

echo "=== VERIFICATION COMPLETE ==="
