# VenomOS — Recommended Ollama Models

Install Ollama and pull these models for full analyst capability:

```bash
# General intelligence analysis
ollama pull llama3

# Fast, lightweight — for quick IOC lookups
ollama pull mistral

# Code and script analysis
ollama pull codellama

# Alternative general model with good instruction following
ollama pull phi3
```

## Usage

```bash
# Quick query
venom-ai "Analyze this IP: 185.220.101.45"

# IOC enrichment
venom-ai ioc 185.220.101.45

# APT attribution
venom-ai apt "T1059.001, T1027, spearphishing via OneDrive link"

# OSINT correlation
venom-ai osint "Lazarus Group"
```

## Model Selection

The `venom-ai` wrapper defaults to `mistral` for speed.
Set a different default: `export VENOM_MODEL=llama3`
