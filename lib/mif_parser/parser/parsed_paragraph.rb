# frozen_string_literal: true

module MifParser
  class Parser
    class ParsedParagraph
      attr_accessor :tag, :number_string, :strings, :parts

      def initialize(tag:)
        @tag = tag
        @number_string = nil
        @strings = []
        @parts = []
      end
    end
  end
end
