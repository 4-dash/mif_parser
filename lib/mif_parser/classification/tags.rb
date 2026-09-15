# frozen_string_literal: true

module MifParser
  module Classification
    # Paragraph style names: heading?, list-like?, ul/ol from PgfTag.
    module Tags
      extend self

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
    end
  end
end
