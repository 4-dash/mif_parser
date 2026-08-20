require_relative "lib/mif_parser"

input_file  = ARGV[0] || "test/fixtures/realtest.mif"
output_file = ARGV[1] || "output.txt"

File.open(input_file, "r:UTF-8") do |file|
  document = MifParser.parse(file)

  File.open(output_file, "w:UTF-8") do |out|
    out.puts "MIF PARSER OUTPUT"
    out.puts "=" * 100
    out.puts

    document.each_with_index do |paragraph, index|
      out.puts "[#{index + 1}]"
      out.puts "tag:           #{paragraph.tag.inspect}"
      out.puts "heading:       #{paragraph.heading?}"
      out.puts "heading_level: #{paragraph.heading_level.inspect}"
      out.puts "list:          #{paragraph.list?}"
      out.puts "list_level:    #{paragraph.interpret.list_level.inspect}"
      out.puts "list_marker:   #{paragraph.interpret.list_marker.inspect}"
      out.puts "text:          #{paragraph.text.inspect}"
      out.puts "import_text:   #{paragraph.import_text.inspect}"
      out.puts
    end

    out.puts "=" * 100
    out.puts "TOTAL: #{document.size}"
  end

  puts "Done."
  puts "#{document.size} paragraphs parsed."
  puts "See #{output_file}"
end