# frozen_string_literal: true

module MifParser
  class List < Element
    attr_reader :number_string,
                :raw_text,
                :list_type,
                :list_level,
                :list_marker

    def initialize(
      text:,
      list_type:,
      tag: nil,
      number_string: nil,
      list_level: nil,
      list_marker: nil
    )
      super(tag: tag)

      @raw_text = text.to_s
      @number_string = number_string
      @list_type = list_type
      @list_level = list_level
      @list_marker = list_marker
    end
  end
end
