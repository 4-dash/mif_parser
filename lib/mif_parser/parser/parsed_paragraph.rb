# frozen_string_literal: true

module MifParser
  class Parser
    class ParsedParagraph
      attr_accessor :tag,
                    :number_string,
                    :parts,
                    :tokens,
                    :local_properties,
                    :font_properties

      def initialize(tag:)
        @tag = tag
        @number_string = nil
        @parts = []
        @tokens = []
        @local_properties = {}
        @font_properties = {}
      end
    end
  end
end
