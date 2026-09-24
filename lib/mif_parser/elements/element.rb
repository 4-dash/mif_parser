# frozen_string_literal: true

require_relative "../format"
require_relative "../html_text"

module MifParser
  class Element
    attr_reader :tag, :format

    def initialize(tag: nil, format: nil)
      @tag = tag
      @format = format || Format.new
    end

    def type
      :unknown
    end

    def text
      nil
    end

    def heading?
      false
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

    def cell?
      type == :cell
    end

    def image?
      type == :image
    end

    def heading_level
      nil
    end

    def list_level
      nil
    end

    def list_marker
      nil
    end

    def list_type
      nil
    end

    def import_text
      text.to_s.strip
    end

    alias clean_text import_text

    def html_text
      import_text
    end
  end
end
