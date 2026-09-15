# frozen_string_literal: true

require_relative "mif_parser/version"

# Public document nodes
require_relative "mif_parser/elements/element"
require_relative "mif_parser/elements/paragraph"
require_relative "mif_parser/elements/list"
require_relative "mif_parser/elements/table"
require_relative "mif_parser/document"

# Meaning: heading vs body, typed list/table results
require_relative "mif_parser/interpreter/interpreter"

# Structure: MIF source -> Document (uses syntax/ and classification/)
require_relative "mif_parser/parser/parser"

module MifParser
  def self.parse(input)
    Parser.new(input).parse
  end
end
