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
    assert_equal 0, list.list_level
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
    assert_equal 0, list.list_level
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
    assert_equal [%w[A1 B1]], cell_texts(table)
    assert_instance_of MifParser::Cell, table.rows[0][0]
    assert_instance_of MifParser::Paragraph, table.rows[0][0].elements.first
    assert_equal "After table", after.raw_text

    assert_equal "Body", before.tag
    assert_nil after.tag
  end

  def test_table_cell_contains_two_paragraph_elements
    document = parse_fixture("tables.mif")
    table = document.tables.first
    cell = table.rows[0][0]

    assert_equal 2, cell.elements.size
    assert_equal "A1", cell.elements[0].raw_text
    assert_equal "Second paragraph", cell.elements[1].raw_text
    assert_equal "A1\nSecond paragraph", cell.text
  end

  def test_framemaker_like_table_with_header_body_and_cell_content
    mif = <<~'MIF'
      <MIFFile 7.00>
      <Tbls
        <Tbl
          <TblID 1>
          <TblTag `Format A'>
          <TblTitle
            <TblTitleContent
              <Para
                <ParaLine
                  <String `Parts'>
                >
              >
            >
          >
          <TblH
            <Row
              <Cell
                <CellContent
                  <Para
                    <ParaLine
                      <String `Name'>
                    >
                  >
                >
              >
              <Cell
                <CellContent
                  <Para
                    <ParaLine
                      <String `Value'>
                    >
                  >
                >
              >
            >
          >
          <TblBody
            <Row
              <Cell
                <CellContent
                  <Para
                    <ParaLine
                      <String `Alpha'>
                    >
                  >
                >
              >
              <Cell
                <CellContent
                  <Para
                    <ParaLine
                      <String `1'>
                    >
                  >
                >
              >
            >
          >
        >
      >
      <Para
        <PgfTag `Body'>
        <ParaLine
          <String `See table:'>
          <ATbl 1>
        >
      >
    MIF

    document = MifParser.parse(mif)

    assert_equal 2, document.size
    assert_equal "See table:", document.elements[0].raw_text

    table = document.elements[1]
    assert_instance_of MifParser::Table, table
    assert_equal "Format A", table.tag
    assert_equal "Parts", table.title.first.raw_text
    assert_equal ["Name", "Value"], table.header_rows.first.map(&:text)
    assert_equal ["Alpha", "1"], table.body_rows.first.map(&:text)
    assert_equal(
      [%w[Name Value], %w[Alpha 1]],
      cell_texts(table)
    )
  end

  def test_empty_and_self_closing_cells
    mif = <<~'MIF'
      <Para
        <ParaLine
          <ATbl 7>
        >
      >
      <Tbl
        <TblID 7>
        <Row
          <Cell
            <Para
              <ParaLine
                <String `left'>
              >
            >
          >
          <Cell
          >
          <Cell>
          <Cell
            <Para
              <ParaLine
                <String `right'>
              >
            >
          >
        >
      >
    MIF

    table = MifParser.parse(mif).tables.first
    texts = table.rows.first.map(&:text)

    assert_equal ["left", "", "", "right"], texts
    assert_empty table.rows.first[1].elements
    assert_empty table.rows.first[2].elements
  end

  def test_inline_cell_on_one_line
    mif = <<~'MIF'
      <Para
        <ParaLine
          <ATbl 4>
        >
      >
      <Tbl
        <TblID 4>
        <Row
          <Cell <Para <ParaLine <String `inline'> > > >
        >
      >
    MIF

    table = MifParser.parse(mif).tables.first

    assert_equal [["inline"]], cell_texts(table)
    assert_instance_of MifParser::Paragraph, table.rows[0][0].elements.first
  end

  def test_list_inside_table_cell
    mif = <<~'MIF'
      <Para
        <ParaLine
          <ATbl 5>
        >
      >
      <Tbl
        <TblID 5>
        <Row
          <Cell
            <Para
              <PgfTag `Numbered List'>
              <PgfNumString `1.\t'>
              <ParaLine
                <String `First item'>
              >
            >
            <Para
              <PgfNumString `2.\t'>
              <ParaLine
                <String `Second item'>
              >
            >
          >
        >
      >
    MIF

    cell = MifParser.parse(mif).tables.first.rows[0][0]

    assert_equal 2, cell.elements.size
    assert_instance_of MifParser::List, cell.elements[0]
    assert_instance_of MifParser::List, cell.elements[1]
    assert_equal :ol, cell.elements[0].list_type
    assert_equal :ol, cell.elements[1].list_type
    assert_equal "1.", cell.elements[0].list_marker
    assert_equal "2.", cell.elements[1].list_marker
    assert_equal "First item", cell.elements[0].raw_text
    assert_equal "Second item", cell.elements[1].raw_text
  end

  def test_missing_table_drops_anchor
    mif = <<~'MIF'
      <Para
        <PgfTag `Body'>
        <ParaLine
          <String `before'>
          <ATbl 99>
          <String `after'>
        >
      >
    MIF

    document = MifParser.parse(mif)

    assert_equal 2, document.size
    assert_empty document.tables
    assert_equal "before", document.elements[0].raw_text
    assert_equal "after", document.elements[1].raw_text
  end

  def test_unreferenced_table_is_not_in_document
    mif = <<~'MIF'
      <Para
        <PgfTag `Body'>
        <ParaLine
          <String `before'>
        >
      >
      <Tbl
        <TblID 5>
        <Row
          <Cell
            <Para
              <ParaLine
                <String `hidden'>
              >
            >
          >
        >
      >
      <Para
        <ParaLine
          <String `after'>
        >
      >
    MIF

    document = MifParser.parse(mif)

    assert_equal 2, document.size
    assert_empty document.tables
    assert_equal "before", document.elements[0].raw_text
    assert_equal "after", document.elements[1].raw_text
  end

  def test_catalog_format_is_applied_to_paragraphs
    mif = <<~'MIF'
      <MIFFile 7.00>

      <PgfCatalog
        <Pgf
          <PgfTag `001 Title2'>
          <PgfFont
            <FWeight `Bold'>
            <FAngle `Regular'>
            <FUnderlining FNoUnderlining>
          >
        >
      >

      <Para
        <PgfTag `001 Title2'>
        <ParaLine
          <String `Bold from catalog'>
        >
      >
    MIF

    document = MifParser.parse(mif)
    paragraph = document.elements.first

    assert_equal "Bold", document.catalog["001 Title2"]["FWeight"]
    assert_equal "Bold", paragraph.format["FWeight"]
    assert paragraph.format.bold?
    refute paragraph.format.italic?
    refute paragraph.format.underline?
    assert_equal "Bold from catalog", paragraph.raw_text
    assert_equal "Bold from catalog", paragraph.text
    assert_equal "<b>Bold from catalog</b>", paragraph.html_text
  end

  def test_local_pgf_overrides_catalog_format
    mif = <<~'MIF'
      <MIFFile 7.00>

      <PgfCatalog
        <Pgf
          <PgfTag `Body'>
          <PgfFont
            <FWeight `Regular'>
            <FAngle `Regular'>
            <FUnderlining FNoUnderlining>
          >
        >
      >

      <Para
        <PgfTag `Body'>
        <Pgf
          <PgfFont
            <FWeight `Bold'>
          >
        >
        <ParaLine
          <String `Local bold'>
        >
      >
    MIF

    paragraph = MifParser.parse(mif).elements.first

    assert_equal "Bold", paragraph.format["FWeight"]
    assert paragraph.format.bold?
    assert_equal "Local bold", paragraph.text
    assert_equal "<b>Local bold</b>", paragraph.html_text
  end

  def test_inline_font_creates_runs_without_changing_plain_text
    mif = <<~'MIF'
      <MIFFile 7.00>

      <Para
        <PgfTag `Body'>
        <ParaLine
          <String `The '>
          <Font
            <FWeight `Bold'>
          >
          <String `power'>
          <Font
            <FWeight `Regular'>
          >
          <String ` feed'>
        >
      >
    MIF

    paragraph = MifParser.parse(mif).elements.first

    assert_equal "The power feed", paragraph.raw_text
    assert_equal "The power feed", paragraph.text
    assert_equal "The <b>power</b> feed", paragraph.html_text

    assert_equal 3, paragraph.runs.length
    assert_equal "The ", paragraph.runs[0].text
    refute paragraph.runs[0].bold?
    assert_equal "power", paragraph.runs[1].text
    assert paragraph.runs[1].bold?
    assert_equal " feed", paragraph.runs[2].text
    refute paragraph.runs[2].bold?
  end

  def test_empty_font_resets_to_paragraph_format
    mif = <<~'MIF'
      <MIFFile 7.00>

      <Para
        <PgfTag `100 Para'>
        <ParaLine
          <Font
            <FTag `'>
            <FPlatformName `W.Arial.R.700'>
            <FFamily `Arial'>
            <FWeight `Bold'>
            <FEncoding `FrameRoman'>
            <FLocked No>
          >
          <String `(Example)'>
          <Font
            <FTag `'>
            <FLocked No>
          >
          <String ` When machining SKD11, 40t with '>
          <Font
            <FTag `'>
            <FPlatformName `W.Symbol.R.400'>
            <FFamily `Symbol'>
            <FEncoding `FrameRoman'>
            <FLanguage NoLanguage>
            <FLocked No>
          >
          <String `f'>
          <Font
            <FTag `'>
            <FLocked No>
          >
          <String `0.2 wire and using the Paraol 250 EDM oil'>
        >
      >

      <Para
        <PgfTag `100 Para'>
        <Pgf
          <PgfLIndent  29.0 mm>
        >
        <ParaLine
          <Font
            <FTag `'>
            <FPlatformName `W.Arial.R.700'>
            <FFamily `Arial'>
            <FWeight `Bold'>
            <FEncoding `FrameRoman'>
            <FLocked No>
          >
          <String `Note)'>
          <Font
            <FTag `'>
            <FLocked No>
          >
          <String ` This table is a guideline.Machining characteristics may vary with the specific workpiece material and'>
        >
      >
    MIF

    document = MifParser.parse(mif)
    example = document.elements[0]
    note = document.elements[1]

    assert_equal(
      "<b>(Example)</b> When machining SKD11, 40t with f0.2 wire and using the Paraol 250 EDM oil",
      example.html_text
    )
    refute example.format.bold?
    assert example.runs[0].bold?
    refute example.runs[1].bold?

    assert_equal(
      "<b>Note)</b> This table is a guideline.Machining characteristics may vary with the specific workpiece material and",
      note.html_text
    )
    refute note.format.bold?
    assert note.runs[0].bold?
    refute note.runs[1].bold?
  end

  def test_italic_and_underline_from_catalog
    mif = <<~'MIF'
      <MIFFile 7.00>

      <PgfCatalog
        <Pgf
          <PgfTag `Emphasis'>
          <PgfFont
            <FWeight `Regular'>
            <FAngle `Italic'>
            <FUnderlining FSingle>
          >
        >
      >

      <Para
        <PgfTag `Emphasis'>
        <ParaLine
          <String `Note'>
        >
      >
    MIF

    paragraph = MifParser.parse(mif).elements.first

    assert paragraph.format.italic?
    assert paragraph.format.underline?
    refute paragraph.format.bold?
    assert_equal "<i><u>Note</u></i>", paragraph.html_text
  end

  def test_inherited_tag_uses_catalog_format
    mif = <<~'MIF'
      <MIFFile 7.00>

      <PgfCatalog
        <Pgf
          <PgfTag `Body'>
          <PgfFont
            <FWeight `Bold'>
          >
        >
      >

      <Para
        <PgfTag `Body'>
        <ParaLine
          <String `First'>
        >
      >

      <Para
        <ParaLine
          <String `Second'>
        >
      >
    MIF

    document = MifParser.parse(mif)

    assert document.elements[0].format.bold?
    assert document.elements[1].format.bold?
    assert_equal "Body", document.elements[1].tag
  end

  def test_unlisted_font_properties_are_ignored
    mif = <<~'MIF'
      <MIFFile 7.00>

      <PgfCatalog
        <Pgf
          <PgfTag `Body'>
          <PgfFont
            <FWeight `Bold'>
            <FFamily `Arial'>
            <FSize  10.5 pt>
          >
        >
      >

      <Para
        <PgfTag `Body'>
        <ParaLine
          <String `Hello'>
        >
      >
    MIF

    paragraph = MifParser.parse(mif).elements.first

    assert_equal({ "FWeight" => "Bold" }, paragraph.format.to_h)
    assert_nil paragraph.format["FFamily"]
    assert_nil paragraph.format["FSize"]
  end

  def test_html_text_escapes_special_characters
    mif = <<~'MIF'
      <MIFFile 7.00>

      <Para
        <PgfTag `Body'>
        <Pgf
          <PgfFont
            <FWeight `Bold'>
          >
        >
        <ParaLine
          <String `A < B & C'>
        >
      >
    MIF

    paragraph = MifParser.parse(mif).elements.first

    assert_equal "A < B & C", paragraph.raw_text
    assert_equal "<b>A &lt; B &amp; C</b>", paragraph.html_text
  end

  def test_list_items_receive_catalog_format
    mif = <<~'MIF'
      <MIFFile 7.00>

      <PgfCatalog
        <Pgf
          <PgfTag `220 List n=1)'>
          <PgfFont
            <FWeight `Bold'>
          >
        >
      >

      <Para
        <PgfTag `220 List n=1)'>
        <PgfNumString `1)\t'>
        <ParaLine
          <String `The power feed terminal is worn.'>
        >
      >
    MIF

    list = MifParser.parse(mif).elements.first

    assert_instance_of MifParser::List, list
    assert list.format.bold?
    assert_equal "The power feed terminal is worn.", list.raw_text
    assert_equal "The power feed terminal is worn.", list.text
    assert_equal "<b>The power feed terminal is worn.</b>", list.html_text
  end

  private

  def cell_texts(table)
    table.rows.map do |row|
      row.map(&:text)
    end
  end
end
