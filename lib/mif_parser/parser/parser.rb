# frozen_string_literal: true

require_relative "document_parser"

module MifParser
  # Public parse entry. Reads MIF into a Document of Paragraph, List, Table, and Image.
  #
  # syntax/            tokens, escapes, block nesting
  # document_parser.rb orchestrates MIF statements
  # catalog_parser.rb  <PgfCatalog> paragraph formats
  # paragraph_parser.rb <Para>, tags, text, table/frame anchors, font runs
  # table_parser.rb     <Tbl>, rows, cells, anchor resolution
  # frame_parser.rb     <Frame>, <ImportObject>, <AFrame> resolution
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
