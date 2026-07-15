# ghostty-config

This repository syncs personal [Ghostty](https://ghostty.org/) terminal emulator configurations.

## XDG Base Directory

Ghostty follows the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/).
Configuration files are stored under `$XDG_CONFIG_HOME`, which defaults to `~/.config` when not explicitly set.

Ghostty's local config path is therefore:

```
~/.config/ghostty/
```

## Repository Structure

```
ghostty-config/
└── config          # Main Ghostty configuration file
```

### Files

| Path | Description |
|------|-------------|
| `config` | Main Ghostty configuration content used under `~/.config/ghostty` |

## Setup

```sh
# Clone the repo
git clone https://github.com/alexxyjiang/ghostty-config.git ~/.config/ghostty
```
