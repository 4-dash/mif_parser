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
