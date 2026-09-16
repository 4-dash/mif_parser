# frozen_string_literal: true

module MifParser
  # Optional HTML view of TextRuns. Plain text and Format stay the
  # source of truth; callers can render Markdown or anything else.
  module HtmlText
    extend self

    def from_runs(runs)
      chunks = []

      Array(runs).each do |run|
        text = run.text.to_s
        next if text.empty?

        flags = formatting_flags(run.format)
        last = chunks.last

        if last && last[:flags] == flags
          last[:text] += text
        else
          chunks << { text: text, flags: flags }
        end
      end

      chunks.map do |chunk|
        wrap(escape(chunk[:text]), chunk[:flags])
      end.join
    end

    private

    def formatting_flags(format)
      [
        format&.bold?,
        format&.italic?,
        format&.underline?
      ]
    end

    def wrap(text, flags)
      bold, italic, underline = flags
      result = text

      result = "<u>#{result}</u>" if underline
      result = "<i>#{result}</i>" if italic
      result = "<b>#{result}</b>" if bold

      result
    end

    def escape(text)
      text
        .gsub("&", "&amp;")
        .gsub("<", "&lt;")
        .gsub(">", "&gt;")
    end
  end
end
