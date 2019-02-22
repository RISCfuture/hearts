Hearts.rb
=========

Generates images made of emoji characters ("emoji-art").

Installation
------------

This script requires ImageMagick. For macOS, you can run
`brew install imagemagick`.

Run `bundle` in the project directory to install required gems.

Usage
-----

Basic example:

``` sh
ruby hearts.rb -r80 https://placekitten.com/200/300
```

This will generate an 80-character-wide emoji-art version of a local or
web-accessible image.

![Output preview](https://i.imgur.com/fgJBiId.png)

``` sh
ruby hearts.rb -r80 -o❤️🧡💛💚💙💜🖤 /Library/Desktop\ Pictures/High\ Sierra.jpg
```

Generates an emoji-art image using only heart emoji.

![Output preview](https://i.imgur.com/5waeG1r.png)

``` sh
ruby hearts.rb -oflags -r80 https://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/1235px-Flag_of_the_United_States.svg.png
```

Generates an emoji-art image of the US flags using flag emoji. Note that, when
using groups, the amount of monochromacy is ignored, and emoji with large color
variety can be used, instead of just emoji with more generally uniform color.

![Output preview](https://i.imgur.com/P4MUaq1.png)

### Options

`-r`: Pass an [ImageMagick geometry string](https://imagemagick.org/script/command-line-processing.php#geometry)
to resize the output before generating text. Otherwise it will be one character
per pixel of the original image!

`-c`: Pass a number between 0 and 1 to customize how "color coherent" an emoji
must be to be used. Higher numbers will use emoji that have more color variety.
Default is 0.2.

`-o`: Pass a string of emoji characters, or a group name. Only characters from
this string or group will be used. Group names are listed in `db/groups.txt` and
include `flags`, `food`, and `hearts`, for example. Overrides `-c`.

### Files

`hearts.rb`: Generates emoji-art from the given options.

`db/colors.txt`: A space- and newline-delimited database with the following
values: emoji, average red, average green, average blue, standard deviation red,
standard deviation green, standard deviation blue.

`db/sequences.txt`: A space- and newline-delimited database with the proper
location of zero-width joiners ("zwjs") and variant characters to create
composite emoji (such as man + woman + child).

`db/groups.txt`: A space- and newline-delimited database of emoji group names.

### Rake Tasks

`rake colors:generate`: Generates the `colors.txt` file from the emoji image
data in the Gemoji gem.

`rake sequences:generate`: Generates the `sequences.txt` file from the Unicode
reference web site.

`rake groups:generate`: Generates the `groups.txt` file.

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
