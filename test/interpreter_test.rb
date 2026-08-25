# frozen_string_literal: true

require_relative "test_helper"

class InterpreterTest < Minitest::Test
  def test_heading_from_heading_tag
    paragraph = MifParser::Paragraph.new(
      tag: "Heading2",
      text: "Installation"
    )

    result = paragraph.interpret

    assert result.heading?
    assert_equal :heading, result.type
    assert_equal 1, result.heading_level
    assert_equal "Installation", result.text
  end

  def test_title_tag_is_heading
    paragraph = MifParser::Paragraph.new(
      tag: "Title",
      text: "Document Title"
    )

    result = paragraph.interpret

    assert result.heading?
    assert_equal 0, result.heading_level
  end

  def test_chapter_title_is_heading
    paragraph = MifParser::Paragraph.new(
      tag: "ChapterTitle",
      text: "Introduction"
    )

    result = paragraph.interpret

    assert result.heading?
    assert_equal 0, result.heading_level
  end

  def test_numbered_heading_uses_number_string
    paragraph = MifParser::Paragraph.new(
      tag: "CustomStyle",
      number_string: "2.3.4",
      text: "Deep heading"
    )

    result = paragraph.interpret

    assert result.heading?
    assert_equal 2, result.heading_level
  end

  def test_numeric_level_overrides_tag_level
    paragraph = MifParser::Paragraph.new(
      tag: "040 Title4",
      number_string: "4.3\t",
      text: "Wire Breakage Tests"
    )

    result = paragraph.interpret

    assert result.heading?

    # Existing behavior:
    # 4.3 -> two numeric components -> level 1
    assert_equal 1, result.heading_level
  end

  def test_parenthesized_number_is_list
    paragraph = MifParser::Paragraph.new(
      tag: "050 Title5",
      number_string: "(1)\t",
      text: "Problem"
    )

    result = paragraph.interpret

    assert result.list?
    refute result.heading?

    assert_equal 0, result.list_level
    assert_equal "(1)", result.list_marker
    assert_equal "Problem", result.text
  end

  def test_list_style_is_list
    paragraph = MifParser::Paragraph.new(
      tag: "220 List n=1)",
      number_string: "1)\t",
      text: "First item"
    )

    result = paragraph.interpret

    assert result.list?
    assert_equal 1, result.list_level
    assert_equal "1)", result.list_marker
  end

  def test_numbered_list_is_not_heading
    paragraph = MifParser::Paragraph.new(
      tag: "Numbered List",
      number_string: "1.\t",
      text: "List item"
    )

    result = paragraph.interpret

    assert result.list?
    refute result.heading?

    assert_equal "1.", result.list_marker
  end

  def test_body_is_body
    paragraph = MifParser::Paragraph.new(
      tag: "Body",
      text: "Normal paragraph"
    )

    result = paragraph.interpret

    assert result.body?
    assert_equal :body, result.type
    assert_equal "Normal paragraph", result.text
  end

  def test_visible_number_alone_does_not_make_custom_style_a_heading
    paragraph = MifParser::Paragraph.new(
      tag: "CustomStyle",
      text: "2.1 Custom Numbered Subheading"
    )

    result = paragraph.interpret

    assert result.body?
    refute result.heading?
  end

  def test_visible_decimal_in_body_is_not_heading
    paragraph = MifParser::Paragraph.new(
      tag: "Body",
      text: "3.1 volts are required."
    )

    result = paragraph.interpret

    assert result.body?
  end

  def test_figure_number_is_not_numbered_heading
    paragraph = MifParser::Paragraph.new(
      tag: "600 Fig Title",
      number_string: "Fig. 5.2.1  ",
      text: "Wire Feed System"
    )

    result = paragraph.interpret

    assert result.body?
    refute result.heading?
  end

  def test_numbered_heading_detection_can_be_disabled
    interpreter =
      MifParser::Interpreter.new(
        numbered_headings: false
      )

    paragraph = MifParser::Paragraph.new(
      tag: "CustomStyle",
      number_string: "2.3",
      text: "Custom heading"
    )

    result = interpreter.interpret(paragraph)

    assert result.body?
    refute result.heading?
  end

  def test_table_interpretation
    table = MifParser::Table.new(
      id: 10,
      tag: "Basic",
      rows: [
        %w[A B],
        %w[C D]
      ]
    )

    result = table.interpret

    assert result.table?
    assert_equal :table, result.type

    assert_equal(
      [
        %w[A B],
        %w[C D]
      ],
      result.rows
    )
  end
end
