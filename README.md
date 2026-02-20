# Blackpearl

Automated and modular bootstrap script to provision a full Ubuntu-based penetration testing workstation.

⚠️ This repository is a **fork of the original xct setup**, with architectural and tooling improvements.

## Preview

<screen>
---

## Changes in this fork

- Modular structure (`modules/`)
- Centralized `bootstrap.sh`
- Idempotent step system
- Rust installed via `rustup` (instead of apt)
- Clean Go environment setup
- Clear separation: system / shell / UI / devtools
- Reproducible and maintainable design

---

## Included tooling

This setup provisions a ready-to-use offensive security environment, including:

- **Docker**
- **Exegol**
- **Burp Suite Pro**
- **VSCode**
- Common CLI tooling (git, curl, build tools, etc.)
- Rust & Go development environments

## Installation

```bash
git clone https://github.com/luksecurity/blackpearl.git
cd blackpearl/
chmod +x bootstrap.sh
./bootstrap.sh
```

## Re-run a Step

```bash
rm -f .done_<step_name>
```
