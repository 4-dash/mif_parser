# frozen_string_literal: true

module MifParser
  class Element
    attr_reader :tag

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
    ].freeze

    def initialize(tag: nil)
      @tag = tag
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
  end
end
