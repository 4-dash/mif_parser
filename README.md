# MifParser

Parses Adobe FrameMaker MIF files.


### Parsing and Interpretation

`MifParser` separates **parsing** from **interpretation**.

MIF source -> Parser -> Paragraph / List / Table -> Interpreter -> heading / body / list / table


`MifParser.parse` still returns a `Document` of `Paragraph`, `List`, and `Table` elements.

Internally the parser runs in phases:

* **Syntax** (`syntax/`) reads MIF blocks, `<String>` / `<Char>` tokens, and escapes.
* **Structure** (`parser/`) builds `Para` and `Tbl` records, including table anchors (`<ATbl>`). Table cells are `Cell` nodes whose children are `Paragraph` / `List`, same as the document flow.
* **List classification** (`classification/`) decides whether a paragraph is a `List` (ul/ol, level, marker). MIF has no list construct; this is inferred from tags and markers.
* **Interpretation** (`interpreter/`) decides what those elements mean: heading vs body for paragraphs, and a typed result for lists and tables.

The **Interpreter** determines what parsed elements mean:

* Paragraph → heading or body
* List → list type, level, marker
* Table → table data (`rows` is a grid of `Cell` elements)
* Cell → joined cell text; interpret each `cell.elements` entry for heading / body / list


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
