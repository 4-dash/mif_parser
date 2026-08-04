module MifConverter
	module Generic
		class Node
			attr_reader :type, :attributes, :children

			def initialize(type:, attributes: {}, children: [])
				validate_type!(type)
				validate_attributes!(attributes)
				validate_children!(children)

				@type = type
				@attributes = attributes
				@children = children
			end

			private

			def validate_type!(type)
				return if NodeType::ALL.include?(type)

				raise ArgumentError, "Invalid node type: #{type.inspect}"
			end

			def validate_attributes!(attributes)
				attributes.each do |type, value|
					unless AttributeType::ALL.include?(type)
						raise ArgumentError, "Invalid attribute type: #{type.inspect}"
					end

					case type
					when AttributeType::STYLE
						unless AttributeValue::StyleType::ALL.include?(value)
							raise ArgumentError, "Invalid style value: #{value.inspect}"
						end
					end
				end
			end

			def validate_children!(children)
				return if children.all? { |child| child.is_a?(Node) }

				raise ArgumentError, "Children must be Generic::Node objects"
			end
		end
	end
end