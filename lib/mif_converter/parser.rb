module MifConverter
  class Parser
    def self.parse(path)
      new(File.read(path)).parse
    end

    def initialize(content)
      @content = content
    end

    def parse
      document = Generic::Document.new

      stack = []

      @content.each_line do |line|
        line = line.strip

        next if line.empty?

        if line == ">"
          stack.pop
          next
        end

        next unless line.start_with?("<")

        parse_element(line, document, stack)
      end

      document
    end

    private

    def parse_element(line, document, stack)
      tag, value = extract_tag_and_value(line)

      case tag
      when "MIFFile"
        document.attributes[
          Generic::AttributeType::VERSION
        ] = value

      when "Para"
        node = Generic::Node.new(
          type: Generic::NodeType::PARAGRAPH
        )

        add_node(node, document, stack)
        stack << node

      when "PgfTag"
        current = stack.last

        current.attributes[
          Generic::AttributeType::STYLE
        ] = map_style(value)

      when "ParaLine"
        node = Generic::Node.new(
          type: Generic::NodeType::LINE
        )

        add_node(node, document, stack)
        stack << node

      when "String"
        node = Generic::Node.new(
          type: Generic::NodeType::TEXT,
          attributes: {
            Generic::AttributeType::VALUE => value
          }
        )

        add_node(node, document, stack)

      else
        raise ArgumentError, "Unsupported MIF tag: #{tag}"
      end
    end

    def add_node(node, document, stack)
      if stack.empty?
        document.nodes << node
      else
        stack.last.children << node
      end
    end

    def extract_tag_and_value(line)
      content = line.delete_prefix("<").strip

      tag, rest = content.split(/\s+/, 2)

      value =
        if rest
          rest
            .strip
            .delete_prefix("`")
            .delete_suffix("'>")
            .delete_suffix(">")
            .delete_suffix("'")
        end

      [tag, value]
    end

    def map_style(value)
      case value
      when "Heading1"
        Generic::AttributeValue::StyleType::H1
      when "Heading2"
        Generic::AttributeValue::StyleType::H2
      when "Body"
        Generic::AttributeValue::StyleType::BODY
      else
        raise ArgumentError, "Unsupported paragraph style: #{value}"
      end
    end
  end
end