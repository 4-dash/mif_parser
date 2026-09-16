# frozen_string_literal: true

require_relative "../elements/paragraph"
require_relative "../elements/list"
require_relative "../format"
require_relative "../text_run"

module MifParser
  module Classification
    # Turns one parsed paragraph into Paragraph or List (ul/ol, level, marker).
    module ListItem
      extend self

      def build(tag:, number_string:, text:, previous_element: nil, format: nil, runs: nil)
        marker = Classification.clean_marker(number_string)
        list_text = text.to_s
        format ||= Format.new
        runs ||= [
          TextRun.new(
            text: list_text,
            format: format
          )
        ]

        if marker.empty?
          extracted = extract_leading_list_marker(tag, list_text)

          if extracted
            marker = extracted[:marker]
            list_text = extracted[:text]
          end
        end

        unless list_paragraph?(tag, marker)
          return Paragraph.new(
            tag: tag,
            number_string: number_string,
            text: text,
            format: format,
            runs: runs
          )
        end

        List.new(
          tag: tag,
          number_string: number_string,
          text: list_text,
          format: format,
          runs: TextRun.drop_prefix(runs, text.to_s, list_text),
          list_type: list_type_for(tag, marker),
          list_level: list_level_for(
            tag,
            marker,
            previous_element: previous_element
          ),
          list_marker: marker
        )
      end

      def list_paragraph?(tag, marker)
        return false if marker.empty?

        # Strong list punctuation is structural evidence and wins even
        # when the paragraph style happens to contain a heading-like name.
        #
        # Examples:
        #   <PgfTag `050 Title5'> + <PgfNumString `(1)\t'>
        #   <PgfTag `050 Title5'> + <PgfNumString `(2)\t'>
        #
        # Both are list items, not headings.
        #
        # Hierarchical heading markers such as 4.3 and 4.3.1 are not
        # strong list markers, so they still fall through to heading
        # detection.
        return true if Classification.strong_list_marker?(marker)

        # For ambiguous/non-structural markers, explicit heading styles
        # still prevent the paragraph from being claimed as a list.
        return false if Classification.heading_tag?(tag)

        Classification.list_like_tag?(tag)
      end

      def list_type_for(tag, marker)
        # Actual marker syntax takes priority
        # over a generic paragraph style.
        return :ul if Classification.unordered_list_marker?(marker)
        return :ol if Classification.ordered_list_marker?(marker)
        return :ol if Classification.ambiguous_period_numeric_marker?(marker)
        return :ul if Classification.unordered_list_tag?(tag)

        :ol
      end

      def list_level_for(tag, marker, previous_element: nil)
        tag_level = Classification.list_level_from_tag(tag)
        return tag_level unless tag_level.nil?

        family = Classification.marker_family(marker)
        intrinsic_depth = Classification.numeric_marker_depth(marker)

        case family
        when :wrapped_numeric
          intrinsic_depth
        when :right_numeric, :period_numeric
          contextual_numeric_list_level(
            family,
            intrinsic_depth,
            previous_element
          )
        when :wrapped_alpha, :right_alpha, :wrapped_roman, :right_roman
          contextual_alpha_list_level(family, previous_element)
        when :unordered
          contextual_unordered_list_level(previous_element)
        else
          0
        end
      end

      def extract_leading_list_marker(tag, text)
        stripped = text.to_s.lstrip
        return nil if stripped.empty?

        bullet = Classification::COMMON_BULLET_MARKERS.find do |candidate|
          stripped.start_with?(candidate)
        end

        if bullet
          remainder = stripped[bullet.length..].to_s.sub(/\A\s+/, "")

          return {
            marker: bullet,
            text: remainder
          }
        end

        return nil unless Classification.list_like_tag?(tag)

        match = stripped.match(
          /\A(\(\d+(?:\.\d+)*\)|\d+(?:\.\d+)*\)|\([A-Za-z]\)|[A-Za-z]\)|\((?i:[ivxlcdm]{2,})\)|(?i:[ivxlcdm]{2,})\))\s+(.+)\z/m
        )

        return nil unless match

        {
          marker: match[1],
          text: match[2]
        }
      end

      private

      def contextual_numeric_list_level(family, intrinsic_depth, previous_element)
        return intrinsic_depth unless previous_element.is_a?(List)

        previous_family = Classification.marker_family(previous_element.list_marker)
        previous_level = previous_element.list_level.to_i

        if same_numeric_family?(family, previous_family)
          return [intrinsic_depth, previous_level].max
        end

        if previous_family == :wrapped_numeric
          return [intrinsic_depth, previous_level + 1].max
        end

        intrinsic_depth
      end

      def contextual_alpha_list_level(family, previous_element)
        return 0 unless previous_element.is_a?(List)

        previous_family = Classification.marker_family(previous_element.list_marker)
        previous_level = previous_element.list_level.to_i

        return previous_level if family == previous_family

        if numeric_family?(previous_family) ||
           previous_family == :wrapped_alpha ||
           previous_family == :wrapped_roman
          return previous_level + 1
        end

        0
      end

      def contextual_unordered_list_level(previous_element)
        return 0 unless previous_element.is_a?(List)

        previous_family = Classification.marker_family(previous_element.list_marker)

        if previous_family == :unordered
          return previous_element.list_level.to_i
        end

        0
      end

      def numeric_family?(family)
        %i[wrapped_numeric right_numeric period_numeric].include?(family)
      end

      def same_numeric_family?(left, right)
        numeric_family?(left) && left == right
      end
    end
  end
end
