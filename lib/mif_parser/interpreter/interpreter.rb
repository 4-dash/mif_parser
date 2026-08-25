# frozen_string_literal: true

require_relative "paragraph_interpreter"
require_relative "table_interpreter"

module MifParser
  class Interpreter
    include ParagraphInterpreter
    include TableInterpreter

    Result = Struct.new(
      :type,
      :text,
      :heading_level,
      :list_level,
      :list_marker,
      :rows,
      :source,
      keyword_init: true
    ) do
      def heading?
        type == :heading
      end

      def body?
        type == :body
      end

      def list?
        type == :list
      end

      def table?
        type == :table
      end
    end

    def self.default
      @default ||= new
    end

    def initialize(numbered_headings: true)
      @numbered_headings = numbered_headings
    end

    def interpret(element)
      case element
      when Paragraph
        interpret_paragraph(element)

      when Table
        interpret_table(element)

      else
        Result.new(
          type: :unknown,
          source: element
        )
      end
    end
  end
end
