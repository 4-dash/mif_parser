# frozen_string_literal: true

module MifParser
  class Cell < Element
    include Enumerable

    attr_reader :elements

    def initialize(elements: [], tag: nil)
      super(tag: tag)

      @elements = elements
    end

    def each(&block)
      elements.each(&block)
    end

    def empty?
      elements.empty?
    end

    def text
      elements.map do |element|
        cell_element_text(element)
      end.join("\n")
    end

    def import_text
      text.to_s.strip
    end

    def html_text
      elements.map do |element|
        if element.respond_to?(:html_text)
          element.html_text
        else
          cell_element_text(element)
        end
      end.join("\n")
    end

    private

    def cell_element_text(element)
      if element.respond_to?(:import_text)
        element.import_text
      elsif element.respond_to?(:raw_text)
        element.raw_text.to_s.strip
      else
        element.to_s
      end
    end
  end
end
