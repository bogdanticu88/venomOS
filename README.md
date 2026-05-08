# VenomOS

```
 __   _____ _  _  ___  __  __  ___  ___ 
 \ \ / / __| \| |/ _ \|  \/  |/ _ \/ __|
  \ V /| _|| .` | (_) | |\/| | (_) \__ \
   \_/ |___|_|\_|\___/|_|  |_|\___/|___/
```

**Intelligence. Precision. Persistence.**

VenomOS is a Debian-based live operating system built for intelligence analysts, security researchers, and APT trackers. It combines OSINT tooling, offensive security capabilities, and locally-run AI into a single, privacy-first platform.

---

## Who Is This For

- Cyber intelligence analysts
- APT researchers and threat hunters
- OSINT investigators
- Penetration testers
- Security researchers who need an air-gap capable, privacy-respecting environment

---

## Features

- **Live USB with encrypted persistence** — boot anywhere, leave nothing behind
- **Intelligence core** — YARA, Sigma rules, chainsaw, Volatility3, IOC tooling
- **OSINT toolkit** — 40+ tools: theHarvester, SpiderFoot, Sherlock, recon-ng, and more
- **Offensive layer** — Nmap, Impacket, NetExec, Responder, Nuclei, EvilGinx2, and more
- **Local AI** — `venom-ai` powered by Ollama (Mistral/Llama3), fully offline
- **Heavy tools on demand** — `venom-install` for Metasploit, Sliver, Havoc, Caldera
- **Hardened by default** — AppArmor, UFW, DNS-over-HTTPS, no telemetry
- **Full VenomOS identity** — custom GRUB menu, Plymouth splash, LightDM login, XFCE theme
- **Built on Debian Trixie** — stable, trusted, community-driven

---

## Build Requirements

- Docker Desktop (WSL2 backend) or a Linux host
- ~20GB free disk space
- WSL2 (Ubuntu or Debian) recommended on Windows

## Quick Build

```bash
# Clone the repo
git clone https://github.com/bogdanticu88/venomOS
cd venomOS/build

# Build the ISO (runs inside Docker)
bash run-build.sh
```

The ISO will be output to `venomOS/output/`.

---

## Stages

| Stage | Status | Description |
|-------|--------|-------------|
| 1 | Done | Base system — Debian + XFCE + branding + hardening |
| 2 | Done | Intelligence core — OSINT + APT tracking tools (40+ tools) |
| 3 | Done | Offensive layer — full pentesting toolkit |
| 4 | Done | AI layer — venom-ai, venom-install, Ollama + analyst prompts |
| 5 | Done | Polish — full VenomOS identity, Plymouth/GRUB/LightDM theming |

---

## Project Structure

```
venomOS/
  build/          live-build configs and Docker build system
  tools/          OSINT and security tool collection
  ai/             Ollama configs and analyst prompts
  hardening/      AppArmor profiles and system hardening
  themes/         Visual branding assets
  docs/           Documentation
  output/         Built ISO files (gitignored)
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to submit tools, report issues, or improve the build system.

---

## License

GPL-3.0 — see [LICENSE](LICENSE)
