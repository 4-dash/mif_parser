# frozen_string_literal: true

require "minitest/autorun"
require "yaml"

require_relative "../lib/mif_parser"

module MifTestSupport
  FIXTURE_ROOT =
    File.expand_path("fixtures", __dir__)

  def parse_fixture(name)
    path = File.join(
      FIXTURE_ROOT,
      name
    )

    File.open(path, "r:UTF-8") do |file|
      MifParser.parse(file)
    end
  end

  def normalize_test_value(value)
    case value
    when Symbol
      value.to_s

    when Array
      value.map do |item|
        normalize_test_value(item)
      end

    when Hash
      value.each_with_object({}) do |(key, item), result|
        result[key.to_s] =
          normalize_test_value(item)
      end

    else
      value
    end
  end
end

class Minitest::Test
  include MifTestSupport
end
