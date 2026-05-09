#!/usr/bin/env python3
"""
VenomOS headless verification script — v2.
Strategy:
  1. Boot via direct kernel boot (archisodevice + kernel/initrd)
  2. Log in as root through serial socket
  3. Kill tmux (auto-started by .zshrc) to get a clean shell
  4. Mount a virtio-9p share so we can write results without parsing terminal output
  5. Run all checks, redirect to share file
  6. poweroff — read results from the host-side share folder
"""

import os
import sys
import time
import socket
import subprocess

ISO    = "/mnt/c/Users/mihai/OneDrive/Desktop/venomOS/output/venomos-1.0-x86_64.iso"
KERNEL = "/tmp/venomos-boot/vmlinuz-linux"
INITRD = "/tmp/venomos-boot/initramfs-linux.img"
SOCK   = "/tmp/venomos-serial.sock"
SHARE  = "/tmp/venomos-share"
LOG    = "/tmp/venomos-test.log"

BOOT_TIMEOUT = 360  # seconds

# ── helpers ───────────────────────────────────────────────────────────────────

def log(msg):
    ts = time.strftime("%H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line, flush=True)
    with open(LOG, "a") as f:
        f.write(line + "\n")

def recv_until(sock, needle, timeout, buf=b"", search_start=0):
    """Read from socket until needle appears in data AFTER search_start."""
    if isinstance(needle, str):
        needle = needle.encode()
    deadline = time.time() + timeout
    sock.settimeout(2)
    while time.time() < deadline:
        try:
            chunk = sock.recv(4096)
            if not chunk:
                time.sleep(0.1)
                continue
            buf += chunk
            sys.stdout.buffer.write(chunk)
            sys.stdout.flush()
        except socket.timeout:
            pass
        if needle in buf[search_start:]:
            return True, buf
    return False, buf

def send(sock, text):
    log(f"  >> {text[:80]}")
    sock.sendall((text + "\n").encode())

def drain(sock, buf, wait=1.5):
    """Read any pending data for `wait` seconds into buf."""
    sock.settimeout(0.3)
    deadline = time.time() + wait
    while time.time() < deadline:
        try:
            chunk = sock.recv(4096)
            if chunk:
                buf += chunk
                sys.stdout.buffer.write(chunk)
                sys.stdout.flush()
        except socket.timeout:
            pass
    return buf

# ── main ──────────────────────────────────────────────────────────────────────

def main():
    os.makedirs(SHARE, exist_ok=True)
    if os.path.exists(SOCK):
        os.unlink(SOCK)
    open(LOG, "w").close()
    # Remove any old results
    results_file = os.path.join(SHARE, "results.txt")
    if os.path.exists(results_file):
        os.unlink(results_file)

    log("=== VenomOS Headless Verification v2 ===")

    qemu_cmd = [
        "qemu-system-x86_64",
        "-enable-kvm",
        "-m", "2048",
        "-smp", "2",
        "-kernel", KERNEL,
        "-initrd", INITRD,
        "-append",
        ("archisodevice=/dev/sr0 archisobasedir=arch archisolabel=VENOMOS "
         "console=ttyS0,115200 quiet loglevel=3"),
        "-cdrom", ISO,
        "-display", "none",
        "-device", "virtio-net-pci,netdev=net0",
        "-netdev", "user,id=net0",
        # virtio-9p share so the VM can write results we can read without
        # parsing escape-sequence-laden terminal output
        "-virtfs", f"local,path={SHARE},mount_tag=hostshare,security_model=none",
        "-serial", f"unix:{SOCK},server,nowait",
        "-no-reboot",
    ]

    log("Launching QEMU with virtio-9p share...")
    proc = subprocess.Popen(
        qemu_cmd,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
        env={**os.environ, "DISPLAY": ""},
    )

    for _ in range(20):
        if os.path.exists(SOCK):
            break
        time.sleep(0.5)
    else:
        log("ERROR: serial socket never appeared")
        err = proc.stderr.read().decode(errors="replace")
        log("QEMU stderr:\n" + err)
        sys.exit(1)

    log("Serial socket ready — connecting...")
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(SOCK)

    # ── Wait for login prompt ────────────────────────────────────────────────
    log(f"Waiting up to {BOOT_TIMEOUT}s for login prompt...")
    found, buf = recv_until(sock, "login:", BOOT_TIMEOUT)
    if not found:
        log("ERROR: login prompt not seen")
        proc.terminate()
        sys.exit(1)
    log("Login prompt seen")

    time.sleep(0.5)
    send(sock, "root")

    found, buf = recv_until(sock, "Password:", 15, buf)
    if found:
        log("Sending password")
        time.sleep(0.3)
        send(sock, "venom")

    # Wait for shell prompt — look for "# " after login sequence
    found, buf = recv_until(sock, "# ", 30, buf)
    if not found:
        log("ERROR: shell prompt not seen after login")
        proc.terminate()
        sys.exit(1)
    log("Shell prompt seen — draining tmux startup noise...")
    # Give tmux time to fully start and settle
    buf = drain(sock, buf, wait=4)

    # ── Escape tmux ──────────────────────────────────────────────────────────
    # .zshrc auto-starts tmux. Kill it to get back to a clean outer zsh.
    log("Killing tmux to escape to clean shell...")
    search_start = len(buf)
    send(sock, "tmux kill-server 2>/dev/null; true")
    # After tmux dies, the outer zsh shows fastfetch then its prompt
    buf = drain(sock, buf, wait=5)  # let fastfetch + prompt render
    log("Post-tmux-kill drain complete")

    # Look for the shell prompt (zsh: "# " for root)
    found, buf = recv_until(sock, "# ", 20, buf, search_start)
    buf = drain(sock, buf, wait=2)
    log("Clean shell obtained")

    # ── Copy check script to share, mount in VM, execute ────────────────────
    # The check script was pre-written to the host share dir before QEMU started.
    # Inside the VM we just run: bash /mnt/hs/check.sh
    # This avoids multi-line interactive shell issues and zsh reserved-var conflicts.
    log("Mounting virtio-9p host share...")
    search_start = len(buf)
    send(sock, "mkdir -p /mnt/hs && mount -t 9p -o trans=virtio,version=9p2000.L hostshare /mnt/hs 2>/tmp/mount.err && echo MOUNT_OK || echo MOUNT_FAIL")
    found, buf = recv_until(sock, "MOUNT_", 15, buf, search_start)
    buf = drain(sock, buf, wait=1)
    if b"MOUNT_OK" not in buf[search_start:]:
        log("virtio-9p mount failed — check QEMU stderr")
        proc.terminate()
        sys.exit(1)
    log("Share mounted — running check script via bash...")

    search_start = len(buf)
    # Run the pre-written check script as bash (not zsh, avoids read-only `status`)
    send(sock, "bash /mnt/hs/check.sh; echo CHECK_DONE")
    # Wait for completion — the script runs all tools checks, may take up to 30s
    found, buf = recv_until(sock, "CHECK_DONE", 60, buf, search_start)
    buf = drain(sock, buf, wait=2)
    log("Check script finished")

    send(sock, "sync; poweroff")

    # Wait for QEMU to exit
    log("Waiting for VM to shut down...")
    try:
        proc.wait(timeout=60)
    except subprocess.TimeoutExpired:
        proc.terminate()
    sock.close()

    # ── Read results file ─────────────────────────────────────────────────────
    log("\n" + "=" * 60)
    if os.path.exists(results_file):
        with open(results_file) as f:
            content = f.read()
        log("RESULTS FILE:\n" + content)
        print("\n" + "=" * 60)
        print(content)
    else:
        log("Results file not found — check terminal output above")

if __name__ == "__main__":
    main()
