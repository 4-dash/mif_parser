module MifConverter
  class Exporter
    def self.generate(document)
      document.nodes.map do |node|
        export_node(node)
      end.join("\n")
    end

    def self.export_node(node)
      tag = FE::Mapping::NODES.fetch(node.type)

      attributes = export_attributes(node.attributes)
      children = node.children.map { |child| export_node(child) }.join

      if node.type == Generic::NodeType::TEXT
        return node.attributes[
          Generic::AttributeType::VALUE
        ].to_s
      end

      opening_tag =
        if attributes.empty?
          "<#{tag}>"
        else
          "<#{tag} #{attributes}>"
        end

      "#{opening_tag}#{children}</#{tag}>"
    end

    def self.export_attributes(attributes)
      attributes.filter_map do |type, value|
        next if type == Generic::AttributeType::VALUE

        name = FE::Mapping::ATTRIBUTES.fetch(type)
        converted_value = export_attribute_value(type, value)

        %(#{name}="#{converted_value}")
      end.join(" ")
    end

    def self.export_attribute_value(type, value)
      case type
      when Generic::AttributeType::STYLE
        FE::AttributeValueMapping::STYLE.fetch(value)
      else
        value.to_s
      end
    end

    private_class_method :export_node,
                         :export_attributes,
                         :export_attribute_value
  end
end