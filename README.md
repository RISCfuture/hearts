Hearts
======

Generates images made of emoji characters ("emoji-art").

Installation
------------

This script uses Swift 6 and Swift Package Manager. Run `swift build` to build
all targets.

Usage
-----

Basic example:

``` sh
swift run Hearts -w 80 https://placekitten.com/200/300
```

This will generate an 80-character-wide emoji-art version of a local or
web-accessible image.

![Output preview](https://i.imgur.com/GbWvQms.png)

``` sh
swift run Hearts -w 80 --only ❤️🧡💛💚💙💜🩷🤎🖤🤍 /System/Library/Desktop\ Pictures/Ventura\ Graphic.heic
```

Generates an emoji-art image using only heart emoji.

![Output preview](https://i.imgur.com/81kyXtd.png)

``` sh
swift run Hearts -w 80 --only flags https://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/1235px-Flag_of_the_United_States.svg.png
```

Generates an emoji-art image of the US flags using flag emoji. Note that, when
using groups, the amount of monochromacy is ignored, and emoji with large color
variety can be used, instead of just emoji with more generally uniform color.

![Output preview](https://i.imgur.com/DgkAGRB.png)

### Options

```
USAGE: hearts [--width <width>] [--coherency <coherency>] [--only <only>]
    [--background <background>] [--glyph-count] <file>

ARGUMENTS:
  <file>                  The image file or URL to process

OPTIONS:
  -w, --width <width>     Resize image to the given width (in pixels)
  -c, --coherency <coherency>
                          Amount of monochrome required for an emoji to be used
                          (lower is stricter)
  -o, --only <only>       Only include emoji from this string or group name
                          (overrides -c)
  -b, --background <background>
                          The background color to use when calculating emoji
                          color values, as 3 floats. This is the background
                          color that the resulting emoji-art will look best
                          against. (example: “0,0.5,1”)
  -g, --glyph-count       Does not process or load the image; instead, returns
                          the number of emoji that would be selected from,
                          given the values of --coherency and --only.
  -h, --help              Show help information.

```

### Helper Tasks

* `swift run GenerateCharacters`: Generates the `characters.txt` file used by
  `GenerateColors`. You can specify the Emoji version to use.
* `swift run GenerateColors`: Generates the `colors.json` file used by Hearts.
* `swift run GenerateGroups`: Generates the `groups.json` file used by Hearts.
  You can specify the Emoji version to use.

### Display Issues

Like with ASCII art, proper display of the resulting image is heavily dependent
on how the text is rendered on the viewer's platform. In particular:

* The emoji must be rendered as fixed-width characters. Not all platforms do
  this for all font configurations.
* The emoji must be rendered as square. Some platforms will use line heights
  different from character widths.
* The color values are calculated from Apple's emoji images in their proprietary
  font. Other platforms' emoji may have entirely different colors.
* Not every platform supports some of the newer complex emoji created using
  zwjs. On these platforms, the emoji will be displayed "decomposed" (e.g.,
  man + woman + child instead of the single man-woman-child emoji), which will
  mess up the fixed-width alignment.
