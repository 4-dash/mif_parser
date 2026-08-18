module MifParser
  class Interpreter
    Result = Struct.new(
      :type,
      :text,
      :heading_level,
      :rows,
      :source,
      keyword_init: true
    ) do
      def heading?
        type == :heading
      end

      def body?
        type == :body
      end

      def table?
        type == :table
      end
    end

    def self.default
      @default ||= new
    end

    def initialize(numbered_headings: true)
      @numbered_headings = numbered_headings
    end

    def interpret(element)
      case element
      when Paragraph
        interpret_paragraph(element)

      when Table
        interpret_table(element)

      else
        Result.new(
          type: :unknown,
          source: element
        )
      end
    end

    private

    def interpret_paragraph(paragraph)
      #
      # First use an explicit heading-style tag.
      #
      # Examples:
      #
      # Title4
      # 040 Title4
      # Heading3
      #
      tag_level =
        heading_level_from_tag(paragraph.tag)

      if tag_level
        number =
          clean_number_string(
            paragraph.number_string
          )

        numeric_level =
          numbered_heading_level(number)

        return Result.new(
          type: :heading,

          #
          # Prefer the actual numbering depth when available.
          #
          # 4.3.4 => level 2
          #
          heading_level:
            numeric_level || tag_level,

          text:
            heading_text(
              number,
              paragraph.raw_text
            ),

          source: paragraph
        )
      end

      #
      # Keep the old numbered-heading fallback,
      # but don't turn obvious numbered-list styles
      # into headings.
      #
      if @numbered_headings &&
         !list_like_tag?(paragraph.tag)

        result =
          interpret_numbered_heading(paragraph)

        return result if result
      end

      Result.new(
        type: :body,
        text: paragraph.raw_text.strip,
        source: paragraph
      )
    end

    def interpret_table(table)
      Result.new(
        type: :table,
        rows: table.rows,
        source: table
      )
    end

    def interpret_numbered_heading(paragraph)
      return nil if
        paragraph.number_string.to_s.strip.empty?

      return nil if
        paragraph.raw_text.to_s.strip.empty?

      number =
        clean_number_string(
          paragraph.number_string
        )

      level =
        numbered_heading_level(number)

      return nil if level.nil?

      Result.new(
        type: :heading,
        heading_level: level,

        text:
          heading_text(
            number,
            paragraph.raw_text
          ),

        source: paragraph
      )
    end

    def numbered_heading_level(number)
      #
      # Matches:
      #
      # 3)
      # 3.
      # 2.1
      # 2.1.1
      # 2.1.1.
      #
      # Does NOT match:
      #
      # Fig. 5.5.13
      # Table 3
      #
      match = number.match(
        /\A(\d+(?:\.\d+)*)(?:[.)])?\z/
      )

      return nil unless match

      match[1].split(".").length - 1
    end

    def heading_text(number, raw_text)
      text = raw_text.to_s.strip

      return text if number.empty?

      "#{number} #{text}"
    end

    def clean_number_string(value)
      #
      # Parser now converts MIF \t into a real tab,
      # so normal strip is sufficient.
      #
      value.to_s.strip
    end

    #
    # Prevent obvious numbered-list paragraph styles
    # from being promoted to headings.
    #
    def list_like_tag?(tag)
      value = tag.to_s.strip

      return false if value.empty?

      value.match?(
        /\b(?:list|numbered|bullet)\b/i
      )
    end

    def heading_level_from_tag(tag)
      value = tag.to_s.strip

      case value

      #
      # Matches:
      #
      # Title4
      # 040 Title4
      # Heading3
      # 030 Heading3
      # Head_2
      # H1
      #
      # But NOT:
      #
      # Subtitle4
      #
      when /(?:\A|[\s_-])(?:heading|head|h|title)[\s_-]*(\d+)\z/i

        [
          Regexp.last_match(1).to_i - 1,
          0
        ].max

      when /(?:\A|[\s_-])chapter[\s_-]*title\z/i,
           /\Atitle\z/i

        0

      else
        nil
      end
    end
  end
end