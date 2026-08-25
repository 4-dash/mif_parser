#!/usr/bin/env ruby
# frozen_string_literal: true

# Usage: ruby script/inspect_mif.rb [mif_file_or_directory] [optional_output.json]

require "json"

require_relative "../lib/mif_parser"

input_path =
  ARGV[0] || "test/fixtures"

output_file =
  ARGV[1]

def normalize(value)
  case value
  when Symbol
    value.to_s

  when Array
    value.map do |item|
      normalize(item)
    end

  when Hash
    value.each_with_object({}) do |(key, item), result|
      result[key.to_s] =
        normalize(item)
    end

  else
    value
  end
end

def raw_attributes(element)
  element
    .instance_variables
    .sort
    .each_with_object({}) do |variable, result|
      name =
        variable
        .to_s
        .delete_prefix("@")

      result[name] =
        normalize(
          element.instance_variable_get(variable)
        )
    end
end

def interpreted_attributes(element)
  result = element.interpret

  result
    .to_h
    .reject do |key, _value|
      key == :source
    end
    .then do |attributes|
      normalize(attributes)
    end
end

def inspect_document(path)
  document =
    File.open(
      path,
      "r:UTF-8"
    ) do |file|
      MifParser.parse(file)
    end

  {
    "file" => path,
    "total" => document.size,

    "elements" =>
      document.each_with_index.map do |element, index|
        {
          "index" => index + 1,
          "class" => element.class.name,

          "raw" =>
            raw_attributes(element),

          "interpreted" =>
            interpreted_attributes(element)
        }
      end
  }
end

files =
  if File.directory?(input_path)
    Dir[
      File.join(
        input_path,
        "**",
        "*.mif"
      )
    ].sort
  else
    [input_path]
  end

abort "No MIF files found." if files.empty?

documents =
  files.map do |path|
    inspect_document(path)
  end

payload =
  if documents.length == 1
    documents.first
  else
    {
      "files" => documents.length,
      "documents" => documents
    }
  end

output =
  JSON.pretty_generate(payload)

if output_file
  File.write(
    output_file,
    "#{output}\n",
    mode: "w:UTF-8"
  )

  puts "Wrote #{output_file}"
else
  puts output
end
