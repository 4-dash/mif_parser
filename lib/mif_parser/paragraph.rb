module MifParser
  class Paragraph
    attr_reader :text, :tag

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
      level_from_tag
    end

    def import_text
      text.strip
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

    def normalize_level(number)
      [number.to_i - 1, 0].max
    end
  end
end