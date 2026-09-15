# frozen_string_literal: true

require_relative "../syntax/block_tracker"
require_relative "../classification/classification"
require_relative "paragraph_parser"
require_relative "table_parser"

module MifParser
  class Parser
    # Mutable scan state shared by paragraph and table parsers.
    class Context
      attr_accessor :elements,
                    :tables,
                    :current_para,
                    :current_tag,
                    :current_table,
                    :current_row,
                    :current_cell
      attr_reader :block_tracker

      def initialize
        @elements = []
        @tables = {}
        @current_para = nil
        @current_tag = nil
        @current_table = nil
        @current_row = nil
        @current_cell = nil
        @block_tracker = Syntax::BlockTracker.new
      end
    end

    # Walks MIF lines and delegates Para vs Tbl, then classifies lists.
    class DocumentParser
      def initialize(input)
        @input = input
        @context = Context.new
        @paragraph_parser = ParagraphParser.new(@context)
        @table_parser = TableParser.new(@context)
      end

      def parse
        each_line do |raw_line|
          line = raw_line.strip

          next if line.empty?
          next if comment?(line)

          closed_block = @context.block_tracker.update(line)

          if @table_parser.start?(line)
            @table_parser.start
            next
          end

          if @context.current_table
            @table_parser.parse_line(line, closed_block)
            next
          end

          if @paragraph_parser.start?(line)
            @paragraph_parser.start
            next
          end

          next unless @context.current_para

          @paragraph_parser.parse_line(line, closed_block)
        end

        @paragraph_parser.flush if @context.current_para

        resolved_elements = TableParser.resolve_anchors(
          @context.elements,
          @context.tables
        )

        #
        # Resolve cases that require neighboring
        # paragraph context only after the entire
        # document structure has been parsed.
        #
        Document.new(
          Classification::AmbiguousSequence.classify(
            resolved_elements
          )
        )
      end

      private

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
    end
  end
end
