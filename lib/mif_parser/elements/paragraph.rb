# frozen_string_literal: true

require_relative "element"
require_relative "../text_run"
require_relative "../html_text"

module MifParser
  class Paragraph < Element
    attr_reader :number_string, :raw_text, :runs

    def initialize(
      text:,
      tag: nil,
      number_string: nil,
      format: nil,
      runs: nil
    )
      super(tag: tag, format: format)

      @raw_text = text.to_s
      @number_string = number_string
      @runs = runs || default_runs
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
