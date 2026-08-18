module MifParser
  class Document
    include Enumerable

    attr_reader :elements

    def initialize(elements = [])
      @elements = elements
    end

    def each(&block)
      elements.each(&block)
    end

    def paragraphs
      elements.select { |element| element.is_a?(Paragraph) }
    end

    def tables
      elements.select { |element| element.is_a?(Table) }
    end

    def empty?
      elements.empty?
    end

    def size
      elements.size
    end
  end
end