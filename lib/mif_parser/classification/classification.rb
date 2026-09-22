# frozen_string_literal: true

require_relative "tags"
require_relative "markers"
require_relative "heading"

module MifParser
  # Heuristics for tags, markers, lists, and heading vs body.
  #
  # tags.rb               paragraph-style names (heading, list, ul/ol)
  # markers.rb            PgfNumString / bullet syntax
  # heading.rb            heading vs body, including numbered headings
  # list_item.rb          Paragraph vs List, including ul/ol and level
  # ambiguous_sequence.rb document pass for consecutive "1." / "2)" runs
  module Classification
    COMMON_BULLET_MARKERS = Markers::COMMON_BULLET_MARKERS

    extend Tags
    extend Markers
    extend Heading
  end
end

require_relative "list_item"
require_relative "ambiguous_sequence"
