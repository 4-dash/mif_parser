# frozen_string_literal: true

require_relative "../format"
require_relative "../syntax/string_decoder"

module MifParser
  class Parser
    # Reads one complete MIF statement if its tag is on the format whitelist.
    module Property
      extend self

      STRING_RE =
        /\A<[A-Za-z][A-Za-z0-9]*\s+`((?:\\.|[^'])*)'\s*>\z/
      VALUE_RE =
        /\A<[A-Za-z][A-Za-z0-9]*\s+(.+?)\s*>\z/

      def parse(statement)
        return nil unless statement.complete?

        tag = statement.tag
        return nil unless Format.known?(tag)

        text = statement.text
        match = text.match(STRING_RE)
        if match
          return [
            tag,
            Syntax::StringDecoder.decode(match[1])
          ]
        end

        match = text.match(VALUE_RE)
        return nil unless match

        [tag, match[1].strip]
      end
    end
  end
end
