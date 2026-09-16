# frozen_string_literal: true

require_relative "../syntax/block_tracker"
require_relative "../syntax/statements"
require_relative "../classification/classification"
require_relative "paragraph_parser"
require_relative "table_parser"
require_relative "catalog_parser"

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
                    :current_cell,
                    :current_title,
                    :saved_tags,
                    :catalog
      attr_reader :block_tracker

      def initialize
        @elements = []
        @tables = {}
        @current_para = nil
        @current_tag = nil
        @current_table = nil
        @current_row = nil
        @current_cell = nil
        @current_title = false
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

        @paragraph_parser.flush if @context.current_para
        @table_parser.finish if @context.current_table
        @catalog_parser.finish

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
          ),
          catalog: @context.catalog
        )
      end

      private

      def handle_statement(statement)
        closed_block = @context.block_tracker.update(statement)
        line = statement.text

        if @table_parser.start?(line)
          @table_parser.start
          @table_parser.finish if statement.complete?
          return
        end

        if @paragraph_parser.start?(line) && paragraph_allowed?
          @paragraph_parser.start
          if statement.complete?
            @paragraph_parser.flush
          end
          return
        end

        if @context.current_para
          @paragraph_parser.parse_statement(statement, closed_block)
          return
        end

        @catalog_parser.parse_statement(statement, closed_block)

        return unless @context.current_table

        @table_parser.parse_statement(statement, closed_block)
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
