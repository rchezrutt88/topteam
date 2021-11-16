#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/topteam"

lines = $stdin.readlines(chomp: true).reject { |line| line.strip.empty? }

season = Topteam::Season.new

season.add_games(lines) do |rankings, match_day|
  puts "Matchday #{match_day}"
  rankings.each do |ranking|
    puts "#{ranking.name}, #{ranking.score} pts"
  end
  puts "\n"
end
