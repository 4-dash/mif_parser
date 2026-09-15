# frozen_string_literal: true

require_relative "document_parser"

module MifParser
  # Public parse entry. Reads MIF into a Document of Paragraph, List, and Table.
  #
  # syntax/            tokens, escapes, block nesting
  # document_parser.rb orchestrates the line scan
  # paragraph_parser.rb <Para>, tags, text, table anchors
  # table_parser.rb     <Tbl>, rows, cells, anchor resolution
  # classification/     Paragraph vs List (MIF has no list construct)
  class Parser
    def initialize(input)
      @input = input
    end

    def parse
      DocumentParser.new(@input).parse
    end
  end
end
