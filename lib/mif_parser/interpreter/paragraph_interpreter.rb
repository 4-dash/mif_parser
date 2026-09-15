# frozen_string_literal: true

require_relative "../classification/classification"
require_relative "result"

module MifParser
  class Interpreter
    # Decides whether a Paragraph is a heading or body text.
    class ParagraphInterpreter
      def initialize(numbered_headings:)
        @numbered_headings = numbered_headings
      end

      def interpret(paragraph)
        tag_level = heading_level_from_tag(paragraph.tag)

        #
        # Explicit heading style wins.
        #
        # Number syntax must not change
        # Heading2 into Heading1, etc.
        #
        if tag_level
          return Result.new(
            type: :heading,
            heading_level: tag_level,
            text: heading_text(paragraph.raw_text),
            source: paragraph
          )
        end

        if @numbered_headings
          result = interpret_numbered_heading(paragraph)
          return result if result
        end

        Result.new(
          type: :body,
          text: paragraph.raw_text.to_s.strip,
          source: paragraph
        )
      end

      private

      def interpret_numbered_heading(paragraph)
        return nil if paragraph.number_string.to_s.strip.empty?
        return nil if paragraph.raw_text.to_s.strip.empty?

        number = clean_number_string(paragraph.number_string)
        level = numbered_heading_level(number)
        return nil if level.nil?

        Result.new(
          type: :heading,
          heading_level: level,
          text: heading_text(paragraph.raw_text),
          source: paragraph
        )
      end

      #
      # Only hierarchical numeric markers
      # are inferred as headings without an
      # explicit heading style.
      #
      # Accepted:
      #
      #   1.1
      #   1.2
      #   1.2.
      #   1.2.3
      #
      # Not accepted as headings:
      #
      #   1
      #   1.
      #   1)
      #   (1)
      #
      # This prevents list numbering from
      # being consumed by heading detection.
      #
      def numbered_heading_level(number)
        match = number.match(/\A(\d+(?:\.\d+)+)\.?\z/)
        return nil unless match

        match[1].split(".").length - 1
      end

      def heading_text(raw_text)
        raw_text.to_s.strip
      end

      def clean_number_string(value)
        value.to_s.strip
      end

      def heading_level_from_tag(tag)
        Classification.heading_level_from_tag(tag)
      end
    end
  end
end
