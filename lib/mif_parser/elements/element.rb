# frozen_string_literal: true

require_relative "../format"
require_relative "../html_text"

module MifParser
  class Element
    attr_reader :tag, :format

    INTERPRETED_METHODS = %i[
      type
      text
      heading?
      body?
      list?
      table?
      heading_level
      list_level
      list_marker
      list_type
      cell?
    ].freeze

    def initialize(tag: nil, format: nil)
      @tag = tag
      @format = format || Format.new
    end

    def interpret(interpreter = Interpreter.default)
      interpreter.interpret(self)
    end

    INTERPRETED_METHODS.each do |method_name|
      define_method(method_name) do
        interpret.public_send(method_name)
      end
    end

    def import_text
      text.to_s.strip
    end

    alias clean_text import_text

    def html_text
      import_text
    end
  end
end
