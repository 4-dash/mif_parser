# frozen_string_literal: true

require_relative "../elements/image"
require_relative "graphic_value"

module MifParser
  class Parser
    class ParsedFrame
      attr_accessor :id, :angle, :imports

      def initialize
        @id = nil
        @angle = nil
        @imports = []
      end
    end

    class ParsedImport
      attr_accessor :file,
                    :file_di,
                    :url,
                    :inset_file,
                    :native_file,
                    :angle,
                    :scale_x,
                    :scale_y,
                    :width,
                    :height,
                    :dpi,
                    :flip_horizontal,
                    :fixed_size

      def initialize
        @flip_horizontal = false
        @fixed_size = false
        @angle = nil
      end

      def to_image(frame_id:, frame_angle: nil)
        path = present_path
        name = GraphicValue.file_name_from(file, path)
        return nil if name.nil? && path.nil?

        Image.new(
          **image_attributes(frame_id, path, name, frame_angle)
        )
      end

      private

      def image_attributes(frame_id, path, name, frame_angle)
        {
          id: frame_id, file_name: name, file_path: path,
          angle: angle || frame_angle || 0.0,
          scale_x: scale_x, scale_y: scale_y,
          width: width, height: height, dpi: dpi,
          flip_horizontal: flip_horizontal, fixed_size: fixed_size
        }
      end

      def present_path
        [file_di, file, inset_file, native_file, url].find do |value|
          !value.to_s.empty?
        end
      end
    end
  end
end
