# frozen_string_literal: true

module MifParser
  # Resolved paragraph or character format.
  #
  # Keys are MIF tag names from PROPERTY_TAGS, the same shape as a
  # PgfCatalog entry after whitelist filtering. Add a tag name to
  # PROPERTY_TAGS to collect it from catalog, local <Pgf>, and <Font>.
  class Format
    PROPERTY_TAGS = %w[
      FWeight
      FAngle
      FUnderlining
    ].freeze

    attr_reader :properties

    def self.known?(tag)
      PROPERTY_TAGS.include?(tag.to_s)
    end

    def initialize(properties = {})
      @properties =
        properties.each_with_object({}) do |(key, value), result|
          result[key.to_s] = value.to_s
        end.freeze
    end

    def [](key)
      properties[key.to_s]
    end

    def merge(other)
      return self if other.nil? || other.empty?

      self.class.new(properties.merge(other.properties))
    end

    def empty?
      properties.empty?
    end

    def bold?
      self["FWeight"].to_s.match?(/bold/i)
    end

    def italic?
      self["FAngle"].to_s.match?(/italic|oblique/i)
    end

    def underline?
      value = self["FUnderlining"].to_s
      return false if value.empty?

      !value.match?(/\A(?:FNoUnderlining|No|None)\z/i)
    end

    def ==(other)
      other.is_a?(self.class) && properties == other.properties
    end

    alias eql? ==

    def hash
      [self.class, properties].hash
    end

    def to_h
      properties.dup
    end
  end
end
