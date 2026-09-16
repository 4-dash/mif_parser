# frozen_string_literal: true

require_relative "test_helper"

class FormatTest < Minitest::Test
  def test_merge_overlays_whitelisted_properties
    base = MifParser::Format.new(
      "FWeight" => "Regular",
      "FAngle" => "Italic"
    )
    overlay = MifParser::Format.new(
      "FWeight" => "Bold"
    )

    merged = base.merge(overlay)

    assert_equal "Bold", merged["FWeight"]
    assert_equal "Italic", merged["FAngle"]
    assert merged.bold?
    assert merged.italic?
  end

  def test_underline_ignores_none_tokens
    refute MifParser::Format.new("FUnderlining" => "FNoUnderlining").underline?
    refute MifParser::Format.new("FUnderlining" => "No").underline?
    assert MifParser::Format.new("FUnderlining" => "FSingle").underline?
  end

  def test_html_text_wraps_combined_flags
    run = MifParser::TextRun.new(
      text: "Hi",
      format: MifParser::Format.new(
        "FWeight" => "Bold",
        "FAngle" => "Italic",
        "FUnderlining" => "FSingle"
      )
    )

    assert_equal(
      "<b><i><u>Hi</u></i></b>",
      MifParser::HtmlText.from_runs([run])
    )
  end

  def test_drop_prefix_removes_leading_marker_from_runs
    format = MifParser::Format.new("FWeight" => "Bold")
    runs = [
      MifParser::TextRun.new(text: "1) ", format: format),
      MifParser::TextRun.new(text: "Hello", format: format)
    ]

    dropped = MifParser::TextRun.drop_prefix(
      runs,
      "1) Hello",
      "Hello"
    )

    assert_equal 1, dropped.length
    assert_equal "Hello", dropped.first.text
    assert dropped.first.bold?
  end
end
