# frozen_string_literal: true

require_relative "test_helper"

class FixtureExpectationTest < Minitest::Test
  expectation_files =
    Dir[
      File.join(
        MifTestSupport::FIXTURE_ROOT,
        "**",
        "*.expected.yml"
      )
    ].sort

  expectation_files.each do |expected_path|
    relative_name =
      expected_path
      .delete_prefix(
        "#{MifTestSupport::FIXTURE_ROOT}/"
      )
      .sub(/\.expected\.yml\z/, "")

    test_name =
      relative_name.gsub(/[^A-Za-z0-9]+/, "_")

    define_method(
      "test_fixture_#{test_name}"
    ) do
      mif_path =
        expected_path.sub(
          /\.expected\.yml\z/,
          ".mif"
        )

      assert(
        File.exist?(mif_path),
        "Missing fixture: #{mif_path}"
      )

      expected =
        YAML.safe_load(
          File.read(
            expected_path,
            encoding: "UTF-8"
          ),
          aliases: false
        )

      document =
        File.open(
          mif_path,
          "r:UTF-8"
        ) do |file|
          MifParser.parse(file)
        end

      expected_elements =
        expected.fetch("elements")

      assert_equal(
        expected_elements.length,
        document.size,
        "#{relative_name}: element count"
      )

      expected_elements.each_with_index do |expectations, index|
        element = document.elements[index]

        expectations.each do |property, expected_value|
          actual_value =
            fixture_property(
              element,
              property
            )

          assert_equal(
            normalize_test_value(expected_value),
            normalize_test_value(actual_value),
            "#{relative_name}, element #{index + 1}, #{property}"
          )
        end
      end
    end
  end

  private

  def fixture_property(element, property)
    return element.class.name if property == "class"

    return element.public_send(property) if element.respond_to?(property)

    result = element.interpret

    return result.public_send(property) if result.respond_to?(property)

    flunk(
      "Neither #{element.class} nor " \
      "#{result.class} has property #{property.inspect}"
    )
  end
end
