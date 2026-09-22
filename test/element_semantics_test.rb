# frozen_string_literal: true

require_relative "test_helper"

class ElementSemanticsTest < Minitest::Test
  def test_heading_from_heading_tag
    paragraph = MifParser::Paragraph.new(
      tag: "Heading2",
      text: "Installation"
    )

    assert paragraph.heading?
    assert_equal :heading, paragraph.type
    assert_equal 1, paragraph.heading_level
    assert_equal "Installation", paragraph.text
    assert_equal "Installation", paragraph.html_text
  end

  def test_html_text_uses_runs
    paragraph = MifParser::Paragraph.new(
      tag: "Body",
      text: "The power feed",
      format: MifParser::Format.new("FWeight" => "Bold")
    )

    assert_equal "The power feed", paragraph.text
    assert_equal "<b>The power feed</b>", paragraph.html_text
  end

  def test_title_tag_is_heading
    paragraph = MifParser::Paragraph.new(
      tag: "Title",
      text: "Document Title"
    )

    assert paragraph.heading?
    assert_equal 0, paragraph.heading_level
  end

  def test_chapter_title_is_heading
    paragraph = MifParser::Paragraph.new(
      tag: "ChapterTitle",
      text: "Introduction"
    )

    assert paragraph.heading?
    assert_equal 0, paragraph.heading_level
  end

  def test_numbered_heading_uses_number_string
    paragraph = MifParser::Paragraph.new(
      tag: "CustomStyle",
      number_string: "2.3.4",
      text: "Deep heading"
    )

    assert paragraph.heading?
    assert_equal 2, paragraph.heading_level
  end

  def test_heading_tag_level_wins_over_number_string
    paragraph = MifParser::Paragraph.new(
      tag: "040 Title4",
      number_string: "4.3\t",
      text: "Wire Breakage Tests"
    )

    assert paragraph.heading?
    assert_equal 3, paragraph.heading_level
  end

  def test_ordered_list_semantics
    list = MifParser::List.new(
      tag: "220 List n=1)",
      number_string: "1)\t",
      text: "First item",
      list_type: :ol,
      list_level: 1,
      list_marker: "1)"
    )

    assert list.list?
    refute list.heading?

    assert_equal :list, list.type
    assert_equal :ol, list.list_type
    assert_equal 1, list.list_level
    assert_equal "1)", list.list_marker
    assert_equal "First item", list.text
    assert_equal "First item", list.html_text
  end

  def test_unordered_list_semantics
    list = MifParser::List.new(
      tag: "Bullet",
      number_string: "•\t",
      text: "Bullet item",
      list_type: :ul,
      list_level: 1,
      list_marker: "•"
    )

    assert list.list?
    refute list.heading?

    assert_equal :list, list.type
    assert_equal :ul, list.list_type
    assert_equal 1, list.list_level
    assert_equal "•", list.list_marker
    assert_equal "Bullet item", list.text
  end

  def test_parenthesized_list_semantics
    list = MifParser::List.new(
      tag: "050 Title5",
      number_string: "(1)\t",
      text: "Problem",
      list_type: :ol,
      list_level: 0,
      list_marker: "(1)"
    )

    assert list.list?
    refute list.heading?

    assert_equal :ol, list.list_type
    assert_equal 0, list.list_level
    assert_equal "(1)", list.list_marker
    assert_equal "Problem", list.text
  end

  def test_body_is_body
    paragraph = MifParser::Paragraph.new(
      tag: "Body",
      text: "Normal paragraph"
    )

    assert paragraph.body?
    assert_equal :body, paragraph.type
    assert_equal "Normal paragraph", paragraph.text
  end

  def test_visible_number_alone_does_not_make_custom_style_a_heading
    paragraph = MifParser::Paragraph.new(
      tag: "CustomStyle",
      text: "2.1 Custom Numbered Subheading"
    )

    assert paragraph.body?
    refute paragraph.heading?
  end

  def test_visible_decimal_in_body_is_not_heading
    paragraph = MifParser::Paragraph.new(
      tag: "Body",
      text: "3.1 volts are required."
    )

    assert paragraph.body?
  end

  def test_figure_number_is_not_numbered_heading
    paragraph = MifParser::Paragraph.new(
      tag: "600 Fig Title",
      number_string: "Fig. 5.2.1  ",
      text: "Wire Feed System"
    )

    assert paragraph.body?
    refute paragraph.heading?
  end

  def test_table_semantics
    cell_a = MifParser::Cell.new(
      elements: [MifParser::Paragraph.new(text: "A")]
    )
    cell_b = MifParser::Cell.new(
      elements: [MifParser::Paragraph.new(text: "B")]
    )
    cell_c = MifParser::Cell.new(
      elements: [MifParser::Paragraph.new(text: "C")]
    )
    cell_d = MifParser::Cell.new(
      elements: [MifParser::Paragraph.new(text: "D")]
    )

    table = MifParser::Table.new(
      id: 10,
      tag: "Basic",
      rows: [
        [cell_a, cell_b],
        [cell_c, cell_d]
      ]
    )

    assert table.table?
    assert_equal :table, table.type
    assert_equal "A", table.rows[0][0].text
  end

  def test_cell_semantics
    cell = MifParser::Cell.new(
      elements: [MifParser::Paragraph.new(text: "A1")]
    )

    assert cell.cell?
    assert_equal :cell, cell.type
    assert_equal "A1", cell.text
  end
end
