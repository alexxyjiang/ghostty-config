# ghostty-config

This repository syncs personal [Ghostty](https://ghostty.org/) terminal emulator configurations.

## XDG Base Directory

Ghostty follows the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/).
Configuration files are stored under `$XDG_CONFIG_HOME`, which defaults to `~/.config` when not explicitly set.

Ghostty's local config path is therefore:

```
~/.config/ghostty/
```

To store configs in a non-default location, set `$XDG_CONFIG_HOME` before launching Ghostty:

```sh
export XDG_CONFIG_HOME="$HOME/my-configs"
# Ghostty will then look for config at $HOME/my-configs/ghostty/config
```

## Repository Structure

```
ghostty-config/
├── config          # Main Ghostty configuration file
└── themes/         # Custom color themes (*.conf files)
```

### Files

| Path | Description |
|------|-------------|
| `config` | Main configuration file — maps to `~/.config/ghostty/config` |
| `themes/` | Directory of custom themes — maps to `~/.config/ghostty/themes/` |

## Setup

Symlink this repository into the Ghostty config directory:

```sh
# Clone the repo
git clone https://github.com/alexxyjiang/ghostty-config.git ~/.config/ghostty

# Or symlink individual files if the directory already exists
ln -sf /path/to/ghostty-config/config ~/.config/ghostty/config
ln -sf /path/to/ghostty-config/themes ~/.config/ghostty/themes
```
