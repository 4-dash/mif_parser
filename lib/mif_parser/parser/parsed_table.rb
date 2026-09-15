# frozen_string_literal: true

module MifParser
  class Parser
    class ParsedTable
      attr_accessor :id, :tag, :rows

      def initialize
        @id = nil
        @tag = nil
        @rows = []
      end
    end

    class ParsedCell
      attr_accessor :strings, :paragraphs

      def initialize
        @strings = []
        @paragraphs = []
      end
    end
  end
end
