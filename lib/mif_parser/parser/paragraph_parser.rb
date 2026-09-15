# frozen_string_literal: true

require_relative "../syntax/string_decoder"
require_relative "../syntax/text_tokens"
require_relative "../classification/classification"
require_relative "parsed_paragraph"
require_relative "table_anchor"

module MifParser
  class Parser
    # Reads <Para> blocks: PgfTag, PgfNumString, text, <ATbl> anchors.
    class ParagraphParser
      def initialize(context)
        @context = context
      end

      def start?(line)
        line.match?(/\A<Para(?:\s|>|$)/)
      end

      def start
        if @context.current_para
          append_paragraph_elements(@context.current_para)
        end

        @context.current_para = ParsedParagraph.new(
          tag: @context.current_tag
        )
      end

      def parse_line(line, closed_block)
        data = @context.current_para

        tag = parse_paragraph_tag(line)
        unless tag.nil?
          @context.current_tag = tag
          data.tag = tag
        end

        number_string = parse_number_string(line)
        unless number_string.nil?
          data.number_string = number_string
        end

        table_id = TableAnchor.parse(line)
        unless table_id.nil?
          flush_paragraph_text_part(data)
          data.parts << table_id
        end

        Syntax::TextTokens.append(line, data.strings)

        return unless @context.block_tracker.closed?(closed_block, "Para")

        append_paragraph_elements(data)
        @context.current_para = nil
      end

      def flush
        append_paragraph_elements(@context.current_para)
      end

      private

      def parse_paragraph_tag(line)
        match = line.match(/<PgfTag\s+`((?:\\.|[^'])*)'>/)
        return nil unless match

        Syntax::StringDecoder.decode(match[1])
      end

      def parse_number_string(line)
        match = line.match(/<PgfNumString\s+`((?:\\.|[^'])*)'>/)
        return nil unless match

        Syntax::StringDecoder.decode(match[1])
      end

      def flush_paragraph_text_part(data)
        return if data.strings.empty?

        text = data.strings.join
        data.parts << text unless text.empty?
        data.strings.clear
      end

      def append_paragraph_elements(data)
        return unless data

        flush_paragraph_text_part(data)

        first_text_part = true

        data.parts.each do |part|
          if part.is_a?(TableAnchor)
            @context.elements << part
            next
          end

          element = Classification::ListItem.build(
            tag: (data.tag if first_text_part),
            number_string: (data.number_string if first_text_part),
            text: part,
            previous_element: @context.elements.last
          )

          @context.elements << element unless element.raw_text.strip.empty?

          first_text_part = false
        end
      end
    end
  end
end
