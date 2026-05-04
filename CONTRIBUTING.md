# Contributing to VenomOS

VenomOS is a community-driven project. Contributions are welcome in any of these areas:

## Ways to Contribute

### Submit a Tool
Open an issue or PR with:
- Tool name and GitHub link
- Category (recon / ioc-enrichment / attribution / network / visualization / offensive)
- Brief description of what it does
- Any known dependencies or conflicts

### Improve the Build System
- Bug fixes in `build/` scripts
- Package list improvements
- Hook optimizations

### Add Hardening Configs
- AppArmor profiles for new tools
- Sysctl tuning improvements
- Network hardening configs

### Improve the AI Layer
- New analyst prompt templates in `ai/prompts/`
- Ollama model recommendations
- Workflow automation scripts

---

## Guidelines

- All tools must be open source
- No tools that exist solely for illegal use
- Test before submitting — if it breaks the build, the PR won't merge
- Keep commits focused — one change per PR

## Reporting Issues

Open a GitHub Issue with:
- VenomOS version / stage
- Steps to reproduce
- Expected vs actual behavior
