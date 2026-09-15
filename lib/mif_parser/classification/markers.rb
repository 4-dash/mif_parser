# frozen_string_literal: true

module MifParser
  module Classification
    # Visible list punctuation: bullets, (1), 1), A), 1. and marker families.
    module Markers
      extend self

      COMMON_BULLET_MARKERS = %w[
        •
        ◦
        ▪
        ▫
        ‣
        ⁃
      ].freeze

      def clean_marker(value)
        value.to_s.strip
      end

      def unordered_list_marker?(marker)
        COMMON_BULLET_MARKERS.include?(clean_marker(marker))
      end

      def wrapped_numeric_list_marker?(marker)
        clean_marker(marker).match?(
          /\A\(\d+(?:\.\d+)*\)\z/
        )
      end

      def right_numeric_list_marker?(marker)
        clean_marker(marker).match?(
          /\A\d+(?:\.\d+)*\)\z/
        )
      end

      def wrapped_alpha_list_marker?(marker)
        clean_marker(marker).match?(
          /\A\([A-Za-z]\)\z/
        )
      end

      def right_alpha_list_marker?(marker)
        clean_marker(marker).match?(
          /\A[A-Za-z]\)\z/
        )
      end

      def wrapped_roman_list_marker?(marker)
        clean_marker(marker).match?(
          /\A\((?i:[ivxlcdm]{2,})\)\z/
        )
      end

      def right_roman_list_marker?(marker)
        clean_marker(marker).match?(
          /\A(?i:[ivxlcdm]{2,})\)\z/
        )
      end

      def ordered_list_marker?(marker)
        wrapped_numeric_list_marker?(marker) ||
          right_numeric_list_marker?(marker) ||
          wrapped_alpha_list_marker?(marker) ||
          right_alpha_list_marker?(marker) ||
          wrapped_roman_list_marker?(marker) ||
          right_roman_list_marker?(marker)
      end

      def strong_list_marker?(marker)
        unordered_list_marker?(marker) ||
          ordered_list_marker?(marker)
      end

      def ambiguous_period_numeric_marker?(marker)
        clean_marker(marker).match?(
          /\A\d+\.\z/
        )
      end

      def marker_family(marker)
        value = clean_marker(marker)

        return :unordered if unordered_list_marker?(value)
        return :wrapped_numeric if wrapped_numeric_list_marker?(value)
        return :right_numeric if right_numeric_list_marker?(value)
        return :wrapped_alpha if wrapped_alpha_list_marker?(value)
        return :right_alpha if right_alpha_list_marker?(value)
        return :wrapped_roman if wrapped_roman_list_marker?(value)
        return :right_roman if right_roman_list_marker?(value)
        return :period_numeric if ambiguous_period_numeric_marker?(value)

        :other
      end

      def numeric_marker_depth(marker)
        value = clean_marker(marker)

        value = value[1...-1] if wrapped_numeric_list_marker?(value)

        value = value[0...-1] if right_numeric_list_marker?(value)

        value = value[0...-1] if ambiguous_period_numeric_marker?(value)

        return 0 unless value.match?(
          /\A\d+(?:\.\d+)*\z/
        )

        value.split(".").length - 1
      end
    end
  end
end
