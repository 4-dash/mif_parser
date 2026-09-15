# frozen_string_literal: true

module MifParser
  class Interpreter
    # Typed view of an element: heading, body, list, or table.
    Result = Struct.new(
      :type,
      :text,
      :heading_level,
      :list_level,
      :list_marker,
      :list_type,
      :rows,
      :source,
      keyword_init: true
    ) do
      def heading?
        type == :heading
      end

      def body?
        type == :body
      end

      def list?
        type == :list
      end

      def table?
        type == :table
      end
    end
  end
end
