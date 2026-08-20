module MifParser
  class Paragraph < Element
    attr_reader :number_string, :raw_text

    def initialize(text:, tag: nil, number_string: nil)
      super(tag: tag)

      @raw_text = text.to_s
      @number_string = number_string
    end
  end
end