# frozen_string_literal: true

module MifParser
  class Parser
    module ListParser
      COMMON_BULLET_MARKERS = %w[
        •
        ◦
        ▪
        ▫
        ‣
        ⁃
      ].freeze

      private

      def build_paragraph_element(
        tag:,
        number_string:,
        text:
      )
        marker =
          clean_list_marker(number_string)

        unless list_paragraph?(tag, marker)
          return Paragraph.new(
            tag: tag,
            number_string: number_string,
            text: text
          )
        end

        List.new(
          tag: tag,
          number_string: number_string,
          text: text,
          list_type:
            list_type_for(tag, marker),
          list_level:
            list_level_for(tag, marker),
          list_marker: marker
        )
      end

      def list_paragraph?(tag, marker)
        return false if marker.empty?

        list_like_tag?(tag) ||
          parenthesized_list_marker?(marker) ||
          unordered_list_marker?(marker)
      end

      def list_type_for(tag, marker)
        if unordered_list_tag?(tag) ||
           unordered_list_marker?(marker)
          :ul
        else
          :ol
        end
      end

      def list_level_for(tag, marker)
        if list_like_tag?(tag) ||
           unordered_list_marker?(marker)
          1
        else
          0
        end
      end

      def clean_list_marker(value)
        value.to_s.strip
      end

      def list_like_tag?(tag)
        value = tag.to_s.strip

        return false if value.empty?

        value.match?(
          /\b(?:list|numbered|bullet|ordered|unordered)\b/i
        ) ||
          short_list_tag?(value)
      end

      def unordered_list_tag?(tag)
        value = tag.to_s.strip

        return false if value.empty?

        value.match?(
          /\b(?:bullet|unordered)\b/i
        ) ||
          value.match?(
            /(?:\A|[\s:_-])ul(?:\z|[\s:_-])/i
          )
      end

      def short_list_tag?(value)
        value.match?(
          /(?:\A|[\s:_-])(?:ul|ol)(?:\z|[\s:_-])/i
        )
      end

      def unordered_list_marker?(marker)
        COMMON_BULLET_MARKERS.include?(marker)
      end

      def parenthesized_list_marker?(marker)
        marker.match?(
          /\A\(\d+(?:\.\d+)*\)\z/
        )
      end
    end
  end
end
