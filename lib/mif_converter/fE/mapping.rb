# lib/mif_converter/fe/mapping.rb
module MifConverter
  module FE
    module Mapping
      NODES = {
        Generic::NodeType::PARAGRAPH => "paragraph",
        Generic::NodeType::LINE      => "line",
        Generic::NodeType::TEXT      => "text",
        Generic::NodeType::TABLE     => "table",
        Generic::NodeType::ROW       => "row",
        Generic::NodeType::CELL      => "cell"
      }.freeze

      ATTRIBUTES = {
        Generic::AttributeType::STYLE => "style",
        Generic::AttributeType::VALUE => "value"
      }.freeze
    end
  end
end