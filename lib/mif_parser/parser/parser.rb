# frozen_string_literal: true

require_relative "paragraph_parser"
require_relative "list_parser"
require_relative "table_parser"

module MifParser
  class Parser
    include ParagraphParser
    include ListParser
    include TableParser

    TableAnchor = Struct.new(:id)

    CHAR_MAP = {
      "Tab" => "\t",
      "HardReturn" => "\n",
      "HardSpace" => "\u00A0",
      "SoftHyphen" => "\u00AD",
      "DiscHyphen" => "\u00AD",
      "HardHyphen" => "\u2011",
      "EnDash" => "–",
      "EmDash" => "—",
      "Bullet" => "•",
      "Cent" => "¢",
      "Pound" => "£",
      "Yen" => "¥"
    }.freeze

    TEXT_TOKEN_RE =
      /<String\s+`((?:\\.|[^'])*)'>|<Char\s+([A-Za-z][A-Za-z0-9]*)>/

    def initialize(input)
      @input = input
      @block_stack = []
    end

    def parse
      @elements = []
      @tables = {}

      @current_para = nil
      @current_tag = nil

      @current_table = nil
      @current_row = nil
      @current_cell = nil

      each_line do |raw_line|
        line = raw_line.strip

        next if line.empty?
        next if comment?(line)

        closed_block = update_block_stack(line)

        #
        # Table definition
        #

        if table_start?(line)
          start_table
          next
        end

        if @current_table
          parse_table_line(line, closed_block)
          next
        end

        #
        # Normal document paragraphs
        #

        if paragraph_start?(line)
          start_paragraph
          next
        end

        next unless @current_para

        parse_paragraph_line(line, closed_block)
      end

      if @current_para
        append_paragraph_elements(
          @elements,
          @current_para
        )
      end

      Document.new(
        resolve_table_anchors(@elements, @tables)
      )
    end

    private

    def each_line(&block)
      if @input.respond_to?(:each_line)
        @input.each_line(&block)
      else
        @input.to_s.each_line(&block)
      end
    end

    def comment?(line)
      line.start_with?("#")
    end

    def update_block_stack(line)
      return @block_stack.pop if line.start_with?(">")

      match = line.match(
        /\A<([A-Za-z][A-Za-z0-9]*)\b/
      )

      return nil unless match

      @block_stack << match[1] unless line.match?(/>\s*(?:#.*)?\z/)

      nil
    end

    def block_closed?(closed_block, name)
      !closed_block.nil? &&
        closed_block.casecmp?(name)
    end

    def parse_text_tokens(line, container)
      line.scan(TEXT_TOKEN_RE) do |string_value, char_name|
        if string_value
          container[:strings] <<
            decode_string(string_value)

        elsif char_name
          value = CHAR_MAP[char_name]

          container[:strings] << value if value
        end
      end
    end

    def decode_string(value)
      value.to_s.gsub(/\\(.)/m) do
        escaped = Regexp.last_match(1)

        case escaped
        when "t"
          "\t"

        when ">"
          ">"

        when "q", "'"
          "'"

        when "Q", "`"
          "`"

        when "\\"
          "\\"

        else
          "\\#{escaped}"
        end
      end
    end
  end
end
