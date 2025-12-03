# ``GenerateColors``

Generate emoji color data for use by libHearts.

## Overview

GenerateColors is an internal build tool that creates the `colors.json` file used by libHearts. This file contains the average color and color standard deviation for every emoji character, enabling accurate color matching during emoji-art generation.

## When to Run

Run this tool when:

- Updating to a new Unicode emoji version
- Apple releases emoji with new or changed colors
- The `characters.txt` input file has been regenerated

## Usage

```bash
# Generate colors.json in the current directory
swift run GenerateColors

# Specify an output path
swift run GenerateColors /path/to/colors.json
```

The tool reads emoji characters from the bundled `characters.txt` resource file, renders each emoji using Core Text, analyzes the pixel colors, and outputs JSON data.

## Output Format

The output is a JSON array where each entry contains:

1. The emoji character (string)
2. Mean red component (0.0-1.0)
3. Mean green component (0.0-1.0)
4. Mean blue component (0.0-1.0)
5. Red standard deviation
6. Green standard deviation
7. Blue standard deviation

```json
[
  ["❤️", 0.89, 0.12, 0.15, 0.08, 0.05, 0.06],
  ...
]
```

## Performance

The tool processes emoji in parallel and displays a progress bar. Processing all emoji typically completes in under a minute on modern hardware.

> Important: This tool must run on macOS to access Apple's emoji font via Core Text.
