#!/usr/bin/env ruby
require 'optparse'

options = {}
optparse = OptionParser.new do |opts|
end

# Parse arguments and deal with exceptions.
begin
  unparsed = optparse.parse!
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse
  exit(2)
end

$attributes_group = '\((.*?)\)'
$name_and_type_group = '(.*)'
$comment_group = '(\/?\/? .*)'

def parse_line(line) 
  case line
  when / ^ \s* @property \s* #{$attributes_group} \s* #{$name_and_type_group} ; #{$comment_group}/x
    return format_property line, Regexp.last_match
  when / ^ \s* [+-] \s* \( .+ \) \s* .+ /x
    return format_method line, Regexp.last_match
  else
    return line
  end
end

def compress_whitespace(string)
  string.gsub /\s+/, " "
end


def format_property(line, match_data)
  
  property_attribute_order = ["atomic", "nonatomic", "strong", "weak", "assign", "copy", "readonly", "readwrite"]

  # Extract and sort property attributes
  attributes_array = match_data[1].split(",").collect do |a|
    a.strip
  end.sort do |a, b|
    (property_attribute_order.index(a) || 9999) <=> (property_attribute_order.index(b) || 9999)
  end
  attributes_string = attributes_array.join ", "

  # Extract name and type
  name_and_type_string = compress_whitespace match_data[2].strip
  # Remove any spaces after asterisks
  name_and_type_string.gsub! /\s* \* \s*/x, " *"

  # Extract comment
  comment_string = match_data[3].strip
  
  return "@property \(#{attributes_string}\) #{name_and_type_string}; #{comment_string}\n"
end

def format_method(line, match_data)
  line = compress_whitespace line

  # Strip space around parens, colon, and semicolon
  line.gsub! /\s* ([():;]) \s*/x, '\1'
  # Format plus or minus
  # Whitespace between '+/-' and '(' will have just been removed.
  line.gsub! /\s* [+-] \( /x, '- ('
  # Fix space around asterisk
  line.gsub! /([^*\s\t\r\n\f]) \s* \* \s*/x, '\1 *'
  
  return line
end 

input_file_name = unparsed.first
output_file_name = unparsed.last

output_file = File.new output_file_name, "w"

File.open(input_file_name) do |file|
  file.each_line do |line|
    new_line = parse_line line
    output_file.write new_line if new_line
  end
end

