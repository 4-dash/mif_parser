# frozen_string_literal: true

require_relative "test_helper"

class ParserTest < Minitest::Test
  def test_parses_paragraph_tag_number_and_text
    mif = <<~'MIF'
      <MIFFile 7.00>

      <Para
        <PgfTag `030 Title3'>
        <PgfNumString `2.1.1\t'>
        <ParaLine
          <String `Wire Electrode Selection'>
        >
      >
    MIF

    document = MifParser.parse(mif)

    assert_equal 1, document.size

    paragraph = document.elements.first

    assert_instance_of MifParser::Paragraph, paragraph

    assert_equal "030 Title3", paragraph.tag
    assert_equal "2.1.1\t", paragraph.number_string
    assert_equal "Wire Electrode Selection", paragraph.raw_text
  end

  def test_paragraph_inherits_previous_tag
    mif = <<~'MIF'
      <MIFFile 7.00>

      <Para
        <PgfTag `Body'>
        <ParaLine
          <String `First paragraph'>
        >
      >

      <Para
        <ParaLine
          <String `Second paragraph'>
        >
      >
    MIF

    document = MifParser.parse(mif)

    assert_equal 2, document.size

    first = document.elements[0]
    second = document.elements[1]

    assert_equal "Body", first.tag
    assert_equal "Body", second.tag

    assert_equal "First paragraph", first.raw_text
    assert_equal "Second paragraph", second.raw_text
  end

  def test_combines_strings_and_chars
    mif = <<~'MIF'
      <MIFFile 7.00>

      <Para
        <PgfTag `Body'>
        <ParaLine
          <String `Hello'>
          <Char Tab>
          <String `world'>
        >
        <ParaLine
          <Char HardReturn>
          <String `next line'>
        >
      >
    MIF

    document = MifParser.parse(mif)

    paragraph = document.elements.first

    assert_equal(
      "Hello\tworld\nnext line",
      paragraph.raw_text
    )
  end

  def test_multiple_para_lines_still_create_one_paragraph
    mif = <<~'MIF'
      <MIFFile 7.00>

      <Para
        <PgfTag `Body'>
        <ParaLine
          <String `First part. '>
        >
        <ParaLine
          <String `Second part. '>
        >
        <ParaLine
          <String `Third part.'>
        >
      >
    MIF

    document = MifParser.parse(mif)

    assert_equal 1, document.size

    assert_equal(
      "First part. Second part. Third part.",
      document.elements.first.raw_text
    )
  end

  def test_empty_paragraphs_are_not_added
    mif = <<~'MIF'
      <MIFFile 7.00>

      <Para
        <PgfTag `Body'>
        <ParaLine
          <String `'>
        >
      >

      <Para
        <PgfTag `Body'>
        <ParaLine
          <String `   '>
        >
      >
    MIF

    document = MifParser.parse(mif)

    assert_empty document
  end

  def test_decodes_mif_string_escapes
    mif = <<~'MIF'
      <MIFFile 7.00>

      <Para
        <PgfTag `Body'>
        <ParaLine
          <String `Apostrophe: \'. Backtick: \`. Backslash: \\.'>
        >
      >
    MIF

    document = MifParser.parse(mif)

    assert_equal(
      "Apostrophe: '. Backtick: `. Backslash: \\.",
      document.elements.first.raw_text
    )
  end

  def test_unknown_escape_is_preserved
    mif = <<~'MIF'
      <MIFFile 7.00>

      <Para
        <PgfTag `Body'>
        <ParaLine
          <String `Legacy \x41 value'>
        >
      >
    MIF

    document = MifParser.parse(mif)

    assert_equal(
      "Legacy \\x41 value",
      document.elements.first.raw_text
    )
  end

  def test_parses_numbered_list_as_ordered_list
    mif = <<~'MIF'
      <MIFFile 7.00>

      <Para
        <PgfTag `Numbered List'>
        <PgfNumString `1.\t'>
        <ParaLine
          <String `First list item'>
        >
      >
    MIF

    document = MifParser.parse(mif)

    assert_equal 1, document.size

    list = document.elements.first

    assert_instance_of MifParser::List, list

    assert_equal "Numbered List", list.tag
    assert_equal "1.\t", list.number_string
    assert_equal "First list item", list.raw_text

    assert_equal :ol, list.list_type
    assert_equal 1, list.list_level
    assert_equal "1.", list.list_marker
  end

  def test_parses_parenthesized_number_as_ordered_list
    mif = <<~'MIF'
      <MIFFile 7.00>

      <Para
        <PgfTag `050 Title5'>
        <PgfNumString `(1)\t'>
        <ParaLine
          <String `Problem'>
        >
      >
    MIF

    document = MifParser.parse(mif)

    list = document.elements.first

    assert_instance_of MifParser::List, list

    assert_equal :ol, list.list_type
    assert_equal 0, list.list_level
    assert_equal "(1)", list.list_marker
    assert_equal "Problem", list.raw_text
  end

  def test_parses_bullet_list_as_unordered_list
    mif = <<~'MIF'
      <MIFFile 7.00>

      <Para
        <PgfTag `Bullet'>
        <PgfNumString `•\t'>
        <ParaLine
          <String `Bullet item'>
        >
      >
    MIF

    document = MifParser.parse(mif)

    list = document.elements.first

    assert_instance_of MifParser::List, list

    assert_equal :ul, list.list_type
    assert_equal 1, list.list_level
    assert_equal "•", list.list_marker
    assert_equal "Bullet item", list.raw_text
  end

  def test_parses_alphabetic_ordered_list
    mif = <<~'MIF'
      <MIFFile 7.00>

      <Para
        <PgfTag `Ordered List'>
        <PgfNumString `A)\t'>
        <ParaLine
          <String `Alphabetic item'>
        >
      >
    MIF

    document = MifParser.parse(mif)

    list = document.elements.first

    assert_instance_of MifParser::List, list

    assert_equal :ol, list.list_type
    assert_equal "A)", list.list_marker
  end

  def test_list_tag_is_inherited
    mif = <<~'MIF'
      <MIFFile 7.00>

      <Para
        <PgfTag `220 List n=1)'>
        <PgfNumString `1)\t'>
        <ParaLine
          <String `First item'>
        >
      >

      <Para
        <PgfNumString `2)\t'>
        <ParaLine
          <String `Second item'>
        >
      >
    MIF

    document = MifParser.parse(mif)

    assert_equal 2, document.size

    first = document.elements[0]
    second = document.elements[1]

    assert_instance_of MifParser::List, first
    assert_instance_of MifParser::List, second

    assert_equal "220 List n=1)", first.tag
    assert_equal "220 List n=1)", second.tag

    assert_equal "1)", first.list_marker
    assert_equal "2)", second.list_marker
  end

  def test_bullet_style_without_number_string_remains_paragraph
    mif = <<~'MIF'
      <MIFFile 7.00>

      <Para
        <PgfTag `Bullet'>
        <ParaLine
          <String `No number string'>
        >
      >
    MIF

    document = MifParser.parse(mif)

    element = document.elements.first

    assert_instance_of MifParser::Paragraph, element
    refute_instance_of MifParser::List, element

    assert_equal "Bullet", element.tag
    assert_equal "No number string", element.raw_text
  end

  def test_document_separates_paragraphs_and_lists
    mif = <<~'MIF'
      <MIFFile 7.00>

      <Para
        <PgfTag `Body'>
        <ParaLine
          <String `Normal paragraph'>
        >
      >

      <Para
        <PgfTag `Numbered List'>
        <PgfNumString `1.\t'>
        <ParaLine
          <String `List item'>
        >
      >
    MIF

    document = MifParser.parse(mif)

    assert_equal 2, document.size
    assert_equal 1, document.paragraphs.size
    assert_equal 1, document.lists.size

    assert_instance_of(
      MifParser::Paragraph,
      document.paragraphs.first
    )

    assert_instance_of(
      MifParser::List,
      document.lists.first
    )
  end

  def test_table_anchor_is_resolved_at_original_position
    mif = <<~'MIF'
      <MIFFile 7.00>

      <Para
        <PgfTag `Body'>
        <ParaLine
          <String `Before table'>
          <ATbl 42>
          <String `After table'>
        >
      >

      <Tbl
        <TblID 42>
        <TblTag `Basic'>
        <Row
          <Cell
            <Para
              <ParaLine
                <String `A1'>
              >
            >
          >
          <Cell
            <Para
              <ParaLine
                <String `B1'>
              >
            >
          >
        >
      >
    MIF

    document = MifParser.parse(mif)

    assert_equal 3, document.size

    before = document.elements[0]
    table = document.elements[1]
    after = document.elements[2]

    assert_instance_of MifParser::Paragraph, before
    assert_instance_of MifParser::Table, table
    assert_instance_of MifParser::Paragraph, after

    assert_equal "Before table", before.raw_text
    assert_equal 42, table.id
    assert_equal "Basic", table.tag
    assert_equal [%w[A1 B1]], table.rows
    assert_equal "After table", after.raw_text

    assert_equal "Body", before.tag
    assert_nil after.tag
  end
end
