# ``GenerateCharacters``

Generate a list of all emoji characters from the Unicode specification.

## Overview

GenerateCharacters is an internal build tool that creates the `characters.txt` file used by GenerateColors. This file contains every emoji character defined in the Unicode emoji specification, including base emoji and ZWJ sequences.

## When to Run

Run this tool when:

- Updating to a new Unicode emoji version
- Before running GenerateColors to ensure all new emoji are included

## Usage

```bash
# Generate characters.txt using the default emoji version (16.0)
swift run GenerateCharacters

# Specify an emoji version
swift run GenerateCharacters -e 15.1

# Specify an output path
swift run GenerateCharacters /path/to/characters.txt
```

The tool downloads the `emoji-sequences.txt` and `emoji-zwj-sequences.txt` files from the Unicode Consortium and combines them into a single character list.

## Options

### --emoji-version, -e

The Unicode Emoji specification version to use. Defaults to `16.0`.

```bash
swift run GenerateCharacters -e 15.1
```

## Output Format

The output is a text file containing all emoji characters concatenated together (no separators). The file uses UTF-16 encoding.

## Workflow

The typical workflow when updating emoji data is:

1. Run `GenerateCharacters` to get the latest emoji list
2. Copy the output to `Sources/GenerateColors/Resources/characters.txt`
3. Run `GenerateColors` to compute color data
4. Copy the output to `Sources/libHearts/Resources/colors.json`
5. Run `GenerateGroups` to get the latest group mappings
6. Copy the output to `Sources/libHearts/Resources/groups.json`
