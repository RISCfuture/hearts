# Choosing Emoji

Control which emoji are used to generate your emoji-art.

## Overview

By default, ``EmojiArt`` uses a curated set of emoji that have relatively uniform colors. You can customize this selection to achieve different visual effects or to use only specific emoji.

## Color Coherency

Color coherency measures how uniform an emoji's colors are. Emoji with high coherency (like solid-colored hearts) produce cleaner-looking output, while emoji with low coherency (like faces with multiple colors) can make the output harder to recognize.

The ``EmojiArt/defaultCoherency`` value of `0.2` provides a good balance. Lower values are stricter (fewer emoji, cleaner output), while higher values include more emoji variety:

```swift
// Strict: Only very uniform emoji
let strict = try await EmojiArt(coherency: 0.1)

// Permissive: Include more varied emoji
let permissive = try await EmojiArt(coherency: 0.5)
```

## Unicode Emoji Groups

You can select emoji by their Unicode classification. This is useful for thematic images:

```swift
// Use flag emoji for patriotic images
let flags = try await EmojiArt(group: "flags")

// Use food emoji
let food = try await EmojiArt(group: "food-drink")

// Combine multiple groups
let nature = try await EmojiArt(groups: ["animals-nature", "travel-places"])
```

### Available Groups

The available groups correspond to the Unicode emoji specification groups and subgroups. Common groups include:

| Group | Description |
|-------|-------------|
| `smileys-emotion` | Faces and emotional emoji |
| `people-body` | People, gestures, and body parts |
| `animals-nature` | Animals, plants, and nature |
| `food-drink` | Food and beverage emoji |
| `travel-places` | Locations, vehicles, and buildings |
| `activities` | Sports, games, and activities |
| `objects` | Common objects and tools |
| `symbols` | Signs, symbols, and shapes |
| `flags` | Country and regional flags |
| `hearts` | Heart emoji in various colors |

Subgroups are also available, like `cat-face` or `plant-flower`.

> Note: When using groups, the coherency filter is bypassed. All emoji in the selected groups are available, regardless of their color uniformity.

## Custom Emoji Sets

For complete control, provide your own set of emoji characters:

```swift
// Use only heart emoji
let hearts = try EmojiArt(characters: Set("❤️🧡💛💚💙💜🩷🤎🖤🤍"))

// Use a small custom set for a specific effect
let ocean = try EmojiArt(characters: Set("🌊💙🐟🐠🦈"))
```

> Important: All characters in the set must be valid emoji. Providing non-emoji characters throws ``Error/nonEmojiCharacter(_:)``. The character set must not be empty, or ``Error/noCharacters`` is thrown.

## Background Color Considerations

When your source image has transparency, set the background color to match where the output will be displayed:

```swift
let emojiArt = try await EmojiArt()

// For display on a white background
await emojiArt.setBackgroundColor(Color(red: 1, green: 1, blue: 1))

// For display on a dark background
await emojiArt.setBackgroundColor(Color(red: 0, green: 0, blue: 0))
```

This ensures transparent pixels are converted to emoji that blend well with your display background.
