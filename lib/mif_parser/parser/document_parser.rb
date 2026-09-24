# frozen_string_literal: true

require_relative "../syntax/block_tracker"
require_relative "../syntax/statements"
require_relative "../classification/classification"
require_relative "paragraph_parser"
require_relative "table_parser"
require_relative "frame_parser"
require_relative "catalog_parser"

module MifParser
  class Parser
    # Mutable scan state shared by paragraph and table parsers.
    class Context
      attr_accessor :elements,
                    :tables,
                    :frames,
                    :current_para,
                    :current_tag,
                    :current_table,
                    :current_row,
                    :current_cell,
                    :current_title,
                    :current_frame,
                    :current_import,
                    :saved_tags,
                    :catalog
      attr_reader :block_tracker

      def initialize
        @elements = []
        @tables = {}
        @frames = {}
        @current_para = nil
        @current_tag = nil
        @current_table = nil
        @current_row = nil
        @current_cell = nil
        @current_title = false
        @current_frame = nil
        @current_import = nil
        @saved_tags = []
        @catalog = {}
        @block_tracker = Syntax::BlockTracker.new
      end
    end

    # Walks MIF statements and delegates Para vs Tbl, then classifies lists.
    class DocumentParser
      def initialize(input)
        @input = input
        @context = Context.new
        @paragraph_parser = ParagraphParser.new(@context)
        @table_parser = TableParser.new(@context)
        @frame_parser = FrameParser.new(@context)
        @catalog_parser = CatalogParser.new(@context)
      end

      def parse
        each_line do |raw_line|
          line = raw_line.strip

          next if line.empty?
          next if comment?(line)

          Syntax::Statements.parse_line(line).each do |statement|
            handle_statement(statement)
          end
        end

        flush_open_parsers

        Document.new(
          classified_elements,
          catalog: @context.catalog
        )
      end

      private

      def flush_open_parsers
        @paragraph_parser.flush if @context.current_para
        @table_parser.finish if @context.current_table
        @frame_parser.finish if @context.current_frame
        @catalog_parser.finish
      end

      def classified_elements
        resolved = TableParser.resolve_anchors(
          @context.elements,
          @context.tables
        )
        resolved = FrameParser.resolve_anchors(
          resolved,
          @context.frames
        )

        Classification::AmbiguousSequence.classify(resolved)
      end

      def handle_statement(statement)
        closed_block = @context.block_tracker.update(statement)
        line = statement.text

        return if start_table?(statement, line)
        return if start_frame?(statement, line)
        return if start_paragraph?(statement, line)
        return if continue_paragraph?(statement, closed_block)

        @catalog_parser.parse_statement(statement, closed_block)
        continue_structure(statement, closed_block)
      end

      def start_table?(statement, line)
        return false unless @table_parser.start?(line)

        @table_parser.start
        @table_parser.finish if statement.complete?
        true
      end

      def start_frame?(statement, line)
        return false unless @frame_parser.start?(line)
        return false unless @context.current_frame.nil?

        @frame_parser.start
        @frame_parser.finish if statement.complete?
        true
      end

      def start_paragraph?(statement, line)
        return false unless @paragraph_parser.start?(line)
        return false unless paragraph_allowed?

        @paragraph_parser.start
        @paragraph_parser.flush if statement.complete?
        true
      end

      def continue_paragraph?(statement, closed_block)
        return false unless @context.current_para

        @paragraph_parser.parse_statement(statement, closed_block)
        true
      end

      def continue_structure(statement, closed_block)
        if @context.current_table
          @table_parser.parse_statement(statement, closed_block)
        elsif @context.current_frame
          @frame_parser.parse_statement(statement, closed_block)
        end
      end

      def paragraph_allowed?
        @context.current_cell ||
          @context.current_title ||
          !@context.current_table
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
    end
  end
end
