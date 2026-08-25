# frozen_string_literal: true

module MifParser
  class Interpreter
    module ListInterpreter
      private

      def interpret_list(list)
        Result.new(
          type: :list,
          text: list.raw_text.to_s.strip,
          list_type: list.list_type,
          list_level: list.list_level,
          list_marker: list.list_marker,
          source: list
        )
      end
    end
  end
end
