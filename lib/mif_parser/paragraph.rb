module MifParser
  class Paragraph
    attr_reader :text, :tag

    BODY_TAG_PATTERNS = [
      /\Abody\z/i,
      /\Abody[\s_-]*text\z/i,
      /\Aparagraph\z/i,
      /\Anormal\z/i,
      /\Atext\z/i,
    ].freeze

    def initialize(text:, tag: nil)
      @text = text.to_s
      @tag = tag
    end

    def heading?
      !heading_level.nil?
    end

    def body?
      !heading?
    end

    def heading_level
      explicit_level = level_from_tag

      return explicit_level unless explicit_level.nil?
      return nil if body_tag?

      level_from_numbering
    end

    def import_text
      value = text.strip

      return value unless heading?

      value
        .sub(/\A\s*\d+(?:\.\d+)*\.?\s+/, "")
        .strip
    end

    alias_method :clean_text, :import_text

    private

    def level_from_tag
      value = tag.to_s.strip

      case value
      when /\Aheading[\s_-]*(\d+)\z/i
        normalize_level(Regexp.last_match(1))

      when /\Ahead[\s_-]*(\d+)\z/i
        normalize_level(Regexp.last_match(1))

      when /\Ah[\s_-]*(\d+)\z/i
        normalize_level(Regexp.last_match(1))

      when /\Achapter[\s_-]*title\z/i
        0

      when /\Atitle\z/i
        0

      else
        nil
      end
    end

    def body_tag?
      value = tag.to_s.strip

      BODY_TAG_PATTERNS.any? do |pattern|
        value.match?(pattern)
      end
    end

    def level_from_numbering
      value = text.to_s.strip

      #
      # Match hierarchical numbering:
      #
      # 1 Heading
      # 1.2 Heading
      # 1.2.3 Heading
      # 1.2. Heading
      #
      match = value.match(
        /\A(\d+(?:\.\d+)*)(?:\.)?\s+(.+)\z/
      )

      return nil unless match

      numbering = match[1]
      remainder = match[2].to_s.strip

      return nil if remainder.empty?

      #
      # A single large integer is much more likely to be a year/value:
      #
      # 2026 is the current year.
      #
      if !numbering.include?(".") &&
        numbering.to_i >= 100
        return nil
      end

      #
      # Reject decimal/value-like constructs.
      #
      # Examples:
      #
      # 3.14159 is approximately pi.
      # 10.20 EUR is the listed price.
      #
      parts = numbering.split(".")

      if parts.length == 2
        second = parts[1]

        #
        # Section numbers normally have relatively small components.
        # 3.14159 strongly looks like a decimal rather than section 3.14159.
        #
        return nil if second.length > 3
      end

      #
      # Reject common unit/currency/value continuations.
      #
      # 10.20 EUR
      # 3.1 volts
      # 2.5 meters
      #
      first_word = remainder.split(/\s+/, 2).first.to_s

      non_heading_words = %w[
        eur usd gbp chf
        volt volts
        meter meters metre metres
        cm mm km
        kg g mg
        hz khz mhz ghz
        mb gb tb
        percent percentage
      ]

      return nil if non_heading_words.include?(first_word.downcase)

      parts.length - 1
    end

    def normalize_level(number)
      [number.to_i - 1, 0].max
    end
  end
end