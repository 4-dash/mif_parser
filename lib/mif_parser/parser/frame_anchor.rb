# frozen_string_literal: true

module MifParser
  class Parser
    FrameAnchor = Struct.new(:id) do
      def self.parse(line)
        match = line.match(/<AFrame\s+(\d+)>/)
        return nil unless match

        new(match[1].to_i)
      end
    end
  end
end
