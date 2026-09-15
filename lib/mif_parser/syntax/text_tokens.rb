# frozen_string_literal: true

require_relative "char_map"
require_relative "string_decoder"

module MifParser
  module Syntax
    # Pulls `<String>` and `<Char>` values out of a MIF line.
    module TextTokens
      extend self

      TEXT_TOKEN_RE =
        /<String\s+`((?:\\.|[^'])*)'>|<Char\s+([A-Za-z][A-Za-z0-9]*)>/

      def append(line, strings)
        line.scan(TEXT_TOKEN_RE) do |string_value, char_name|
          if string_value
            strings << StringDecoder.decode(string_value)
          elsif char_name
            value = CHAR_MAP[char_name]
            strings << value if value
          end
        end
      end
    end
  end
end
