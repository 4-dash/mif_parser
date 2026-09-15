# frozen_string_literal: true

require_relative "../syntax/string_decoder"
require_relative "../classification/classification"
require_relative "../elements/table"
require_relative "../elements/cell"
require_relative "parsed_table"
require_relative "table_anchor"

module MifParser
  class Parser
    # Reads <Tbl> structure: id, tag, title, rows, cells.
    # Cell text is parsed by ParagraphParser into the current cell sink.
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
        @context.current_title = false
      end

      def finish
        finish_table
      end

      def parse_statement(statement, closed_block)
        line = statement.text

        table_id = parse_table_id(line)
        @context.current_table.id = table_id unless table_id.nil?

        table_tag = parse_table_tag(line)
        if table_tag && @context.current_table.tag.nil?
          @context.current_table.tag = table_tag
        end

        if section_start?(line, "TblH")
          @context.current_table.section = :header
          return
        end

        if section_start?(line, "TblBody")
          @context.current_table.section = :body
          return
        end

        if section_start?(line, "TblF")
          @context.current_table.section = :footer
          return
        end

        if title_start?(line)
          start_title
          finish_title if statement.complete?
          return
        end

        if row_start?(line)
          start_row
          finish_row if statement.complete?
          return
        end

        if @context.current_row && cell_start?(line)
          start_cell
          finish_cell if statement.complete?
          return
        end

        if @context.block_tracker.closed?(closed_block, "Cell")
          finish_cell
          return
        end

        if @context.block_tracker.closed?(closed_block, "Row")
          finish_row
          return
        end

        if @context.block_tracker.closed?(closed_block, "TblTitle")
          finish_title
          return
        end

        return unless @context.block_tracker.closed?(closed_block, "Tbl")

        finish_table
      end

      def self.resolve_anchors(elements, tables, seen = {})
        elements.filter_map do |element|
          resolve_element(element, tables, seen)
        end
      end

      def self.resolve_element(element, tables, seen)
        if element.is_a?(TableAnchor)
          table = tables[element.id]
          return nil unless table

          resolve_table(table, tables, seen)
          table
        else
          resolve_nested(element, tables, seen)
          element
        end
      end

      def self.resolve_nested(element, tables, seen)
        case element
        when Table
          resolve_table(element, tables, seen)
        when Cell
          element.elements.replace(
            resolve_anchors(element.elements, tables, seen)
          )
        end
      end

      def self.resolve_table(table, tables, seen)
        return if seen[table.object_id]

        seen[table.object_id] = true

        table.title.replace(
          resolve_anchors(table.title, tables, seen)
        )

        [table.header_rows, table.body_rows, table.footer_rows].each do |rows|
          rows.each do |row|
            row.each do |cell|
              cell.elements.replace(
                resolve_anchors(cell.elements, tables, seen)
              )
            end
          end
        end
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

      def section_start?(line, name)
        line.match?(/\A<#{name}(?:\s|>|$)/)
      end

      def title_start?(line)
        line.match?(/\A<TblTitle(?:\s|>|$)/)
      end

      def row_start?(line)
        line.match?(/\A<Row(?:\s|>|$)/)
      end

      def cell_start?(line)
        line.match?(/\A<Cell(?:\s|>|$)/)
      end

      def start_title
        push_tag_scope
        @context.current_title = true
      end

      def finish_title
        return unless @context.current_title

        @context.current_table.title.replace(
          Classification::AmbiguousSequence.classify(
            @context.current_table.title
          )
        )
        @context.current_title = false
        pop_tag_scope
      end

      def start_row
        @context.current_row = []
      end

      def finish_row
        return unless @context.current_row

        finish_cell if @context.current_cell

        @context.current_table.section_rows << @context.current_row
        @context.current_row = nil
      end

      def start_cell
        push_tag_scope
        @context.current_cell = ParsedCell.new
      end

      def finish_cell
        return unless @context.current_cell
        return unless @context.current_row

        cell = Cell.new(
          elements: Classification::AmbiguousSequence.classify(
            @context.current_cell.elements
          )
        )

        @context.current_row << cell
        @context.current_cell = nil
        pop_tag_scope
      end

      def finish_table
        return unless @context.current_table

        finish_title if @context.current_title
        finish_row if @context.current_row

        table = build_table(@context.current_table)
        @context.tables[table.id] = table if table.id

        @context.current_table = nil
        @context.current_row = nil
        @context.current_cell = nil
        @context.current_title = false
      end

      def push_tag_scope
        @context.saved_tags << @context.current_tag
        @context.current_tag = nil
      end

      def pop_tag_scope
        @context.current_tag = @context.saved_tags.pop
      end

      def build_table(data)
        Table.new(
          id: data.id,
          tag: data.tag,
          title: data.title,
          header_rows: data.header_rows,
          body_rows: data.body_rows,
          footer_rows: data.footer_rows
        )
      end
    end
  end
end
