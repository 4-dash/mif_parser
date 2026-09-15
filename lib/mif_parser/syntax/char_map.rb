# frozen_string_literal: true

module MifParser
  module Syntax
    # Named `<Char Tab>` (etc.) replacements used while reading text.
    CHAR_MAP = {
      "Tab" => "\t",
      "HardReturn" => "\n",
      "HardSpace" => "\u00A0",
      "SoftHyphen" => "\u00AD",
      "DiscHyphen" => "\u00AD",
      "HardHyphen" => "\u2011",
      "EnDash" => "–",
      "EmDash" => "—",
      "Bullet" => "•",
      "Cent" => "¢",
      "Pound" => "£",
      "Yen" => "¥"
    }.freeze
  end
end
