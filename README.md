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

The repository root maps directly to `~/.config/ghostty/`.

```
~/.config/ghostty/   (repo root)
└── config.ghostty    # Main Ghostty configuration file
```

### Files

| Path | Description |
|------|-------------|
| `config.ghostty` | Main Ghostty configuration content |

## Setup

```sh
# Clone the repo
git clone https://github.com/alexxyjiang/ghostty-config.git ~/.config/ghostty
```

## Background Images

The repository includes several background images you can use with Ghostty:

- `kagaya_artemis.png` – default background referenced in `config.ghostty`.
- `everest_sunset.png` – a sunset theme.
- `clannad_kyou.png` – a bright, colorful image.

To use a different image, edit the `background-image` line in `config.ghostty` to point to the desired file.

## Generating Custom Wallpapers

The `make.ghostty.background.sh` script can generate a dark PNG wallpaper of size 3840×2160 with configurable contrast, saturation, and brightness. Example:

```sh
./make.ghostty.background.sh path/to/source.jpg path/to/output.png
```

Run `./make.ghostty.background.sh -h` for detailed options.

