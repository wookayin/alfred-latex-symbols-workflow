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
    fb.add_item({
      :uid => uid,
      :title => v.command,
      :subtitle => [(v.package.nil? ? "" : "Package " + v.package),
                    (v.mathmode ? "(math mode)" : "")
                   ].join(' '),
      :arg => v.command,
      :icon => {:name => "icons/#{uid}.png".downcase, :type => 'file'},
      :valid => "yes"
    })
  end

  puts fb.to_xml(ARGV)
end
