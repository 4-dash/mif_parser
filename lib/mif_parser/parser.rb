module MifParser
  class Parser
    TableAnchor = Struct.new(:id)

    CHAR_MAP = {
      "Tab"         => "\t",
      "HardReturn"  => "\n",
      "HardSpace"   => "\u00A0",
      "SoftHyphen"  => "\u00AD",
      "DiscHyphen"  => "\u00AD",
      "HardHyphen"  => "\u2011",
      "EnDash"      => "–",
      "EmDash"      => "—",
      "Bullet"      => "•",
      "Cent"        => "¢",
      "Pound"       => "£",
      "Yen"         => "¥"
    }.freeze

    TEXT_TOKEN_RE =
      /<String\s+`((?:\\.|[^'])*)'>|<Char\s+([A-Za-z][A-Za-z0-9]*)>/

    def initialize(input)
      @input = input
      @block_stack = []
    end

    def parse
      elements = []
      tables = {}

      current_para = nil
      current_tag = nil

      current_table = nil
      current_row = nil
      current_cell = nil

      each_line do |raw_line|
        line = raw_line.strip

        next if line.empty?
        next if comment?(line)

        closed_block = update_block_stack(line)

        #
        # --------------------------------------------------
        # TABLE DEFINITION
        # --------------------------------------------------
        #

        if table_start?(line)
          current_table = {
            id: nil,
            tag: nil,
            rows: []
          }

          current_row = nil
          current_cell = nil

          next
        end

        if current_table
          table_id = parse_table_id(line)

          unless table_id.nil?
            current_table[:id] = table_id
          end

          table_tag = parse_table_tag(line)

          if table_tag && current_table[:tag].nil?
            current_table[:tag] = table_tag
          end

          #
          # Start row
          #
          if row_start?(line)
            current_row = []
            next
          end

          #
          # Start cell
          #
          if current_row && cell_start?(line)
            current_cell = {
              strings: [],
              paragraphs: []
            }

            next
          end

          #
          # Cell contents
          #
          if current_cell
            parse_text_tokens(line, current_cell)

            #
            # One cell can contain multiple Para statements.
            #
            if block_closed?(closed_block, "Para")
              flush_cell_paragraph(current_cell)
              next
            end

            if block_closed?(closed_block, "Cell")
              flush_cell_paragraph(current_cell)

              current_row << current_cell[:paragraphs].join("\n")

              current_cell = nil
              next
            end
          end

          #
          # End row
          #
          if current_row && block_closed?(closed_block, "Row")
            current_table[:rows] << current_row
            current_row = nil
            next
          end

          #
          # End table
          #
          if block_closed?(closed_block, "Tbl")
            table = build_table(current_table)

            tables[table.id] = table if table.id

            current_table = nil
            current_row = nil
            current_cell = nil

            next
          end

          next
        end

        #
        # --------------------------------------------------
        # NORMAL DOCUMENT PARAGRAPHS
        # --------------------------------------------------
        #

        if paragraph_start?(line)
          if current_para
            append_paragraph_elements(
              elements,
              current_para
            )
          end

          current_para = {
            tag: current_tag,
            number_string: nil,
            strings: [],
            parts: []
          }

          next
        end

        next unless current_para

        #
        # PgfTag
        #
        tag = parse_paragraph_tag(line)

        unless tag.nil?
          current_tag = tag
          current_para[:tag] = tag
        end

        #
        # PgfNumString
        #
        number_string = parse_number_string(line)

        unless number_string.nil?
          current_para[:number_string] = number_string
        end

        #
        # Table insertion point.
        #
        # Preserve its actual position instead of always
        # adding the table after the whole paragraph.
        #
        table_id = parse_table_anchor(line)

        unless table_id.nil?
          flush_paragraph_text_part(current_para)

          current_para[:parts] << TableAnchor.new(
            table_id
          )
        end

        #
        # String + Char contents
        #
        parse_text_tokens(line, current_para)

        if block_closed?(closed_block, "Para")
          append_paragraph_elements(
            elements,
            current_para
          )

          current_para = nil
        end
      end

      if current_para
        append_paragraph_elements(
          elements,
          current_para
        )
      end

      Document.new(
        resolve_table_anchors(elements, tables)
      )
    end

    private

    #
    # --------------------------------------------------
    # INPUT
    # --------------------------------------------------
    #

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

    #
    # --------------------------------------------------
    # LIGHTWEIGHT BLOCK TRACKING
    # --------------------------------------------------
    #
    # This is intentionally NOT a full tokenizer.
    #
    # It only remembers multiline statement names:
    #
    #   <Para
    #     ...
    #   >
    #
    # so that the bare ">" tells us that Para ended.
    #
    # This means we no longer depend on:
    #
    #   > # end of Para
    #
    # The comment can be present or absent.
    #

    def update_block_stack(line)
      if line.start_with?(">")
        return @block_stack.pop
      end

      match = line.match(
        /\A<([A-Za-z][A-Za-z0-9]*)\b/
      )

      return nil unless match

      #
      # Atomic statement:
      #
      # <PgfTag `Body'>
      #
      # Multiline statement:
      #
      # <Para
      #
      unless line.match?(/>\s*(?:#.*)?\z/)
        @block_stack << match[1]
      end

      nil
    end

    def block_closed?(closed_block, name)
      !closed_block.nil? &&
        closed_block.casecmp?(name)
    end

    #
    # --------------------------------------------------
    # PARAGRAPHS
    # --------------------------------------------------
    #

    def paragraph_start?(line)
      line.match?(/\A<Para(?:\s|>|$)/)
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

    #
    # Flush text before an anchored table.
    #
    def flush_paragraph_text_part(data)
      return if data[:strings].empty?

      text = data[:strings].join

      data[:parts] << text unless text.empty?

      data[:strings].clear
    end

    #
    # The existing model only has:
    #
    # Paragraph
    # Table
    #
    # So:
    #
    #   String A
    #   ATbl
    #   String B
    #
    # becomes:
    #
    #   Paragraph A
    #   Table
    #   Paragraph B
    #
    # The continuation paragraph does not repeat
    # the original number/tag.
    #
    def append_paragraph_elements(elements, data)
      return unless data

      flush_paragraph_text_part(data)

      first_text_part = true

      data[:parts].each do |part|
        if part.is_a?(TableAnchor)
          elements << part
          next
        end

        paragraph = Paragraph.new(
          tag: first_text_part ? data[:tag] : nil,
          number_string:
            first_text_part ? data[:number_string] : nil,
          text: part
        )

        unless paragraph.raw_text.strip.empty?
          elements << paragraph
        end

        first_text_part = false
      end
    end

    #
    # --------------------------------------------------
    # TABLES
    # --------------------------------------------------
    #

    def table_start?(line)
      line.match?(/\A<Tbl(?:\s|>|$)/)
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
    # --------------------------------------------------
    # ROWS
    # --------------------------------------------------
    #

    def row_start?(line)
      line.match?(/\A<Row(?:\s|>|$)/)
    end

    #
    # --------------------------------------------------
    # CELLS
    # --------------------------------------------------
    #

    def cell_start?(line)
      line.match?(/\A<Cell(?:\s|>|$)/)
    end

    def flush_cell_paragraph(cell)
      return if cell[:strings].empty?

      text = cell[:strings].join

      unless text.strip.empty?
        cell[:paragraphs] << text
      end

      cell[:strings].clear
    end

    #
    # --------------------------------------------------
    # BUILD / RESOLVE TABLES
    # --------------------------------------------------
    #

    def build_table(data)
      Table.new(
        id: data[:id],
        tag: data[:tag],
        rows: data[:rows]
      )
    end

    #
    # Resolve after parsing the complete document.
    #
    # This also means an ATbl can reference a Tbl that
    # appears later in the file.
    #
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

    #
    # --------------------------------------------------
    # STRING + CHAR CONTENTS
    # --------------------------------------------------
    #

    def parse_text_tokens(line, container)
      line.scan(TEXT_TOKEN_RE) do |string_value, char_name|
        if string_value
          container[:strings] <<
            decode_string(string_value)

        elsif char_name
          value = CHAR_MAP[char_name]

          container[:strings] << value if value
        end
      end
    end

    #
    # --------------------------------------------------
    # MIF STRING ESCAPES
    # --------------------------------------------------
    #

    def decode_string(value)
      value.to_s.gsub(/\\(.)/m) do
        escaped = Regexp.last_match(1)

        case escaped
        when "t"
          "\t"

        when ">"
          ">"

        when "q", "'"
          "'"

        when "Q", "`"
          "`"

        when "\\"
          "\\"

        else
          #
          # Keep escapes we do not support yet unchanged.
          #
          # Important for things such as legacy \xNN.
          #
          "\\#{escaped}"
        end
      end
    end
  end
end