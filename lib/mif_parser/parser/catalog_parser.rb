# frozen_string_literal: true

require_relative "../format"
require_relative "../syntax/string_decoder"
require_relative "property"

module MifParser
  class Parser
    # Reads <PgfCatalog> into Context#catalog, keyed by PgfTag.
    class CatalogParser
      def initialize(context)
        @context = context
        @current = nil
      end

      def parse_statement(statement, closed_block)
        tracker = @context.block_tracker

        if statement.open? &&
           statement.tag&.casecmp?("Pgf") &&
           tracker.inside?("PgfCatalog")
          save_current
          @current = {
            "tag" => nil,
            "properties" => {}
          }
          return
        end

        collect_current(statement) if tracker.inside?("PgfCatalog")

        if tracker.closed?(closed_block, "Pgf") ||
           tracker.closed?(closed_block, "PgfCatalog")
          save_current
        end
      end

      def finish
        save_current
      end

      private

      def collect_current(statement)
        return unless @current

        tag = parse_paragraph_tag(statement.text)
        @current["tag"] = tag unless tag.nil?

        parsed = Property.parse(statement)
        return unless parsed

        name, value = parsed
        @current["properties"][name] = value
      end

      def parse_paragraph_tag(line)
        match = line.match(/<PgfTag\s+`((?:\\.|[^'])*)'>/)
        return nil unless match

        Syntax::StringDecoder.decode(match[1])
      end

      def save_current
        return unless @current

        tag = @current["tag"]
        unless tag.nil?
          @context.catalog[tag] =
            Format.new(@current["properties"])
        end

        @current = nil
      end
    end
  end
end
