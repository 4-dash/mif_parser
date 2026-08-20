require_relative "mif_parser/version"

require_relative "mif_parser/elements/element"
require_relative "mif_parser/elements/paragraph"
require_relative "mif_parser/elements/table"

require_relative "mif_parser/document"
require_relative "mif_parser/interpreter"
require_relative "mif_parser/parser"

module MifParser
  def self.parse(input)
    Parser.new(input).parse
  end
end