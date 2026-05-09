# VenomOS

```
 __   _____ _  _  ___  __  __  ___  ___
 \ \ / / __| \| |/ _ \|  \/  |/ _ \/ __|
  \ V /| _|| .` | (_) | |\/| | (_) \__ \
   \_/ |___|_|\_|\___/|_|  |_|\___/|___/
```

**Intelligence. Precision. Persistence.**

VenomOS is a stealth-first, offensive-capable live OS built for threat intelligence
analysts, OSINT investigators, and red team operators. Built on Arch Linux with the
BlackArch tool repository — minimal, fast, rolling, and yours.

---

## Architecture

```
VenomOS (Arch base — CLI only, boots to TTY)
│
├── venom-vm          VM orchestration layer
│   ├── pentest-vm    offensive tools, isolated network
│   ├── osint-vm      browser + OSINT, routed through Tor
│   ├── malware-vm    isolated analysis, no network
│   └── vault-vm      air-gapped, sensitive data only
│
├── venom-setup       first-boot tool installer
├── venom-help        tool reference
└── venom-install     heavy tools on demand
```

## Design Principles

- **Stealth first** — RAM-only by default, MAC randomization, Tor routing, no traces
- **CLI native** — boots to TTY, tmux as the desktop, no display server on host
- **VM isolated** — each task in its own QEMU VM, separate network paths
- **Persistence optional** — explicit opt-in, encrypted, on USB only
- **Your tools** — built around custom tooling, not repackaged Kali

## Base

- **Arch Linux** — minimal, rolling, nothing you didn't put there
- **BlackArch repo** — 2800+ security tools as native pacman packages
- **archiso** — clean reproducible ISO builds

## Stealth Layer

- MAC address randomization on every boot
- Tor as default gateway for OSINT/anonymous VMs
- DNS routed through dnscrypt-proxy (port 53, localhost)
- systemd-resolved disabled and masked — no DNS stub leaks
- RAM-only live environment, no writes to disk by default
- No swap, no logs persisted by default

## Default Credentials

| User | Password |
|------|----------|
| root | venom |
| venom | live |

`venom` has passwordless sudo. Default shell is zsh. tmux starts automatically on login.

## Services (auto-start on boot)

| Service | Purpose |
|---------|---------|
| NetworkManager | network management |
| tor | Tor daemon (SOCKS on 9050/9150, TransPort 9040) |
| dnscrypt-proxy | encrypted DNS on 127.0.0.1:53 |
| docker | container runtime |
| sshd | SSH server |
| venomos-dns-fix | one-shot: writes plain resolv.conf before dnscrypt-proxy starts |

## Pre-installed Tools

### Network & Traffic
`nmap` `masscan` `wireshark-cli` `tcpdump` `socat` `ettercap` `bettercap` `mtr`

### Wireless
`aircrack-ng` `kismet` `wifite`

### Web & OSINT
`sqlmap` `nikto` `dirb` `wfuzz` `ffuf` `nuclei` `gobuster` `feroxbuster`
`whatweb` `theharvester` `dnsenum`

### Password & Credential
`hashcat` `john` `hydra` `medusa` `crunch`

### Exploitation
`metasploit` `exploitdb`

### Forensics
`sleuthkit` `autopsy` `foremost` `scalpel` `testdisk` `dc3dd`

### Reverse Engineering
`radare2` `ghidra` `gdb` `pwndbg` `yara`

### Anonymity & Routing
`tor` `torsocks` `proxychains-ng` `openvpn` `wireguard-tools` `macchanger` `dnscrypt-proxy`

## Custom Tools

Personal tooling cloned at first boot via `sudo venom-setup`:

- **ApexHunter** — threat hunting playbooks
- **SCARABEO** — malware analysis framework
- **RogueDetect** — rogue device detection
- **ERIS Intelligence** — threat intelligence
- **AuthBridge** — authentication analysis
- **ReqReaper** — API security testing
- **ThreatMap** — MITRE ATT&CK mapping

## Build

### Prerequisites

- **Windows**: Docker Desktop with WSL2 backend enabled
- **Linux**: Docker installed and running
- 16 GB RAM recommended (8 GB minimum)
- 30 GB free disk space (packages cache + ISO output)

### Build steps

```bash
git clone https://github.com/bogdanticu88/venomOS
cd venomOS
bash build/run-build.sh
```

Run `bash build/run-build.sh` from inside WSL2 on Windows. On Linux, run it directly.

The build runs inside a privileged Docker container. First run downloads ~3.5 GB of
packages; subsequent builds use the cached `venomos-pacman-cache` Docker volume and
complete in a fraction of the time.

ISO output: `output/venomos-1.0-x86_64.iso` (~4.5 GB)

Build log: `build.log` (project root)

## Persistent USB

```bash
# Flash ISO to USB (replace sdX with your device)
dd if=output/venomos-1.0-x86_64.iso of=/dev/sdX bs=4M status=progress conv=fsync

# Create persistence partition (remaining space on USB)
# Label it 'persistence' — VenomOS picks it up automatically on boot
```

## Legacy

Debian-based build archived at: `legacy/debian-base`

---

## License

GPL-3.0 — see [LICENSE](LICENSE)
