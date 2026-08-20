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
      elements_of(Paragraph)
    end

    def tables
      elements_of(Table)
    end

    def empty?
      elements.empty?
    end

    def size
      elements.size
    end

    private

    def elements_of(type)
      elements.select do |element|
        element.is_a?(type)
      end
    end
  end
end