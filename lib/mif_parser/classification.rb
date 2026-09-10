# frozen_string_literal: true

module MifParser
  module Classification
    COMMON_BULLET_MARKERS = %w[
      •
      ◦
      ▪
      ▫
      ‣
      ⁃
    ].freeze

    module_function

    def clean_marker(value)
      value.to_s.strip
    end

    def heading_tag?(tag)
      !heading_level_from_tag(tag).nil?
    end

    def heading_level_from_tag(tag)
      value = tag.to_s.strip

      case value
      when /(?:\A|[\s_-])(?:heading|head|h|title)[\s_-]*(\d+)\z/i
        [Regexp.last_match(1).to_i - 1, 0].max
      when /(?:\A|[\s_-])chapter[\s_-]*title\z/i,
           /\Atitle\z/i
        0
      else
        nil
      end
    end

    def list_like_tag?(tag)
      value = tag.to_s.strip
      return false if value.empty?
      return false if heading_tag?(value)

      value.match?(
        /(?:\A|[\s:_-])(?:list|numbered|bullet|ordered|unordered)(?:[\s:_-]*\d+)?(?:\z|[\s:_-])/i
      ) ||
        value.match?(
          /(?:\A|[\s:_-])(?:ul|ol)(?:[\s:_-]*\d+)?(?:\z|[\s:_-])/i
        )
    end

    def unordered_list_tag?(tag)
      value = tag.to_s.strip
      return false if value.empty?
      return false if heading_tag?(value)

      value.match?(
        /(?:\A|[\s:_-])(?:bullet|unordered|ul)(?:[\s:_-]*\d+)?(?:\z|[\s:_-])/i
      )
    end

    def ordered_list_tag?(tag)
      value = tag.to_s.strip
      return false if value.empty?
      return false if heading_tag?(value)

      value.match?(
        /(?:\A|[\s:_-])(?:numbered|ordered|ol)(?:[\s:_-]*\d+)?(?:\z|[\s:_-])/i
      )
    end

    def list_level_from_tag(tag)
      value = tag.to_s.strip
      return nil unless list_like_tag?(value)

      match = value.match(
        /(?:\A|[\s:_-])(?:list|numbered|bullet|ordered|unordered|ul|ol)[\s:_-]*(\d+)\z/i
      )

      return nil unless match

      [match[1].to_i - 1, 0].max
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
