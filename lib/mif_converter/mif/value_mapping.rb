module MifConverter
  module Mif
    module ValueMapping
      STYLE = {
        "Heading1" => Generic::AttributeValue::StyleType::H1,
        "Heading2" => Generic::AttributeValue::StyleType::H2,
        "Body"     => Generic::AttributeValue::StyleType::BODY
      }.freeze
    end
  end
end