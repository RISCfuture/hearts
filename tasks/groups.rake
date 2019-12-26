namespace :groups do
  desc "Generates the groups.txt database"
  task :generate do
    require 'bundler'
    Bundler.require

    def combine_emoji_groups(category, subcategories)
      subcategories.each_with_object([]) do |subcategory, ary|
        ary.concat Unicode::Emoji.list(category, subcategory)
      end
    end

    def add_hardcoded_groups(db)
      db.puts "hearts \u{2764}\u{1f9e1}\u{1f49b}\u{1f49a}\u{1f499}\u{1f49c}\u{1f5a4}\u{1f90e}\u{1f90d}"
    end

    def add_emoji_gem_groups(db)
      people = combine_emoji_groups('People & Body',
                                    %w[person person-gesture person-role person-fantasy person-activity person-sport person-resting])
      db.puts('people ' + people.join)

      animals = combine_emoji_groups('Animals & Nature',
                                     %w[animal-mammal animal-bird animal-amphibian animal-reptile animal-marine animal-bug])
      db.puts('animals ' + animals.join)
      plants = combine_emoji_groups('Animals & Nature',
                                    %w[plant-flower plant-other])
      db.puts('plants ' + plants.join)
      db.puts('flowers ' + Unicode::Emoji.list('Animals & Nature', 'plant-flower').join)

      food_drink = Unicode::Emoji.list('Food & Drink').values.flatten - Unicode::Emoji.list('Food & Drink', 'dishware')
      db.puts('food-drink ' + food_drink.join)
      db.puts('food ' + (food_drink - Unicode::Emoji.list('Food & Drink', 'drink')).join)
      db.puts('drink ' + Unicode::Emoji.list('Food & Drink', 'drink').join)

      vehicles = combine_emoji_groups('Travel & Places', %w[transport-ground transport-water transport-air])
      "\u{1f68f}\u{1f6e3}\u{1f6e4}\u{1f6e2}\u{26fd}\u{1f6a8}\u{1f6a5}\u{1f6a6}\u{2693}".each_char do |c|
        vehicles.delete c
      end
      db.puts('vehicles ' + vehicles.join)

      db.puts('sports ' + Unicode::Emoji.list('Activities', 'sport').join)

      db.puts('clothes ' + Unicode::Emoji.list('Objects', 'clothing').join)

      db.puts('flags ' + Unicode::Emoji.list('Flags', 'country-flag').join)
    end

    File.open('db/groups.txt', 'w') do |db|
      add_hardcoded_groups(db)
      add_emoji_gem_groups(db)
    end
  end
end
