# frozen_string_literal: true

ZWJ                = 0x200d
VARIATION_SELECTOR = 0xfe0f

SEQUENCES = File.read("db/sequences.txt").each_line.each_with_object({}) do |line, hsh|
  emoji, *codepoints = line.split

  codepoints.map!(&:hex)
  codepoints.delete ZWJ
  codepoints.delete VARIATION_SELECTOR

  raise "Duplicate codepoints #{codepoints.map { |c| c.to_s(16) }.join(" ")}" if hsh.key?(codepoints)

  hsh[codepoints] = emoji
end

namespace :colors do
  desc "Regenerate the colors.txt file"
  task :generate do
    require "pathname"

    require "bundler"
    Bundler.require
    require "emoji/cli"

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
          dr += ((r / 256.0) - rm) ** 2
          dg += ((g / 256.0) - gm) ** 2
          db += ((b / 256.0) - bm) ** 2
        end
      end

      # standard deviations
      rsd = Math.sqrt(dr / (count - 1))
      gsd = Math.sqrt(dg / (count - 1))
      bsd = Math.sqrt(db / (count - 1))

      return [rm, gm, bm], [rsd, gsd, bsd]
    end

    def emoji_for_codepoints(codepoints)
      return codepoints.pack("U") if codepoints.size == 1
      raise "Unknown emoji #{codepoints.map { |c| c.to_s(16) }.join(" ")}" unless SEQUENCES.key?(codepoints)

      return SEQUENCES[codepoints]
    end

    Emoji::CLI.extract(%w[images])

    File.open("db/colors.txt", "w") do |db|
      Pathname("images/unicode").each_child do |image_path|
        codepoints = image_path.basename(".png").to_s.split("-")
        codepoints.map!(&:hex)

        emoji = emoji_for_codepoints(codepoints)

        image                  = MiniMagick::Image.open(image_path.to_s)
        average_color, std_dev = average_colors(image)
        db.puts [emoji, *average_color, *std_dev].join(" ")
      end
    end

    system "rm", "-rf", "images"
  end
end
