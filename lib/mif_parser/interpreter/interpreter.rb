# frozen_string_literal: true

require_relative "result"
require_relative "paragraph_interpreter"

module MifParser
  # Turns parsed Document elements into typed meaning.
  #
  # Paragraph -> heading or body
  # List      -> list result (ul/ol, level, marker already on the element)
  # Table     -> table result
  class Interpreter
    def self.default
      @default ||= new
    end

    def initialize(numbered_headings: true)
      @numbered_headings = numbered_headings
      @paragraph_interpreter = ParagraphInterpreter.new(
        numbered_headings: numbered_headings
      )
    end

    def interpret(element)
      case element
      when List
        Result.new(
          type: :list,
          text: element.raw_text.to_s.strip,
          list_type: element.list_type,
          list_level: element.list_level,
          list_marker: element.list_marker,
          source: element
        )
      when Paragraph
        @paragraph_interpreter.interpret(element)
      when Table
        Result.new(
          type: :table,
          rows: element.rows,
          source: element
        )
      else
        Result.new(
          type: :unknown,
          source: element
        )
      end
    end
  end
end
