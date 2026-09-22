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

    unless element.respond_to?(property)
      flunk(
        "#{element.class} has no property #{property.inspect}"
      )
    end

    dump_fixture_value(element.public_send(property))
  end

  def dump_fixture_value(value)
    return dump_array(value) if value.is_a?(Array)

    send(dumper_for(value), value)
  end

  def dumper_for(value)
    {
      MifParser::Cell => :dump_cell,
      MifParser::Paragraph => :dump_paragraph,
      MifParser::List => :dump_list,
      MifParser::Format => :dump_format,
      MifParser::TextRun => :dump_text_run
    }.fetch(value.class, :identity_dump)
  end

  def dump_array(values)
    values.map { |item| dump_fixture_value(item) }
  end

  def dump_format(format)
    format.to_h
  end

  def identity_dump(value)
    value
  end

  def dump_cell(cell)
    {
      "class" => cell.class.name,
      "text" => cell.text,
      "elements" => dump_fixture_value(cell.elements)
    }
  end

  def dump_paragraph(paragraph)
    dump_tagged_text(paragraph)
  end

  def dump_list(list)
    dump_tagged_text(list).merge(
      "list_type" => list.list_type,
      "list_marker" => list.list_marker
    )
  end

  def dump_tagged_text(element)
    dumped = {
      "class" => element.class.name,
      "raw_text" => element.raw_text
    }
    dumped["tag"] = element.tag unless element.tag.nil?
    dumped
  end

  def dump_text_run(run)
    {
      "text" => run.text,
      "format" => dump_fixture_value(run.format)
    }
  end
end
