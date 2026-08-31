#!/bin/sh

DEFAULT_CONTRAST=2.129
DEFAULT_SATURATION=5.573
DEFAULT_BRIGHTNESS=14.59
DEFAULT_OPTIPNG_LEVEL=3

TARGET_WIDTH=3840
TARGET_HEIGHT=2160
ANTIALIAS_SCALE=2
RENDER_WIDTH=$((TARGET_WIDTH * ANTIALIAS_SCALE))
RENDER_HEIGHT=$((TARGET_HEIGHT * ANTIALIAS_SCALE))

usage() {
    cat <<EOF
Usage: $0 [options] INPUT [OUTPUT]

Create a ${TARGET_WIDTH}x${TARGET_HEIGHT} dark PNG wallpaper using fixed 2x antialiasing.

Options:
  -c, --contrast VALUE        Target HSL lightness deviation, 0-100% (default: ${DEFAULT_CONTRAST})
  -s, --saturation VALUE      Target mean HSL saturation, 0-100% (default: ${DEFAULT_SATURATION})
  -b, --brightness VALUE      Target mean HSL lightness, 0-100% (default: ${DEFAULT_BRIGHTNESS})
  -o, --optimize-level VALUE  optipng level from 0 to 7 (default: ${DEFAULT_OPTIPNG_LEVEL})
  -h, --help                  Show this help

If OUTPUT is omitted, INPUT-wallpaper.png is written beside the input file.
Existing output files are never overwritten.
EOF
}

error() {
    printf 'Error: %s\n' "$*" >&2
}

install_hint() {
    case "$(uname -s 2>/dev/null)" in
        Darwin)
            printf '%s\n' 'Install the required tools with:' >&2
            printf '%s\n' '  brew install imagemagick optipng' >&2
            ;;
        Linux)
            if [ -r /etc/os-release ] &&
                (grep -Eq '^(ID|ID_LIKE)=.*debian' /etc/os-release 2>/dev/null); then
                printf '%s\n' 'Install the required tools with:' >&2
                printf '%s\n' '  sudo apt update' >&2
                printf '%s\n' '  sudo apt install imagemagick optipng' >&2
            else
                error 'unsupported Linux distribution; install ImageMagick and optipng manually'
            fi
            ;;
        *)
            error 'unsupported operating system; only macOS and Debian are supported'
            ;;
    esac
}

require_tools() {
    missing_tools=

    if command -v magick >/dev/null 2>&1; then
        IMAGE_MAGICK=magick
    elif command -v convert >/dev/null 2>&1; then
        IMAGE_MAGICK=convert
    else
        missing_tools=ImageMagick
    fi

    if ! command -v optipng >/dev/null 2>&1; then
        if [ -n "$missing_tools" ]; then
            missing_tools="$missing_tools and optipng"
        else
            missing_tools=optipng
        fi
    fi

    if [ -n "$missing_tools" ]; then
        error "$missing_tools is not installed or not available in PATH"
        install_hint
        exit 1
    fi
}

is_number() {
    awk -v value="$1" 'BEGIN {
        exit(value ~ /^-?([0-9]+([.][0-9]*)?|[.][0-9]+)$/ ? 0 : 1)
    }'
}

validate_range() {
    value=$1
    minimum=$2
    maximum=$3
    name=$4

    if ! is_number "$value" || ! awk -v value="$value" -v min="$minimum" -v max="$maximum" \
        'BEGIN { exit(value >= min && value <= max ? 0 : 1) }'; then
        error "$name must be a number from $minimum to $maximum"
        exit 2
    fi
}

validate_optimize_level() {
    case "$1" in
        [0-7]) ;;
        *)
            error 'optimize-level must be an integer from 0 to 7'
            exit 2
            ;;
    esac
}

path_identity() {
    path=$1
    directory=$(dirname -- "$path") || return 1
    filename=$(basename -- "$path") || return 1
    absolute_directory=$(CDPATH= cd -- "$directory" 2>/dev/null && pwd -P) || return 1
    printf '%s/%s\n' "$absolute_directory" "$filename"
}

contrast=$DEFAULT_CONTRAST
saturation=$DEFAULT_SATURATION
brightness=$DEFAULT_BRIGHTNESS
optimize_level=$DEFAULT_OPTIPNG_LEVEL

while [ "$#" -gt 0 ]; do
    case "$1" in
        -c|--contrast|-s|--saturation|-b|--brightness|-o|--optimize-level)
            option=$1
            if [ "$#" -lt 2 ]; then
                error "$option requires a value"
                usage >&2
                exit 2
            fi
            case "$option" in
                -c|--contrast) contrast=$2 ;;
                -s|--saturation) saturation=$2 ;;
                -b|--brightness) brightness=$2 ;;
                -o|--optimize-level) optimize_level=$2 ;;
            esac
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            error "unknown option: $1"
            usage >&2
            exit 2
            ;;
        *)
            break
            ;;
    esac
