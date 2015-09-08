#!/usr/bin/env ruby
# encoding: utf-8

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
begin
  require_relative 'bundle/bundler/setup'
rescue LoadError
  # fall back to regular bundler if the developer hasn't bundled standalone
  require 'bundler'
  Bundler.setup
end
require "alfred"

# Load LaTeX symbols (Latex::Symbol)
require_relative 'symbol'

query = ARGV[0]
if query.nil? then query = '' end
query = Regexp.escape(query.downcase).delete('\\')
query_r = /#{query}/i

# Perform some math to understand if the color is light or dark
rawColors = ENV['alfred_theme_background']
splitColors = rawColors.split("rgba(")[1].split(")")[0].split(",")
redIntensity = splitColors[0].to_i
greenIntensity = splitColors[1].to_i
blueIntensity = splitColors[2].to_i
# Level of brightness. Taken from here: http://www.nbdtech.com/Blog/archive/2008/04/27/Calculating-the-Perceived-Brightness-of-a-Color.aspx
brightness =  0.241*redIntensity*redIntensity + 0.691*greenIntensity*greenIntensity + 0.068*blueIntensity*blueIntensity
# Check if theme is light
isLight = brightness > 130

Alfred.with_friendly_error do |alfred|
  # the matching procedure can be boosted up using efficient algorithms
  # such as trie, Aho-Corasick, etc., but naive ones work too :-)

  matched_symbols = Latex::Symbol::List.select { |v|
    vcd = v.command.downcase
    vcd.delete('\\').match(query_r)
  } .sort_by { |v|
    vcd = v.command.downcase.delete('\\')
    [vcd.start_with?(query) ? -1 : 1, vcd]
  }

  # Print all prefix-matched symbols
  fb = alfred.feedback
  matched_symbols.each do |v|
    uid = v.filename
    
    if isLight
      icon = {:name => "icons/#{uid}.png".downcase, :type => 'file'}
    else
      icon = {:name => "icons/#{uid}_white.png".downcase, :type => 'file'}
    end
    
    
    fb.add_item({
      :uid => uid,
      :title => v.command,
      :subtitle => [(v.package.nil? ? "" : "Package " + v.package),
                    (v.mathmode ? "(math mode)" : "")
                   ].join(' '),
      :arg => v.command,
      :icon => icon,
      :valid => "yes"
    })
  end

  puts fb.to_xml(ARGV)
end
