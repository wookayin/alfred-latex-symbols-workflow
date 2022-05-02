#!/usr/bin/env ruby

# generate_icons.rb
#
# Generates 64x64 icon for each LaTeX symbol command
# Lots of code originates from kirel/detexify (lib/rake/symbol_task.rb)
#
# @author Jongwook Choi <wookayin@gmail.com>
# @author Daniel Kirsch <danishkirel@gmail.com>

require 'fileutils'
require 'tmpdir'
require 'shellwords'
require 'thread'
require 'rake/tasklib'
require 'erb'
require 'parallel'   # gem install [--user-install] parallel

require_relative 'symbol'

OUTDIR = './icons'
FileUtils.mkdir_p OUTDIR

TEMPLATE = ERB.new <<-LATEX
  \\documentclass[10pt]{article}
  \\usepackage[utf8]{inputenc}
  \\usepackage{color}

  <%= @packages %>

  \\pagestyle{empty}
  \\begin{document}

  \\color{<%= @color %>}
  <%= @command %>

  \\end{document}
LATEX

# Library: symbol -> icon
def symbol_to_icon(symbol, color)
  Dir.mktmpdir do |tmpdir|
    tmpfile_basename = File.join(tmpdir, symbol.filename)

    # (1) define_single_tex_task
    t = "#{tmpfile_basename}.tex"
    open(t, 'w+') do |texfile|
        # setup variables
        @packages = ''
        @packages << "\\usepackage{#{symbol[:package]}}\n" if symbol[:package]
        @packages << "\\usepackage[#{symbol[:fontenc]}]{fontenc}\n" if symbol[:fontenc]
        @command = symbol.mathmode ? "$#{symbol.command}$" : symbol.command
        @color = color
        # write symbol to tempfile
        texfile.puts TEMPLATE.result(binding)
    end

    # (2) define_single_dvi_task
    t = "#{tmpfile_basename}.dvi"
    res = system "latex -interaction=batchmode -output-directory=#{tmpdir} #{File.join(tmpdir, symbol.filename)}.tex >/dev/null"
    if ! res
      raise "Major Failure creating dvi! (status = #{$?.exitstatus})"
    end

    # (3) define_single_image_task
    t = "#{File.join(OUTDIR, color, symbol.filename)}.png"
    dpi = ENV['DPI'] || 600
    gamma = ENV['GAMMA'] || 1

    res = system "dvipng -bg Transparent -T tight -v -D #{dpi} --gamma #{gamma} #{File.join(tmpdir, symbol.filename)}.dvi -o #{t} >/dev/null"
    if ! res
      raise "Major Failure creating image! (status = #{$?.exitstatus})"
    end

    # (4) adjust size and put it at center
    iconsize = ENV['ICONSIZE'] || '64x64'
    res = system "mogrify -resize '#{iconsize}\>' -extent '#{iconsize}' -background transparent -gravity center -format png #{t} > /dev/null"
    if ! res
      exitcode = $?.exitstatus
      FileUtils.rm(t) # delete raw png
      raise "Major Failure adjusting image! (status = #{exitcode})"
    end
  end

  # return filename of generated png
  return "#{File.join(OUTDIR, color, symbol.filename)}.png"
end


# flush stdout immediately
STDOUT.sync = true

n_symbols = Latex::Symbol::List.size
n_threads = 4
putslock = Mutex.new

Parallel.each_with_index(Latex::Symbol::List, :in_threads => n_threads) do |v, index|
  next unless v.command.start_with? '\\'

  ['white', 'black'].each do |color|
    uid = v.filename
    quote = (v.mathmode ? '$' : '')
    output_file = "#{OUTDIR}/#{color}/#{uid}.png".downcase # lowercase

    if File.exist?(output_file) then
      putslock.synchronize {
        puts "[#{index}/#{n_symbols}] #{v.command.ljust(20)} : #{output_file} (Skipped)"
      }
      next
    end

    generated_file = symbol_to_icon(v, color)
    raise unless generated_file == output_file

    putslock.synchronize {
      puts "[#{index}/#{n_symbols}] #{v.command.ljust(20)} : #{generated_file} was generated"
    }
  end

end
