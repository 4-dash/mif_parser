# frozen_string_literal: true

module MifParser
  module Syntax
    # Tracks open MIF blocks (`<Para` … `>`) so parsers know what just closed.
    class BlockTracker
      def initialize
        @stack = []
      end

      def update(statement)
        return @stack.pop if statement.close?

        tag = statement.tag
        return nil unless tag
        return nil if statement.complete?

        @stack << tag
        nil
      end

      def closed?(closed_block, name)
        !closed_block.nil? && closed_block.casecmp?(name)
      end
    end
  end
end
