# frozen_string_literal: true

module MifParser
  class Parser
    module TableParser
      private

      def table_start?(line)
        line.match?(/\A<Tbl(?:\s|>|$)/)
      end

      def start_table
        @current_table = {
          id: nil,
          tag: nil,
          rows: []
        }

        @current_row = nil
        @current_cell = nil
      end

      def parse_table_line(line, closed_block)
        table_id = parse_table_id(line)

        @current_table[:id] = table_id unless table_id.nil?

        table_tag = parse_table_tag(line)

        @current_table[:tag] = table_tag if table_tag && @current_table[:tag].nil?

        #
        # Start row
        #

        if row_start?(line)
          @current_row = []
          return
        end

        #
        # Start cell
        #

        if @current_row && cell_start?(line)
          @current_cell = {
            strings: [],
            paragraphs: []
          }

          return
        end

        #
        # Cell contents
        #

        if @current_cell
          parse_text_tokens(line, @current_cell)

          #
          # One cell can contain multiple Para statements.
          #

          if block_closed?(closed_block, "Para")
            flush_cell_paragraph(@current_cell)
            return
          end

          if block_closed?(closed_block, "Cell")
            flush_cell_paragraph(@current_cell)

            @current_row <<
              @current_cell[:paragraphs].join("\n")

            @current_cell = nil
            return
          end
        end

        #
        # End row
        #

        if @current_row &&
           block_closed?(closed_block, "Row")
          @current_table[:rows] << @current_row
          @current_row = nil
          return
        end

        #
        # End table
        #

        return unless block_closed?(closed_block, "Tbl")

        table = build_table(@current_table)

        @tables[table.id] = table if table.id

        @current_table = nil
        @current_row = nil
        @current_cell = nil
      end

      def parse_table_id(line)
        match = line.match(
          /\A<TblID\s+(\d+)>/
        )

        return nil unless match

        match[1].to_i
      end

      def parse_table_tag(line)
        match = line.match(
          /<TblTag\s+`((?:\\.|[^'])*)'>/
        )

        return nil unless match

        decode_string(match[1])
      end

      #
      # <ATbl 123>
      #

      def parse_table_anchor(line)
        match = line.match(
          /<ATbl\s+(\d+)>/
        )

        return nil unless match

        match[1].to_i
      end

      #
      # Rows
      #

      def row_start?(line)
        line.match?(/\A<Row(?:\s|>|$)/)
      end

      #
      # Cells
      #

      def cell_start?(line)
        line.match?(/\A<Cell(?:\s|>|$)/)
      end

      def flush_cell_paragraph(cell)
        return if cell[:strings].empty?

        text = cell[:strings].join

        cell[:paragraphs] << text unless text.strip.empty?

        cell[:strings].clear
      end

      #
      # Build / resolve tables
      #

      def build_table(data)
        Table.new(
          id: data[:id],
          tag: data[:tag],
          rows: data[:rows]
        )
      end

      def resolve_table_anchors(elements, tables)
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
    end
  end
end
