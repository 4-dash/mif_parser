# lib/mif_converter/fe/attribute_value_mapping.rb
module MifConverter
  module FE
    module AttributeValueMapping
      STYLE = {
        Generic::AttributeValue::StyleType::H1   => "heading-1",
        Generic::AttributeValue::StyleType::H2   => "heading-2",
        Generic::AttributeValue::StyleType::BODY => "body"
      }.freeze
    end
  end
end
##### TODO Attribue or just valuemapping, make 2 way for mif and fE
########## basically 1 from mapping 1 to mapping