# Using the Hearts Command-Line Tool

Generate emoji-art from images using the Hearts command.

## Overview

Hearts is a command-line tool that converts images into strings of emoji characters. Each pixel in the source image is replaced with an emoji whose color best matches that pixel.

## Synopsis

```
hearts [--width <width>] [--coherency <coherency>] [--only <only>]
       [--background <background>] [--glyph-count] <file>
```

## Arguments

### file

The path to a local image file or a URL to download. Supports any image format that Core Image can read, including PNG, JPEG, HEIC, and more.

```bash
# Local file
swift run Hearts /path/to/image.png

# URL
swift run Hearts https://example.com/image.jpg
```

## Options

### --width, -w

Resize the image to the specified width in pixels before processing. Since each pixel becomes one emoji character, this effectively controls the output width in characters.

```bash
# 80-character wide output
swift run Hearts -w 80 image.png
```

If not specified, the image is processed at its original resolution.

### --coherency, -c

Control which emoji are used based on their color uniformity. Lower values are stricter, using only emoji with very uniform colors. Higher values include emoji with more color variation.

```bash
# Strict: only very uniform emoji (cleaner output)
swift run Hearts -c 0.1 image.png

# Permissive: include varied emoji
swift run Hearts -c 0.5 image.png
```

The default value is `0.2`.

### --only, -o

Restrict output to specific emoji. You can provide either:

1. **A string of emoji characters**: Use exactly these emoji
2. **A group name**: Use all emoji from a Unicode emoji group

```bash
# Use only heart emoji
swift run Hearts -w 80 --only "❤️🧡💛💚💙💜🩷🤎🖤🤍" image.png

# Use flag emoji
swift run Hearts -w 80 --only flags image.png

# Use multiple groups (comma-separated)
swift run Hearts -w 80 --only "animals-nature,food-drink" image.png
```

Available group names include:
- `smileys-emotion`
- `people-body`
- `animals-nature`
- `food-drink`
- `travel-places`
- `activities`
- `objects`
- `symbols`
- `flags`
- `hearts`

Subgroups are also available, like `cat-face` or `plant-flower`.

> Note: When using `--only`, the `--coherency` option is ignored.

### --background, -b

Specify the background color for transparency handling as three comma-separated float values (red, green, blue) in the range 0.0 to 1.0.

```bash
# White background
swift run Hearts -b 1,1,1 image.png

# Dark blue background
swift run Hearts -b 0,0,0.2 image.png
```

The default is black (`0,0,0`).

### --glyph-count, -g

Instead of processing an image, display the number of emoji that would be used with the current `--coherency` and `--only` settings. Useful for understanding how many emoji are available.

```bash
# How many emoji with default coherency?
swift run Hearts -g dummy.png

# How many flag emoji?
swift run Hearts -g --only flags dummy.png
```

## Examples

### Basic Usage

Convert an image to 80-character wide emoji-art:

```bash
swift run Hearts -w 80 photo.jpg
```

### Web Image

Process an image directly from a URL:

```bash
swift run Hearts -w 80 https://placekitten.com/200/300
```

### Themed Output

Create heart-themed emoji-art:

```bash
swift run Hearts -w 80 --only "❤️🧡💛💚💙💜🩷🤎🖤🤍" landscape.heic
```

### Flag Art

Use flag emoji for patriotic images:

```bash
swift run Hearts -w 80 --only flags flag.png
```

## Display Considerations

The quality of the output depends heavily on how emoji are rendered on the viewing platform:

### Fixed-Width Rendering
Emoji must be rendered as fixed-width characters. Not all platforms or font configurations do this correctly.

### Square Aspect Ratio
Emoji should be rendered as squares. If line height differs from character width, the output will appear stretched.

### Platform Differences
The color data is calculated from Apple's emoji font. Emoji on other platforms may have different colors, causing the output to look different.

### Complex Emoji Support
Some newer emoji use Zero-Width Joiner (ZWJ) sequences. Platforms that don't support these will display the emoji "decomposed" (showing separate characters), breaking the fixed-width alignment.

## Output

The tool outputs the emoji-art string directly to stdout, with newline characters separating each row. You can redirect this to a file or pipe it to other commands:

```bash
# Save to file
swift run Hearts -w 80 image.png > output.txt

# Copy to clipboard (macOS)
swift run Hearts -w 80 image.png | pbcopy
```
