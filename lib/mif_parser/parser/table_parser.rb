# frozen_string_literal: true

require_relative "../syntax/string_decoder"
require_relative "../syntax/text_tokens"
require_relative "../elements/table"
require_relative "parsed_table"
require_relative "table_anchor"

module MifParser
  class Parser
    # Reads <Tbl> definitions and later replaces <ATbl> anchors with tables.
    class TableParser
      def initialize(context)
        @context = context
      end

      def start?(line)
        line.match?(/\A<Tbl(?:\s|>|$)/)
      end

      def start
        @context.current_table = ParsedTable.new
        @context.current_row = nil
        @context.current_cell = nil
      end

      def parse_line(line, closed_block)
        table_id = parse_table_id(line)
        @context.current_table.id = table_id unless table_id.nil?

        table_tag = parse_table_tag(line)
        if table_tag && @context.current_table.tag.nil?
          @context.current_table.tag = table_tag
        end

        if row_start?(line)
          @context.current_row = []
          return
        end

        if @context.current_row && cell_start?(line)
          @context.current_cell = ParsedCell.new
          return
        end

        if @context.current_cell
          Syntax::TextTokens.append(line, @context.current_cell.strings)

          if @context.block_tracker.closed?(closed_block, "Para")
            flush_cell_paragraph(@context.current_cell)
            return
          end

          if @context.block_tracker.closed?(closed_block, "Cell")
            flush_cell_paragraph(@context.current_cell)

            @context.current_row <<
              @context.current_cell.paragraphs.join("\n")

            @context.current_cell = nil
            return
          end
        end

        if @context.current_row &&
           @context.block_tracker.closed?(closed_block, "Row")
          @context.current_table.rows << @context.current_row
          @context.current_row = nil
          return
        end

        return unless @context.block_tracker.closed?(closed_block, "Tbl")

        table = build_table(@context.current_table)
        @context.tables[table.id] = table if table.id

        @context.current_table = nil
        @context.current_row = nil
        @context.current_cell = nil
      end

      def self.resolve_anchors(elements, tables)
        resolved = []

        elements.each do |element|
          if element.is_a?(TableAnchor)
            table = tables[element.id]
            resolved << table if table
          else
            resolved << element
          end
        end

        resolved
      end

      private

      def parse_table_id(line)
        match = line.match(/\A<TblID\s+(\d+)>/)
        return nil unless match

        match[1].to_i
      end

      def parse_table_tag(line)
        match = line.match(/<TblTag\s+`((?:\\.|[^'])*)'>/)
        return nil unless match

        Syntax::StringDecoder.decode(match[1])
      end

      def row_start?(line)
        line.match?(/\A<Row(?:\s|>|$)/)
      end

      def cell_start?(line)
        line.match?(/\A<Cell(?:\s|>|$)/)
      end

      def flush_cell_paragraph(cell)
        return if cell.strings.empty?

        text = cell.strings.join
        cell.paragraphs << text unless text.strip.empty?
        cell.strings.clear
      end

      def build_table(data)
        Table.new(
          id: data.id,
          tag: data.tag,
          rows: data.rows
        )
      end
    end
  end
end
