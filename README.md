# MifParser

Parses Adobe FrameMaker MIF files.


### Parsing and Interpretation

`MifParser` separates **parsing** from **interpretation**.

MIF source -> Parser -> Paragraph / List / Table -> Interpreter -> heading / body / list / table


`MifParser.parse` still returns a `Document` of `Paragraph`, `List`, and `Table` elements.

Internally the parser runs in phases:

* **Syntax** (`syntax/`) reads MIF blocks, `<String>` / `<Char>` tokens, and escapes.
* **Structure** (`parser/`) builds `Para` and `Tbl` records, including table anchors (`<ATbl>`).
* **List classification** (`classification/`) decides whether a paragraph is a `List` (ul/ol, level, marker). MIF has no list construct; this is inferred from tags and markers.
* **Interpretation** (`interpreter/`) decides what those elements mean: heading vs body for paragraphs, and a typed result for lists and tables.

The **Interpreter** determines what parsed elements mean:

* Paragraph → heading or body
* List → list type, level, marker
* Table → table data


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
