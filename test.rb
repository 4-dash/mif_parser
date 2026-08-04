# test_manual.rb
require_relative "lib/mif_converter"

output = MifConverter.convert("spec/fixtures/sample.mif")

output_path = File.join(__dir__, "output.txt")
File.write(output_path, output)

puts "Written to #{output_path}"