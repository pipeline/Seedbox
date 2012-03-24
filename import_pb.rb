#!/usr/bin/env ruby

require './models.rb'
require 'pp'

# format: 3281929|MacGyver.S01E02.DVDRip.XviD-MEDiEVAL|376764032|1|0|6e43d748d9446e3cddec69ce9b2ababb51bbf827

count = 0

ArchivedTorrent.transaction do
  File.open(ARGV[0], "r") do |file|
    while(line = file.gets)
      line = line.chomp
      components = line.split '|'

      ArchivedTorrent.create(
        :piratebay_id => components[0].to_i,
        :name => components[1],
        :size => components[2].to_i,
        :popularity => components[3].to_i + components[4].to_i,
        :magnet => components[5]
      )

      count += 1
      puts "#{(count.to_f / 1643194.0)*100.0}%" if count % 1000 == 0
    end
  end
end

