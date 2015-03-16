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


query = ARGV[0]

Alfred.with_friendly_error do |alfred|
  fb = alfred.feedback

  # DUMMY
  fb.add_item({
    :uid => "",
    :title => query,
    :subtitle => "Subtitle " + query,
    :arg => "Notified " + query,
    :valid => "yes"
  })

  puts fb.to_xml(ARGV)
end
