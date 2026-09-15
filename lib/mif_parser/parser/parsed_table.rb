# frozen_string_literal: true

module MifParser
  class Parser
    class ParsedTable
      attr_accessor :id,
                    :tag,
                    :title,
                    :header_rows,
                    :body_rows,
                    :footer_rows,
                    :section

      def initialize
        @id = nil
        @tag = nil
        @title = []
        @header_rows = []
        @body_rows = []
        @footer_rows = []
        @section = :body
      end

      def section_rows
        case section
        when :header
          header_rows
        when :footer
          footer_rows
        else
          body_rows
        end
      end
    end

    class ParsedCell
      attr_accessor :elements

      def initialize
        @elements = []
      end
    end
  end
end
