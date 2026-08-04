
require_relative "mif_converter/generic/attribute_type"
require_relative "mif_converter/generic/attribute_value"
require_relative "mif_converter/generic/node_type"
require_relative "mif_converter/generic/node"
require_relative "mif_converter/generic/document"
require_relative "mif_converter/parser"
require_relative "mif_converter/exporter"
#####
require_relative "mif_converter/mif/mapping"
require_relative "mif_converter/mif/value_mapping"
require_relative "mif_converter/fE/attribute_value_mapping"
require_relative "mif_converter/fE/mapping"


module MifConverter
  def self.convert(input_path)
    document = Parser.parse(input_path)
    Exporter.generate(document)
  end
end