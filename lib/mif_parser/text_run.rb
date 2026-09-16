# frozen_string_literal: true

require_relative "format"

module MifParser
  # One stretch of paragraph text with a single resolved format.
  class TextRun
    attr_reader :text, :format

    def initialize(text:, format: nil)
      @text = text.to_s
      @format = format || Format.new
    end

    def bold?
      format.bold?
    end

    def italic?
      format.italic?
    end

    def underline?
      format.underline?
    end

    def self.drop_prefix(runs, original_text, remaining_text)
      runs = Array(runs)
      original_text = original_text.to_s
      remaining_text = remaining_text.to_s

      return runs if remaining_text == original_text
      return runs unless original_text.end_with?(remaining_text)

      remaining = original_text.length - remaining_text.length
      dropped = []

      runs.each do |run|
        value = run.text.to_s

        if remaining <= 0
          dropped << run
          next
        end

        if remaining >= value.length
          remaining -= value.length
          next
        end

        dropped << new(
          text: value[remaining..],
          format: run.format
        )
        remaining = 0
      end

      dropped
    end
  end
end
