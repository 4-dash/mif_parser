module MifParser
  class Paragraph
    attr_reader :tag, :number_string, :raw_text

    def initialize(text:, tag: nil, number_string: nil)
      @raw_text = text.to_s
      @tag = tag
      @number_string = number_string
    end

    def interpret(interpreter = Interpreter.default)
      interpreter.interpret(self)
    end

    def text
      interpret.text
    end

    def import_text
      text.strip
    end

    alias_method :clean_text, :import_text

    def heading?
      interpret.heading?
    end

    def body?
      interpret.body?
    end

    def list?
      interpret.list?
    end

    def heading_level
      interpret.heading_level
    end
  end
end