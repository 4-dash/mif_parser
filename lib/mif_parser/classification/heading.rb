# frozen_string_literal: true

module MifParser
  module Classification
    # Decides whether a paragraph is a heading and at which 0-based level.
    module Heading
      extend self

      def heading_level_for(tag:, number_string: nil, raw_text: nil)
        tag_level = Tags.heading_level_from_tag(tag)
        return tag_level unless tag_level.nil?

        numbered_heading_level_for(
          number_string: number_string,
          raw_text: raw_text
        )
      end

      private

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
      def numbered_heading_level_for(number_string:, raw_text:)
        number = number_string.to_s.strip
        return nil if number.empty?
        return nil if raw_text.to_s.strip.empty?

        match = number.match(/\A(\d+(?:\.\d+)+)\.?\z/)
        return nil unless match

        match[1].split(".").length - 1
      end
    end
  end
end