done

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    error 'expected INPUT and optional OUTPUT'
    usage >&2
    exit 2
fi

input=$1
if [ "$#" -eq 2 ]; then
    output=$2
else
    input_directory=$(dirname -- "$input")
    input_filename=$(basename -- "$input")
    input_stem=${input_filename%.*}
    if [ "$input_stem" = "$input_filename" ] && [ "${input_filename#*.}" = "$input_filename" ]; then
        input_stem=$input_filename
    fi
    output=$input_directory/$input_stem-wallpaper.png
fi

validate_range "$contrast" 0 100 contrast
validate_range "$saturation" 0 100 saturation
validate_range "$brightness" 0 100 brightness
validate_optimize_level "$optimize_level"

if [ ! -f "$input" ] || [ ! -r "$input" ]; then
    error "input is not a readable file: $input"
    exit 1
fi

output_directory=$(dirname -- "$output")
if [ ! -d "$output_directory" ]; then
    error "output directory does not exist: $output_directory"
    exit 1
fi
if [ ! -w "$output_directory" ]; then
    error "output directory is not writable: $output_directory"
    exit 1
fi
if [ -e "$output" ] || [ -L "$output" ]; then
    error "output already exists: $output"
    exit 1
fi

input_identity=$(path_identity "$input") || {
    error "cannot resolve input path: $input"
    exit 1
}
output_identity=$(path_identity "$output") || {
    error "cannot resolve output path: $output"
    exit 1
}
if [ "$input_identity" = "$output_identity" ]; then
    error 'input and output must be different files'
    exit 1
fi

require_tools

temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/make-wallpaper.XXXXXX") || {
    error 'could not create a temporary directory'
    exit 1
}
resized_png=$temporary_directory/resized.png
temporary_png=$temporary_directory/wallpaper.png

cleanup() {
    rm -rf -- "$temporary_directory"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

if ! "$IMAGE_MAGICK" "$input" \
    -auto-orient \
    -filter Lanczos \
    -resize "${RENDER_WIDTH}x${RENDER_HEIGHT}^" \
    -gravity center \
    -extent "${RENDER_WIDTH}x${RENDER_HEIGHT}" \
    "$resized_png"; then
    error 'ImageMagick failed to resize the image'
    exit 1
fi

metrics=$("$IMAGE_MAGICK" "$resized_png" -colorspace HSL \
    -format '%[fx:mean.g] %[fx:mean.b] %[fx:standard_deviation.b]' info:) || {
    error 'ImageMagick failed to measure the input image'
    exit 1
}
set -- $metrics
source_saturation=$1
source_brightness=$2
source_contrast=$3

adjustments=$(awk \
    -v source_saturation="$source_saturation" \
    -v source_brightness="$source_brightness" \
    -v source_contrast="$source_contrast" \
    -v target_saturation="$saturation" \
    -v target_brightness="$brightness" \
    -v target_contrast="$contrast" '
    BEGIN {
        target_saturation /= 100
        target_brightness /= 100
        target_contrast /= 100

        if (source_saturation == 0 && target_saturation != 0) exit 2
        if (source_contrast == 0 && target_contrast != 0) exit 3

        saturation_scale = source_saturation == 0 ? 0 : target_saturation / source_saturation
        contrast_scale = source_contrast == 0 ? 0 : target_contrast / source_contrast
        brightness_offset = (target_brightness - source_brightness * contrast_scale) * 100
        printf "%.12g %.12g %.12g\n", saturation_scale, contrast_scale, brightness_offset
    }')
adjustment_status=$?
case "$adjustment_status" in
    0) ;;
    2)
        error 'cannot create nonzero saturation from a completely grayscale input'
        exit 1
        ;;
    3)
        error 'cannot create nonzero contrast from an input with uniform lightness'
        exit 1
        ;;
    *)
        error 'failed to calculate image adjustments'
        exit 1
        ;;
esac
set -- $adjustments
saturation_scale=$1
contrast_scale=$2
brightness_offset=$3

if ! "$IMAGE_MAGICK" "$resized_png" \
    -colorspace HSL \
    -channel G -evaluate multiply "$saturation_scale" +channel \
    -channel B -evaluate multiply "$contrast_scale" \
    -evaluate add "${brightness_offset}%" +channel \
    -colorspace sRGB \
    -filter Lanczos \
    -resize "${TARGET_WIDTH}x${TARGET_HEIGHT}!" \
    -strip \
    "$temporary_png"; then
    error 'ImageMagick failed to process the image'
    exit 1
fi

if ! optipng -quiet "-o${optimize_level}" "$temporary_png"; then
    error 'optipng failed to optimize the image'
    exit 1
fi

if [ -e "$output" ] || [ -L "$output" ]; then
    error "output was created while processing; refusing to overwrite it: $output"
    exit 1
fi
if ! mv -- "$temporary_png" "$output"; then
    error "could not write output: $output"
    exit 1
fi

printf 'Created wallpaper: %s\n' "$output"
