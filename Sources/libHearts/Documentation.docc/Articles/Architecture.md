# Architecture

Understand how libHearts processes images and generates emoji-art.

## Overview

libHearts uses a layered architecture with Swift actors for thread-safe concurrent processing. The library processes images in parallel, analyzing multiple pixels simultaneously to maximize performance.

![The architecture of libHearts showing the CLI layer, library layer, common utilities, and bundled resources](architecture.png)

## Components

### EmojiArt

``EmojiArt`` is the main entry point and orchestrator. When you call ``EmojiArt/process(image:)``, it:

1. Extracts pixels from the input `CIImage`
2. Spawns concurrent tasks to process each pixel
3. For each pixel, finds the emoji with the closest matching color
4. Assembles the results into a string with newlines for each row

### ColorData

The `ColorData` actor manages emoji color information. It loads `colors.json` at runtime, which contains pre-computed color data for each emoji:

- **Mean color**: The average RGB color across all pixels in the emoji
- **Standard deviation**: How much the colors vary within the emoji

The standard deviation is used for coherency filtering—emoji with lower standard deviation have more uniform colors.

### Groups

The `Groups` actor manages Unicode emoji group classifications. It loads `groups.json` which maps group names (like "flags" or "food-drink") to the emoji characters in each group. This enables filtering emoji by category.

### libCommon

The `libCommon` module provides low-level utilities shared across the project:

- **Color**: A simple RGB color struct with components in the 0.0-1.0 range
- **PixelSequence**: Efficiently iterates through CGImage pixel data
- **ColorAlpha**: Handles pixels with alpha transparency, supporting premultiplication for accurate color matching

## Data Flow

When processing an image:

```
┌─────────────────────────────────────────────────────────────────────┐
│                           CIImage Input                             │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  Convert to CGImage via Core Image                  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│              Extract pixels using PixelSequence iterator            │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                     ┌──────────────┼──────────────┐
                     ▼              ▼              ▼
              ┌───────────┐  ┌───────────┐  ┌───────────┐
              │  Pixel 1  │  │  Pixel 2  │  │  Pixel N  │   (concurrent)
              └───────────┘  └───────────┘  └───────────┘
                     │              │              │
                     ▼              ▼              ▼
              ┌───────────────────────────────────────────┐
              │     Premultiply alpha with background     │
              └───────────────────────────────────────────┘
                                    │
                                    ▼
              ┌───────────────────────────────────────────┐
              │   Find closest emoji using color distance │
              └───────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│               Assemble emoji into rows with newlines                │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                           String Output                             │
└─────────────────────────────────────────────────────────────────────┘
```

## Color Matching Algorithm

The library uses a perceptually-weighted color distance formula based on human vision research. The formula accounts for the fact that humans perceive differences in certain colors more strongly than others:

- Green differences are weighted most heavily (factor of 4)
- Red and blue weights vary based on the average red value between colors
- For reddish colors, red differences are weighted more (3 vs 2)
- For non-reddish colors, blue differences are weighted more (3 vs 2)

This produces more visually accurate results than simple Euclidean distance in RGB space.

## Thread Safety

All mutable state is protected by Swift actors:

- ``EmojiArt`` is an actor, ensuring safe concurrent access to its properties
- `ColorData` and `Groups` are actors with shared singleton instances
- Pixel processing happens in a task group, allowing safe parallel execution

This design allows the library to efficiently use all available CPU cores when processing large images.
