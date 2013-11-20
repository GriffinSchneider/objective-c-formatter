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
  p line
  case line
  when /^ \s* @property \s* #{$attributes_group} \s* #{$name_and_type_group} ; #{$comment_group} /x
    new_line = format_property line, Regexp.last_match
  when /^ \s* [+-] \s* \( .+ \) \s* .+ /x
    new_line =  format_method line, Regexp.last_match
  else
    new_line = line
  end
  
  return new_line.gsub(/\t/, "    ").rstrip + "\n"
end

def compress_whitespace(string)
  string.gsub /\s+/, " "
end

def format_property(line, match_data)
  property_attribute_order =
    ["atomic", "nonatomic", "strong",
     "weak", "unsafe_unretained" "assign",
     "copy", "readonly", "readwrite"]

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
  name_and_type_string.gsub! /\s* \* \s* /x, " *"

  # Extract comment
  comment_string = match_data[3].strip
  
  "@property (#{attributes_string}) #{name_and_type_string}; #{comment_string}\n"
end

def format_method(line, match_data)
  line = compress_whitespace line

  # If there's a comment at the end of the line, split it out and replace it later
  line_without_comment = line.split('//')[0].rstrip
  comment = line.split('//')[1]

  # Strip space around parens and colon
  line_without_comment.gsub! /\s* ([():]) \s* /x, '\1'
  
  # Format plus or minus
  # Whitespace between '+/-' and '(' will have just been removed.
  line_without_comment.gsub! /\s* ([+-]) \( /x, '\1 ('
  
  # Fix space around asterisk
  line_without_comment.gsub! /([^*\s\t\r\n\f]) \s* \* \s* /x, '\1 *'
  
  # Fix space around opening brace
  line_without_comment.gsub! /\s* { /x, ' {'
  
  # Strip space before semicolon
  line_without_comment.gsub! /\s* ; /x, ';'

  comment ? line_without_comment + " //" + comment : line_without_comment
end 

input_file_name = unparsed.first
output_file_name = unparsed.last

output_file = File.new output_file_name, "w"

output_file_text = ""
File.open(input_file_name) do |file|
  file.each_line do |line|
    new_line = parse_line line
    previous_line = output_file_text[(output_file_text.rindex("\n", -2) || -1)+1..-1] if output_file_text.length
    
    # If the line we're about to add contains only an opening brace and the line above
    # the lone brace doesn't end in a comment, then move the lone brace up to the line
    # where it belongs
    if new_line.strip == "{" and not previous_line.match /\/\//
      output_file_text.rstrip!
      output_file_text += " {\n"
    elsif new_line
      output_file_text += new_line
    end
  end
  
end

output_file.write output_file_text
output_file.close
