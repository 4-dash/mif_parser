module MifConverter
  module Mif
    module MifMapping
      TAGS = {
        "MIFFile" => {
          kind: :node,
          type: Generic::NodeType::DOCUMENT
        },

        "Para" => {
          kind: :node,
          type: Generic::NodeType::PARAGRAPH
        },

        "PgfTag" => {
          kind: :attribute,
          type: Generic::AttributeType::STYLE
        },

        "ParaLine" => {
          kind: :node,
          type: Generic::NodeType::LINE
        },

        "String" => {
          kind: :node,
          type: Generic::NodeType::TEXT
        }
      }.freeze
    end
  end
end