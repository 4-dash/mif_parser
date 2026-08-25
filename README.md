# MifParser

Parses Adobe FrameMaker MIF files.


### Parsing and Interpretation

`MifParser` separates **parsing** from **interpretation**.


MIF source -> Parser -> Paragraph / List / etc. ->  Interpreter -> heading / body / list / etc.


The **Parser** reads raw MIF and creates Ruby elements.

* `ParagraphParser` parses `<Para>` blocks.
* `TableParser` parses tables, rows, and cells.
* `ListParser` is different: MIF lists are represented as paragraphs, so `ParagraphParser` calls `ListParser` to decide whether a parsed paragraph should become a `Paragraph` or `List`.

The **Interpreter** determines what parsed elements mean:

* `ParagraphInterpreter` → heading or body
* `ListInterpreter` → list type, level, marker
* `TableInterpreter` → table data


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
