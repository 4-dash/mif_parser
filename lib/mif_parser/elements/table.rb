# frozen_string_literal: true

module MifParser
  class Table < Element
    attr_reader :id, :title, :header_rows, :body_rows, :footer_rows

    def initialize(
      id:,
      tag: nil,
      title: [],
      header_rows: [],
      body_rows: [],
      footer_rows: [],
      rows: nil
    )
      super(tag: tag)

      @id = id
      @title = title
      @header_rows = header_rows
      @body_rows = body_rows
      @footer_rows = footer_rows

      if rows && header_rows.empty? && body_rows.empty? && footer_rows.empty?
        @body_rows = rows
      end
    end

    def rows
      header_rows + body_rows + footer_rows
    end
  end
end
