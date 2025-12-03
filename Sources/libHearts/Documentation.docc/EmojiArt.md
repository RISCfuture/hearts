# ``libHearts/EmojiArt``

The main actor for generating emoji-art from images.

## Overview

``EmojiArt`` analyzes images pixel-by-pixel and replaces each pixel with an emoji whose average color best matches the pixel's color. The actor model ensures thread-safe operation when processing images concurrently.

### Basic Usage

Create an instance with default settings and process an image:

```swift
let emojiArt = try await EmojiArt()
let result = try await emojiArt.process(image: myCIImage)
```

### Customizing Emoji Selection

You can control which emoji are used in several ways:

```swift
// Use only emoji with highly uniform colors
let strict = try await EmojiArt(coherency: 0.1)

// Use emoji from a specific Unicode group
let flags = try await EmojiArt(group: "flags")

// Use a custom set of emoji
let hearts = try EmojiArt(characters: Set("❤️🧡💛💚💙💜"))
```

### Background Color

When processing images with transparency, set the background color to match where the output will be displayed:

```swift
let emojiArt = try await EmojiArt()
await emojiArt.setBackgroundColor(Color(red: 1, green: 1, blue: 1)) // White background
```

## Topics

### Creating an Instance

- ``init(coherency:)``
- ``init(characters:)``
- ``init(group:)``
- ``init(groups:)``

### Configuring Output

- ``backgroundColor``
- ``setBackgroundColor(_:)``

### Processing Images

- ``process(image:)``

### Configuration Constants

- ``defaultCoherency``

### Available Emoji

- ``characters``
