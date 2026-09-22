## [Unreleased]

## [0.3.0] - 22.09.2026

- Removed the interpreter layer. Heading vs body, list type, and table/cell type live on the document elements (`element.type`, `element.heading?`, `element.heading_level`).
- Breaking: `element.interpret` and `MifParser::Interpreter` are gone.

## [0.2.1] - 25.08.2026

- Added list support. Refactored code to be modular.

## [0.2.0] - 20.08.2026

- Text parsing, correct heading and table detection

## [0.1.0] - 28.07.2026

- Initial release
