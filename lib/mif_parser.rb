require_relative "mif_parser/version"
require_relative "mif_parser/document"
require_relative "mif_parser/paragraph"
require_relative "mif_parser/parser"

module MifParser
  def self.parse(input)
    Parser.new(input).parse
  end
end