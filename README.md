# MifParser

Parses Adobe FrameMaker MIF files.

```ruby
document = MifParser.parse(io_or_string)

document.each do |element|
  result = element.interpret
  # result.type         :heading | :body | :list | :table | :cell
  # result.text         plain text
  # result.html_text    same text with <b> / <i> / <u>
end
```

Pipeline: **syntax** → **structure** (`Para` / `Tbl`) → **list classification** → **interpretation**.

MIF has no list construct; lists are inferred from tags and `PgfNumString` markers.

## Elements

`Document` is enumerable (`#paragraphs`, `#lists`, `#tables`).

| Class | Meaning |
|---|---|
| `Paragraph` | heading or body |
| `List` | `:ol` / `:ul`, marker, level |
| `Table` | `rows` is a grid of `Cell`s |
| `Cell` | nested `Paragraph` / `List` |

Heading and list levels are **0-based** (`Title1` / first list item → `0`). An explicit heading style wins over numbering (`Title4` stays 3 even if numbered `4.3`).

## Format

`document.catalog` is `PgfTag → Format` from `<PgfCatalog>`. Each paragraph/list has:

- `format` — catalog entry plus local `<Pgf>` overlay
- `runs` — character spans from inline `<Font>`
- `html_text` / `interpret.html_text` — HTML view of the runs

An empty `<Font>` resets to the paragraph format.

Collected MIF tags (add names to collect more):

```ruby
MifParser::Format::PROPERTY_TAGS
# => %w[FWeight FAngle FUnderlining]
```

`format.bold?`, `format.italic?`, `format.underline?` and `format.to_h` read those properties. `text` stays plain so you can render HTML, Markdown, or anything else from `format` / `runs`.

## License

MIT
