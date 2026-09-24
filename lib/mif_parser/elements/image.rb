# frozen_string_literal: true

module MifParser
  class Image < Element
    attr_reader :id,
                :file_name,
                :file_path,
                :angle,
                :scale_x,
                :scale_y,
                :width,
                :height,
                :dpi,
                :flip_horizontal,
                :fixed_size

    def initialize(tag: nil, **attributes)
      super(tag: tag)

      assign_attributes(attributes)
    end

    def type
      :image
    end

    def text
      file_name
    end

    def flip_horizontal?
      flip_horizontal
    end

    def fixed_size?
      fixed_size
    end

    private

    ASSIGNED_ATTRIBUTES = %i[
      id
      file_name
      file_path
      angle
      scale_x
      scale_y
      width
      height
      dpi
      flip_horizontal
      fixed_size
    ].freeze

    def assign_attributes(attributes)
      ASSIGNED_ATTRIBUTES.each do |name|
        instance_variable_set(:"@#{name}", attributes[name])
      end

      @angle ||= 0.0
      @flip_horizontal = attributes.fetch(:flip_horizontal, false)
      @fixed_size = attributes.fetch(:fixed_size, false)
    end
  end
end
