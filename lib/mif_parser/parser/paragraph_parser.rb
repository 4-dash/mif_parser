# frozen_string_literal: true

require_relative "../syntax/string_decoder"
require_relative "../syntax/text_tokens"
require_relative "../classification/classification"
require_relative "../format"
require_relative "../text_run"
require_relative "parsed_paragraph"
require_relative "table_anchor"
require_relative "property"

module MifParser
  class Parser
    # Reads <Para> blocks: PgfTag, PgfNumString, text, <ATbl> anchors,
    # local <Pgf> format overlays, and inline <Font> runs.
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

      def parse_statement(statement, closed_block)
        data = @context.current_para
        line = statement.text
        tracker = @context.block_tracker

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

        collect_format_property(data, statement, tracker)

        if tracker.closed?(closed_block, "Font") &&
           !tracker.inside?("Pgf")
          flush_font_override(data, reset: true)
        end

        extract_text_tokens(data, line)

        return unless tracker.closed?(closed_block, "Para")

        append_paragraph_elements(data)
        @context.current_para = nil
      end

      def flush
        append_paragraph_elements(@context.current_para)
        @context.current_para = nil
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

      def collect_format_property(data, statement, tracker)
        parsed = Property.parse(statement)
        return unless parsed

        name, value = parsed

        if tracker.inside?("Pgf")
          data.local_properties[name] = value
        elsif tracker.inside?("Font")
          data.font_properties[name] = value
        end
      end

      def flush_font_override(data, reset: false)
        return if data.font_properties.empty? && !reset

        data.tokens << [
          :font,
          Format.new(data.font_properties)
        ]
        data.font_properties = {}
      end

      def extract_text_tokens(data, line)
        extracted = []
        Syntax::TextTokens.append(line, extracted)

        extracted.each do |text|
          data.tokens << [:text, text]
        end
      end

      def flush_paragraph_text_part(data)
        return if data.tokens.empty?

        text = data.tokens.each_with_object(+"") do |(type, value), joined|
          joined << value if type == :text
        end

        if text.empty?
          data.tokens = []
          return
        end

        data.parts << data.tokens
        data.tokens = []
      end

      def destination
        if @context.current_cell
          @context.current_cell.elements
        elsif @context.current_title
          @context.current_table.title
        else
          @context.elements
        end
      end

      def append_paragraph_elements(data)
        return unless data

        flush_font_override(data)
        flush_paragraph_text_part(data)

        sink = destination
        first_text_part = true
        base_format = resolved_format(data)

        data.parts.each do |part|
          if part.is_a?(TableAnchor)
            sink << part
            next
          end

          runs = materialize_runs(part, base_format)
          text = runs.map(&:text).join

          element = Classification::ListItem.build(
            tag: (data.tag if first_text_part),
            number_string: (data.number_string if first_text_part),
            text: text,
            format: base_format,
            runs: runs,
            previous_element: sink.last
          )

          sink << element unless element.raw_text.strip.empty?

          first_text_part = false
        end
      end

      def resolved_format(data)
        catalog_format = @context.catalog[data.tag]
        local = Format.new(data.local_properties)

        return local unless catalog_format

        catalog_format.merge(local)
      end

      def materialize_runs(tokens, base_format)
        current = base_format
        chunks = []

        tokens.each do |type, value|
          case type
          when :font
            current = base_format.merge(value)
          when :text
            next if value.empty?

            last = chunks.last
            if last && last[1] == current
              last[0] += value
            else
              chunks << [value, current]
            end
          end
        end

        chunks.map do |text, format|
          TextRun.new(text: text, format: format)
        end
      end
    end
  end
end
