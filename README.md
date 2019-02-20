Hearts.rb
=========

Generates images made of emoji hearts.

Installation
------------

This script requires ImageMagick. For macOS, you can run
`brew install imagemagick`.

Run `bundle` in the project directory to install required gems.

Usage
-----

``` sh
ruby hearts.rb path/to/file.jpg
ruby hearts.rb https://placekitten.com/200/300
```

### Options

`-r`: Pass an [ImageMagick geometry string](https://imagemagick.org/script/command-line-processing.php#geometry)
to resize the output before generating hearts. Otherwise it will be one heart
per pixel of the original image!
