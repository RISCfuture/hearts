require 'optparse'

require 'bundler'
Bundler.require

options = Hash.new
OptionParser.new do |opts|
  opts.banner = "Usage: hearts.rb [options] PATH_OR_URL"

  opts.on('-rSTRING', '--resize=STRING', 'Resize image according to ImageMagick geometry') do |r|
    options[:resize] = r
  end
end.parse!

if ARGV.size != 1
  warn "Usage: hearts.rb [options] PATH_OR_URL"
  exit 1
end


HEARTS = File.read('hearts.txt').each_line.inject({}) do |hsh, line|
  parts = line.split(' ')
  hsh[parts.first] = parts[1..-1].map(&:to_i)
  hsh
end.freeze

# https://en.wikipedia.org/wiki/Color_difference
def color_distance(r1, g1, b1, r2, g2, b2)
  r_bar = (r1 + r2) / 2.0
  dr    = r1 - r2
  dg    = g1 - g2
  db    = b1 - b2
  Math.sqrt((2 + r_bar / 256) * (dr ** 2) + 4 * (dg ** 2) + (2 + (255 - r_bar) / 256) * (db ** 2))
  # Math.sqrt(dr**2 + dg**2 + db**2)
end

def closest_heart(color)
  closest_heart = nil
  HEARTS.each do |heart, heart_color|
    distance = color_distance(*color, *heart_color)
    if closest_heart
      closest_heart = [heart, distance] if distance < closest_heart.last
    else
      closest_heart = [heart, distance]
    end
  end

  return closest_heart.first
end

image = MiniMagick::Image.open(ARGV.first)
image.resize(options[:resize]) if options[:resize]
pixels = image.get_pixels
pixels.each do |row|
  row.each do |column|
    print closest_heart(column)
  end
  print "\n"
end

$stdout.flush
