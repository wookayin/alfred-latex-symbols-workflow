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
query = query.downcase

Alfred.with_friendly_error do |alfred|
  fb = alfred.feedback

  filtered_symbols = Latex::Symbol::ExtendedList.reject do |k, v|
    not v.command.downcase.start_with? ('\\' + query)
  end # as hash

  # Print all prefix-matched symbols
  filtered_symbols.each do |k, v|
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
