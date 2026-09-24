# frozen_string_literal: true

require_relative "../syntax/string_decoder"

module MifParser
  class Parser
    # Reads ImportObject / Frame measurement and path statements.
    module GraphicValue
      extend self

      DIMENSION_RE =
        /-?\d+(?:\.\d+)?(?:\s*(?:"|pt|cm|mm))?/

      def string(line, tag)
        match = line.match(
          /<#{tag}\s+`((?:\\.|[^'])*)'>/
        )
        return nil unless match

        clean_path(
          Syntax::StringDecoder.decode(match[1])
        )
      end

      def number(line, tag)
        match = line.match(
          /<#{tag}\s+(-?\d+(?:\.\d+)?)>/
        )
        return nil unless match

        match[1].to_f
      end

      def yes?(line, tag)
        match = line.match(/<#{tag}\s+(Yes|No)>/i)
        return nil unless match

        match[1].casecmp?("Yes")
      end

      def rect(line, tag)
        match = line.match(/<#{tag}\s+(.+?)>/)
        return nil unless match

        parts = match[1].scan(DIMENSION_RE)
        return nil unless parts.length >= 4

        parts.first(4).map do |part|
          dimension(part)
        end
      end

      def scale(line)
        match = line.match(
          /<(?:ImportObScale|Scale)\s+(.+?)>/
        )
        return nil unless match

        parts = match[1].scan(/-?\d+(?:\.\d+)?\s*%?/)
        return nil unless parts.length >= 2

        [
          scale_factor(parts[0]),
          scale_factor(parts[1])
        ]
      end

      def clean_path(value)
        decoded = value.to_s.strip
        return decoded[1..-2] if wrapped_path?(decoded)

        decoded
      end

      def file_name_from(*paths)
        paths.each do |path|
          name = path.to_s.tr("\\", "/").split("/").last
          return name unless name.nil? || name.empty?
        end

        nil
      end

      private

      def wrapped_path?(value)
        value.start_with?("<") && value.end_with?(">")
      end

      def dimension(token)
        number = token.to_f
        stripped = token.strip

        return number / 72.0 if stripped.match?(/pt\z/i)
        return number / 2.54 if stripped.match?(/cm\z/i)
        return number / 25.4 if stripped.match?(/mm\z/i)

        number
      end

      def scale_factor(token)
        value = token.to_f
        return value / 100.0 if token.include?("%")

        value
      end
    end
  end
end
