# frozen_string_literal: true

require_relative "tags"
require_relative "markers"

module MifParser
  # Heuristics shared by parser and interpreter.
  #
  # tags.rb               paragraph-style names (heading, list, ul/ol)
  # markers.rb            PgfNumString / bullet syntax
  # list_item.rb          Paragraph vs List, including ul/ol and level
  # ambiguous_sequence.rb document pass for consecutive "1." / "2)" runs
  module Classification
    COMMON_BULLET_MARKERS = Markers::COMMON_BULLET_MARKERS

    extend Tags
    extend Markers
  end
end

require_relative "list_item"
require_relative "ambiguous_sequence"
