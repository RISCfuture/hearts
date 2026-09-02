# Architecture

Understand how libHearts processes images and generates emoji-art.

## Overview

libHearts uses a layered architecture with a Swift actor at the top for thread-safe concurrent processing. The library processes images in parallel, rendering bands of rows simultaneously to maximize performance.

![The architecture of libHearts showing the CLI layer, library layer, common utilities, and bundled resources](architecture.png)

## Components

### EmojiArt

``EmojiArt`` is the main entry point and orchestrator. When you call ``EmojiArt/process(image:)``, it:

1. Extracts pixels from the input `CIImage`
2. Splits the rows into bands, one per processor core, and renders the bands concurrently
3. For each pixel, finds the emoji with the closest matching color, reusing the answer for colors already seen in that band
4. Assembles the results into a string with newlines for each row

### Palette

`Palette` holds the emoji chosen for an ``EmojiArt`` instance alongside their mean colors, sorted by character so nearest-color ties resolve deterministically. It performs the color matching for each pixel.

### ColorData

`ColorData` provides emoji color information. It loads `colors.json` at startup, which contains pre-computed color data for each emoji:

- **Mean color**: The average RGB color across all pixels in the emoji
- **Standard deviation**: How much the colors vary within the emoji

The standard deviation is used for coherency filtering—emoji with lower standard deviation have more uniform colors.

### Groups

`Groups` provides Unicode emoji group classifications. It loads `groups.json` which maps group names (like "flags" or "food-drink") to the emoji characters in each group. This enables filtering emoji by category.

### VideoFrames and RealtimeSequence

``VideoInfo`` reads a local video file's display size and orientation. ``VideoFrames`` decodes the file with `AVAssetReader`, one frame per request, at the size the caller intends to render, rotating each frame into its display orientation. ``RealtimeSequence`` wraps any sequence of ``TimedFrame`` values and delivers each one at its presentation time, skipping frames whose time has already passed. ``EmojiArt/frames(of:width:clock:)`` converts each decoded frame with ``EmojiArt/process(image:)`` and then paces the rendered ``EmojiFrame`` values, so a frame is held until it is due with its emoji already in hand.

### libCommon

The `libCommon` module provides low-level utilities shared across the project:

- **Color**: A simple RGB color struct with components in the 0.0-1.0 range
- **PixelSequence**: Efficiently iterates through CGImage pixel data
- **ColorAlpha**: Handles pixels with alpha transparency, supporting premultiplication for accurate color matching

## Data Flow

When processing an image:

```text
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
              │  Band 1   │  │  Band 2   │  │  Band N   │   (concurrent)
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

- ``EmojiArt`` is an actor, ensuring safe concurrent access to its properties
- `Palette`, `ColorData`, and `Groups` are immutable `Sendable` values, so they can be read from any task without synchronization
- Pixel processing happens in a task group, allowing safe parallel execution
- ``VideoFrames`` confines its `AVAssetReader` to the iterator that owns it, so decoding never crosses an isolation boundary

This design allows the library to efficiently use all available CPU cores when processing large images.
