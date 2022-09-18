namespace :colors do
  desc "Regenerate the colors.txt file"
  task :generate do
    require 'pathname'

    require 'bundler'
    Bundler.require
    require 'emoji/cli'

    class Array
      def intersperse!(obj)
        (size - 1).downto(1) do |i|
          insert i, obj
        end
      end
    end

    def average_colors(image)
      # total # of samples
      count = 0
      # sum of red, green, blue
      rs = 0
      gs = 0
      bs = 0

      image.get_pixels.each do |row|
        row.each do |(r, g, b)|
          count += 1
          rs    += r / 256.0
          gs    += g / 256.0
          bs    += b / 256.0
        end
      end

      # mean values of red, green, blue
      rm = rs / count
      gm = gs / count
      bm = bs / count
      # mean squared deviations of red, green, blue
      dr = 0
      dg = 0
      db = 0

      image.get_pixels.each do |row|
        row.each do |(r, g, b)|
          dr += (r / 256.0 - rm) ** 2
          dg += (g / 256.0 - gm) ** 2
          db += (b / 256.0 - bm) ** 2
        end
      end

      # standard deviations
      rsd = Math.sqrt(dr / (count - 1))
      gsd = Math.sqrt(dg / (count - 1))
      bsd = Math.sqrt(db / (count - 1))

      return [rm, gm, bm], [rsd, gsd, bsd]
    end

    Emoji::CLI.extract(%w[images])

    File.open('colors.txt', 'w') do |db|
      Pathname('images/unicode').each_child do |image_path|
        codepoints = image_path.basename('.png').to_s.split('-')
        codepoints.map!(&:hex)
        non_joined_emoji = codepoints.pack('U*').unicode_normalize

        codepoints.intersperse! 0x200d # add combiners
        joined_emoji = codepoints.pack('U*').unicode_normalize

        emoji = (non_joined_emoji.scan(Unicode::Emoji::REGEX_VALID_INCLUDE_TEXT).size == 1) ? non_joined_emoji : joined_emoji

        image                  = MiniMagick::Image.open(image_path.to_s)
        average_color, std_dev = average_colors(image)
        db.puts [emoji, *average_color, *std_dev].join(' ')
      end
    end

    system 'rm', '-rf', 'images'
  end
end
