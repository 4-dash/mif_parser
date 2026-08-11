module MifParser
  class Parser
    def initialize(input)
      @input = input
    end

    def parse
      Document.new(parse_paragraphs)
    end

    private

    def parse_paragraphs
      paragraphs = []

      current_para = nil

      each_line do |raw_line|
        line = raw_line.strip

        next if line.empty?
        next if comment?(line)

        #
        # Beginning of a FrameMaker paragraph:
        #
        # <Para
        #
        if paragraph_start?(line)
          #
          # Finish an unfinished paragraph defensively.
          #
          paragraphs << build_paragraph(current_para) if current_para

          current_para = {
            tag: nil,
            strings: [],
          }

          next
        end

        next unless current_para

        parse_paragraph_tag(line, current_para)
        parse_strings(line, current_para)

        #
        # Normal MIF paragraph ending:
        #
        # > # end of Para
        #
        if paragraph_end?(line)
          paragraphs << build_paragraph(current_para)
          current_para = nil
        end
      end

      #
      # Be tolerant if the final Para wasn't properly closed.
      #
      paragraphs << build_paragraph(current_para) if current_para

      paragraphs.compact.reject do |paragraph|
        paragraph.text.strip.empty?
      end
    end

    def each_line(&block)
      if @input.respond_to?(:each_line)
        @input.each_line(&block)
      else
        @input.to_s.each_line(&block)
      end
    end

    def comment?(line)
      line.start_with?("#")
    end

    def paragraph_start?(line)
      line.match?(/\A<Para(?:\s|>|$)/)
    end

    def paragraph_end?(line)
      line.match?(
        /\A>\s*#\s*end\s+of\s+Para\b/i
      )
    end

    #
    # Example:
    #
    # <PgfTag `Heading1'>
    # <PgfTag `Body'>
    #
    def parse_paragraph_tag(line, current_para)
      match = line.match(
        /<PgfTag\s+`((?:\\.|[^'])*)'>/
      )

      return unless match

      current_para[:tag] = decode_string(match[1])
    end

    #
    # One Para can contain several String statements.
    #
    # We intentionally combine ALL of them into the paragraph.
    #
    # Fragment/TU splitting belongs to Segment#write_import_texts!
    # in the Rails application, not to this gem.
    #
    def parse_strings(line, current_para)
      line.scan(
        /<String\s+`((?:\\.|[^'])*)'>/
      ) do |match|
        current_para[:strings] << decode_string(match.first)
      end
    end

    def build_paragraph(data)
      return nil unless data

      Paragraph.new(
        tag: data[:tag],
        text: data[:strings].join
      )
    end

    #
    # Basic MIF escape decoding.
    #
    def decode_string(value)
      value
        .to_s
        .gsub("\\`", "`")
        .gsub("\\'", "'")
        .gsub("\\\\", "\\")
    end
  end
end