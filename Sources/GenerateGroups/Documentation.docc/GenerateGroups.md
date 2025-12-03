# ``GenerateGroups``

Generate emoji group mappings from the Unicode specification.

## Overview

GenerateGroups is an internal build tool that creates the `groups.json` file used by libHearts. This file maps Unicode emoji group and subgroup names to their constituent emoji characters, enabling users to select emoji by category (like "flags" or "food-drink").

## When to Run

Run this tool when:

- Updating to a new Unicode emoji version
- New emoji groups or subgroups are added to the specification

## Usage

```bash
# Generate groups.json using the default emoji version (16.0)
swift run GenerateGroups

# Specify an emoji version
swift run GenerateGroups -e 15.1

# Specify an output path
swift run GenerateGroups /path/to/groups.json
```

The tool downloads the `emoji-test.txt` file from the Unicode Consortium, parses the group and subgroup definitions, and outputs a JSON mapping.

## Options

### --emoji-version, -e

The Unicode Emoji specification version to use. Defaults to `16.0`.

```bash
swift run GenerateGroups -e 15.1
```

## Output Format

The output is a JSON object mapping group/subgroup names (normalized to lowercase with hyphens) to strings containing all emoji in that group:

```json
{
  "flags": "🏁🚩🎌🏴🏳️...",
  "flag": "🏁🚩🎌🏴🏳️...",
  "food-drink": "🍇🍈🍉🍊🍋...",
  ...
}
```

Both group names (like "flags") and subgroup names (like "country-flag") are included.

## Custom Groups

The tool also includes custom group definitions hardcoded in the source, such as the `hearts` group containing only heart emoji of various colors.
