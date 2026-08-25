# frozen_string_literal: true

module MifParser
  class Parser
    module ParagraphParser
      private

      def paragraph_start?(line)
        line.match?(/\A<Para(?:\s|>|$)/)
      end

      def start_paragraph
        if @current_para
          append_paragraph_elements(
            @elements,
            @current_para
          )
        end

        @current_para = {
          tag: @current_tag,
          number_string: nil,
          strings: [],
          parts: []
        }
      end

      def parse_paragraph_line(line, closed_block)
        #
        # PgfTag
        #

        tag = parse_paragraph_tag(line)

        unless tag.nil?
          @current_tag = tag
          @current_para[:tag] = tag
        end

        #
        # PgfNumString
        #

        number_string =
          parse_number_string(line)

        unless number_string.nil?
          @current_para[:number_string] =
            number_string
        end

        #
        # Table insertion point
        #

        table_id =
          parse_table_anchor(line)

        unless table_id.nil?
          flush_paragraph_text_part(
            @current_para
          )

          @current_para[:parts] <<
            TableAnchor.new(table_id)
        end

        #
        # String + Char contents
        #

        parse_text_tokens(
          line,
          @current_para
        )

        return unless block_closed?(
          closed_block,
          "Para"
        )

        append_paragraph_elements(
          @elements,
          @current_para
        )

        @current_para = nil
      end

      def parse_paragraph_tag(line)
        match = line.match(
          /<PgfTag\s+`((?:\\.|[^'])*)'>/
        )

        return nil unless match

        decode_string(match[1])
      end

      def parse_number_string(line)
        match = line.match(
          /<PgfNumString\s+`((?:\\.|[^'])*)'>/
        )

        return nil unless match

        decode_string(match[1])
      end

      def flush_paragraph_text_part(data)
        return if data[:strings].empty?

        text = data[:strings].join

        data[:parts] << text unless text.empty?

        data[:strings].clear
      end

      def append_paragraph_elements(elements, data)
        return unless data

        flush_paragraph_text_part(data)

        first_text_part = true

        data[:parts].each do |part|
          if part.is_a?(TableAnchor)
            elements << part
            next
          end

          element =
            build_paragraph_element(
              tag:
                first_text_part ? data[:tag] : nil,
              number_string:
                if first_text_part
                  data[:number_string]
                else
                  nil
                end,
              text: part
            )

          elements << element unless element.raw_text.strip.empty?

          first_text_part = false
        end
      end
    end
  end
end
