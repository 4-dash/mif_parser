module MifConverter
  module Generic
    module NodeType
      DOCUMENT  = :document
      PARAGRAPH = :paragraph
      LINE      = :line
      TEXT      = :text
      TABLE     = :table
      ROW       = :row
      CELL      = :cell
      MARKER    = :marker

      ALL = [
        DOCUMENT,
        PARAGRAPH,
        LINE,
        TEXT,
        TABLE,
        ROW,
        CELL,
        MARKER
      ].freeze
    end
  end
end