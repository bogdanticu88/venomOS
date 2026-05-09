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
- DNS-over-HTTPS only
- RAM wipe on shutdown
- No swap, no logs persisted by default
- Timestomping tools built in

## Tool Categories

| Category | Source |
|----------|--------|
| Recon & OSINT | BlackArch repo + venom-setup |
| Offensive | BlackArch repo + venom-setup |
| Malware Analysis | BlackArch repo + venom-setup |
| Threat Intel | venom-setup (custom tools) |
| Network | BlackArch repo |
| Forensics | BlackArch repo |

## Custom Tools

Personal tooling cloned at first boot:

- **ApexHunter** — threat hunting playbooks
- **SCARABEO** — malware analysis framework  
- **RogueDetect** — rogue device detection
- **ERIS Intelligence** — threat intelligence
- **AuthBridge** — authentication analysis
- **ReqReaper** — API security testing
- **ThreatMap** — MITRE ATT&CK mapping

## Build

```bash
# Requires Docker with WSL2 backend (Windows) or Linux host
git clone https://github.com/bogdanticu88/venomOS
cd venomOS/build
bash run-build.sh
```

ISO output: `venomOS/output/venomos-x86_64.iso`

## Persistent USB

```bash
# Flash ISO
dd if=output/venomos-x86_64.iso of=/dev/sdX bs=4M status=progress conv=fsync

# Create persistence partition (remaining space on USB)
# Label it 'persistence' — VenomOS picks it up automatically on boot
```

## Legacy

Debian-based build archived at: `legacy/debian-base`

---

## License

GPL-3.0 — see [LICENSE](LICENSE)
