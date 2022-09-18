require 'optparse'

require 'bundler'
Bundler.require
require 'active_support/core_ext/object/blank'

GROUPS = File.read('db/groups.txt').each_line.each_with_object({}) do |line, hsh|
  name, chars = line.split(' ')
  hsh[name]   = chars
end

options = {coherency: 0.2}
OptionParser.new do |opts|
  opts.banner = "Usage: hearts.rb [options] PATH_OR_URL"

  opts.on('-rSTRING', '--resize=STRING', "Resize image according to ImageMagick geometry") do |r|
    options[:resize] = r
  end

  opts.on('-cCOHERENCY', '--coherency=COHERENCY', Float, "Amount of monochrome required for an emoji to be used (lower is stricter, default 0.2)") do |c|
    c = 0.2 if c <= 0
    c = 1 if c > 1
    options[:coherency] = c
  end

  opts.on('-oSTRING', '--only=STRING', "Only include emoji from this string or group name (overrides -c)") do |o|
    options[:only] = if GROUPS.key?(o)
                       GROUPS[o]
                     else
                       o
                     end
  end
end.parse!

if ARGV.size != 1
  warn "Usage: hearts.rb [options] PATH_OR_URL"
  exit 1
end

EMOJI_COLORS = File.read('db/colors.txt').each_line.each_with_object({}) do |line, hsh|
  parts = line.split(' ')
  emoji = parts.first
  next(hsh) if options[:only].present? && !options[:only].include?(emoji)

  average_color = parts[1, 3].map(&:to_f)
  std_devs      = parts[4, 3].map(&:to_f)
  next(hsh) if !options[:only] && std_devs.any? { |d| d > options[:coherency] }

  hsh[emoji] = average_color.map { |c| (c * 256).to_i }
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
  EMOJI_COLORS.each do |heart, heart_color|
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
