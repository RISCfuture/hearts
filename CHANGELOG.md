# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Require Swift 6.4 and macOS 27.
- Adopt strict memory safety.
- Build, test, and release on the Xcode 27 runner image.
- Decode video with the asset reader's provider API.
- Write tests with Swift Testing instead of Quick and Nimble.
- Track generation progress with Foundation instead of the Progress.swift package.

## [1.0.0] - 2026-09-15

### Added

- Render a local or web-accessible image as emoji art in the terminal.
- Play a local video file as emoji art, sized to fit and paced to the video's
  frame rate, dropping frames rather than slowing playback.
- `--width` to resize the image or video to a given character width.
- `--coherency` to set how monochrome an emoji must be before it is eligible.
- `--only` to restrict the palette to the emoji in a given string or to a named
  emoji group, such as `flags`.
- `--background` to pick the background color the art is expected to be viewed
  against, so emoji colors are calculated for it.
- `--glyph-count` to report how many emoji the current `--coherency` and
  `--only` settings select from, without loading the image.

[Unreleased]: https://github.com/RISCfuture/hearts/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/RISCfuture/hearts/releases/tag/v1.0.0
