#!/usr/bin/env ruby
require 'optparse'

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: format.rb [options] input output"
  opts.separator "Note: With no options, format.rb formats all files with a filetype it understands that have staged git changes."
  opts.on("-a", "--all", "Format or check all files under format.rb's jurisdiction.") {|a| options[:all] = a}
  opts.on("-i", "--include-unstaged", "Include files with unstaged changes in addition to those with staged changes") {|i| options[:include_unstaged] = i}
  opts.on("-c", "--check", "Don't actually modify files, just throw an error if incorrect formatting is found.") {|c| options[:check] = c}
end

# Parse arguments and deal with exceptions.
begin
  unparsed = optparse.parse!
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse
  exit(2)
end

$line_pointer = 0
$lines = []

def parse_line(line) 
  case line
  when /@property/
    return format_property(line)
  else
    return line
  end
end

def format_property(line)
end

input_file_name = unparsed.first
output_file_name = unparsed.last

output_file = File.new output_file_name, "w"


File.open(input_file_name) do |file|
  $lines = file.readlines
  while $line_pointer < $lines.count
    output_file.write parse_line $lines[$line_pointer]
    $line_pointer += 1
  end
end

output_file.close
