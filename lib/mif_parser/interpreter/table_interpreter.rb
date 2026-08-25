# frozen_string_literal: true

module MifParser
  class Interpreter
    module TableInterpreter
      private

      def interpret_table(table)
        Result.new(
          type: :table,
          rows: table.rows,
          source: table
        )
      end
    end
  end
end
