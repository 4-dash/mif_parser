module MifConverter
  module Generic
    class Document
      attr_reader :nodes, :attributes

      def initialize(nodes: [], attributes: {})
        @nodes = nodes
        @attributes = attributes
      end
    end
  end
end