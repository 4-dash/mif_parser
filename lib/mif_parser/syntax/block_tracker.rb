# frozen_string_literal: true

module MifParser
  module Syntax
    # Tracks open MIF blocks (`<Para` … `>`) so parsers know what just closed.
    class BlockTracker
      def initialize
        @stack = []
      end

      def update(line)
        return @stack.pop if line.start_with?(">")

        match = line.match(/\A<([A-Za-z][A-Za-z0-9]*)\b/)
        return nil unless match

        unless line.match?(/>\s*(?:#.*)?\z/)
          @stack << match[1]
        end

        nil
      end

      def closed?(closed_block, name)
        !closed_block.nil? && closed_block.casecmp?(name)
      end
    end
  end
end
