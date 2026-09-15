# frozen_string_literal: true

module MifParser
  module Syntax
    # Decodes MIF string escapes (`\'`, `\``, `\\`, `\t`, …).
    module StringDecoder
      extend self

      def decode(value)
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
            "\\#{escaped}"
          end
        end
      end
    end
  end
end
