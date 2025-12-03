# Getting Started with libHearts

Learn how to generate emoji-art from images.

## Overview

libHearts converts images into strings of emoji characters, where each emoji represents a single pixel from the source image. The library matches pixels to emoji by comparing colors, resulting in a recognizable reproduction of the original image using only emoji.

## Adding libHearts to Your Project

Add libHearts as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/RISCfuture/hearts.git", from: "1.0.0")
]
```

Then add it to your target's dependencies:

```swift
.target(
    name: "MyApp",
    dependencies: ["libHearts"]
)
```

## Creating Your First Emoji-Art

Import the library and create an ``EmojiArt`` instance:

```swift
import libHearts
import CoreImage

// Load an image
guard let image = CIImage(contentsOf: imageURL) else {
    fatalError("Could not load image")
}

// Create the emoji-art generator with default settings
let emojiArt = try await EmojiArt()

// Process the image
let result = try await emojiArt.process(image: image)

// Print the result
print(result)
```

## Scaling Your Image

The library doesn't automatically resize images. Each pixel becomes one emoji character, so you'll typically want to scale your image down first. A width of 40-80 characters usually works well:

```swift
import CoreImage

func resize(image: CIImage, width: Double) -> CIImage {
    let scale = width / image.extent.width
    let aspectRatio = image.extent.width / image.extent.height

    return image.applyingFilter(
        "CILanczosScaleTransform",
        parameters: [
            kCIInputScaleKey: scale,
            kCIInputAspectRatioKey: aspectRatio
        ]
    )
}

let scaledImage = resize(image: originalImage, width: 60)
let result = try await emojiArt.process(image: scaledImage)
```

## Next Steps

- Learn how to select specific emoji in <doc:ChoosingEmoji>
- Understand the library's architecture in <doc:Architecture>
