# ``libHearts``

Generate emoji-art from images using Apple's emoji set.

## Overview

libHearts transforms images into emoji-art by analyzing each pixel and finding the emoji with the closest matching color. The library uses pre-computed color data from Apple's emoji font to ensure accurate color matching.

```swift
import libHearts

let emojiArt = try await EmojiArt()
let result = try await emojiArt.process(image: myImage)
print(result)
```

The library supports multiple ways to select which emoji to use:

- **Color coherency filtering**: Only use emoji with uniform colors for cleaner output
- **Unicode emoji groups**: Use emoji from specific categories like "flags" or "food-drink"
- **Custom sets**: Provide your own set of emoji characters

## Topics

### Essentials

- <doc:GettingStarted>
- ``EmojiArt``

### Selecting Emoji

- <doc:ChoosingEmoji>

### Understanding the Library

- <doc:Architecture>

### Errors

- ``Error``
