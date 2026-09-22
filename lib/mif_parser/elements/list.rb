# frozen_string_literal: true

require_relative "element"
require_relative "../text_run"
require_relative "../html_text"

module MifParser
  class List < Element
    attr_reader :number_string,
                :raw_text,
                :list_type,
                :list_level,
                :list_marker,
                :runs

    def initialize(
      text:,
      list_type:,
      tag: nil,
      number_string: nil,
      list_level: nil,
      list_marker: nil,
      format: nil,
      runs: nil
    )
      super(tag: tag, format: format)

      @raw_text = text.to_s
      @number_string = number_string
      @list_type = list_type
      @list_level = list_level
      @list_marker = list_marker
      @runs = runs || default_runs
    end

    def type
      :list
    end

    def text
      raw_text.to_s.strip
    end

    def html_text
      HtmlText.from_runs(runs)
    end

    private

    def default_runs
      return [] if @raw_text.empty?

      [
        TextRun.new(
          text: @raw_text,
          format: format
        )
      ]
    end
  end
end
