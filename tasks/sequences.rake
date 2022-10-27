# frozen_string_literal: true

namespace :sequences do
  desc "Generates the sequences.txt database"
  task :generate do
    require "net/http"
    require "active_support/core_ext/object/blank"

    def download_sequences(db, url)
      Net::HTTP.get(url).each_line do |line|
        next if line.blank? || line.start_with?("#")

        codepoints = line.split(";").first.strip.split.map(&:hex)
        db.puts [codepoints.pack("U*").unicode_normalize, *codepoints.map { |c| c.to_s(16) }].join(" ")
      end
    end

    File.open("db/sequences.txt", "w") do |db|
      download_sequences db, URI.parse("https://unicode.org/Public/emoji/11.0/emoji-sequences.txt")
      download_sequences db, URI.parse("https://unicode.org/Public/emoji/11.0/emoji-zwj-sequences.txt")
    end
  end
end
