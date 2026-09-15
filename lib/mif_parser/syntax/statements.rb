# frozen_string_literal: true

module MifParser
  module Syntax
    # One MIF token: an opener (`<Para`), a complete statement (`<TblID 1>`),
    # or a closer (`>`).
    class Statement
      attr_reader :text

      def initialize(text)
        @text = text
      end

      def close?
        text == ">"
      end

      def complete?
        !close? && text.end_with?(">")
      end

      def open?
        !close? && !complete?
      end

      def tag
        match = text.match(/\A<([A-Za-z][A-Za-z0-9]*)/)
        match && match[1]
      end
    end

    # Splits a physical line into MIF statements so inline markup
    # (`<Cell <Para … > >`) is parsed like pretty-printed MIF.
    module Statements
      extend self

      def parse_line(line)
        statements = []
        index = 0
        length = line.length

        while index < length
          index += 1 while index < length && whitespace?(line[index])
          break if index >= length
          break if line[index] == "#"

          if line[index] == ">"
            statements << Statement.new(">")
            index += 1
            next
          end

          unless line[index] == "<"
            index += 1
            next
          end

          start = index
          index += 1
          index += 1 while index < length && tag_char?(line[index])

          while index < length
            if line[index] == "`"
              index = skip_mif_string(line, index)
              next
            end

            break if line[index] == "<"

            if line[index] == ">"
              index += 1
              break
            end

            index += 1
          end

          text = line[start...index].strip
          statements << Statement.new(text) unless text.empty?
        end

        statements
      end

      private

      def whitespace?(char)
        char == " " || char == "\t"
      end

      def tag_char?(char)
        char.match?(/[A-Za-z0-9]/)
      end

      def skip_mif_string(line, index)
        index += 1

        while index < line.length
          if line[index] == "\\"
            index += 2
            next
          end

          return index + 1 if line[index] == "'"

          index += 1
        end

        index
      end
    end
  end
end
