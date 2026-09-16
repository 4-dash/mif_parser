# frozen_string_literal: true

require_relative "../elements/paragraph"
require_relative "../elements/list"
require_relative "../text_run"

module MifParser
  module Classification
    # Document pass: consecutive "1." / "2)" paragraphs become one ordered list.
    module AmbiguousSequence
      extend self

      #
      # "1." by itself is ambiguous:
      #
      #   1. Introduction
      #
      # could be a heading, while:
      #
      #   1. Remove the cover.
      #   2. Clean the filter.
      #
      # is a list.
      #
      # Therefore a neutral single "1."
      # is not classified as a list from
      # its marker alone.
      #
      # Consecutive 1., 2., 3. paragraphs
      # with the same style are classified
      # as one ordered-list sequence.
      #
      # This also handles manually typed:
      #
      #   1) First
      #   2) Second
      #
      # when PgfNumString is absent.
      #
      def classify(elements)
        classified = []
        index = 0

        while index < elements.length
          candidate = ambiguous_list_candidate(elements[index])

          unless candidate
            classified << elements[index]
            index += 1
            next
          end

          run = [candidate]
          cursor = index + 1

          while cursor < elements.length
            next_candidate = ambiguous_list_candidate(elements[cursor])
            break unless next_candidate
            break unless same_ambiguous_sequence?(run.last, next_candidate)

            run << next_candidate
            cursor += 1
          end

          if run.length >= 2
            run.each do |item|
              previous_element = classified.last

              classified << List.new(
                tag: item[:source].tag,
                number_string: item[:source].number_string,
                text: item[:text],
                format: item[:source].format,
                runs: TextRun.drop_prefix(
                  item[:source].runs,
                  item[:source].raw_text.to_s,
                  item[:text]
                ),
                list_type: :ol,
                list_level: ListItem.list_level_for(
                  item[:source].tag,
                  item[:marker],
                  previous_element: previous_element
                ),
                list_marker: item[:marker]
              )
            end
          else
            classified << elements[index]
          end

          index =
            if run.length >= 2
              cursor
            else
              index + 1
            end
        end

        classified
      end

      private

      def ambiguous_list_candidate(element)
        return nil unless element.is_a?(Paragraph)
        return nil if Classification.heading_tag?(element.tag)

        marker = Classification.clean_marker(element.number_string)

        if Classification.ambiguous_period_numeric_marker?(marker)
          return {
            source: element,
            marker: marker,
            number: marker.delete_suffix(".").to_i,
            punctuation: ".",
            text: element.raw_text.to_s,
            style: normalized_style(element.tag)
          }
        end

        return nil unless marker.empty?

        match = element.raw_text.to_s.lstrip.match(
          /\A(\d+)([.)])\s+(.+)\z/m
        )

        return nil unless match

        {
          source: element,
          marker: "#{match[1]}#{match[2]}",
          number: match[1].to_i,
          punctuation: match[2],
          text: match[3],
          style: normalized_style(element.tag)
        }
      end

      def same_ambiguous_sequence?(previous, current)
        previous[:punctuation] == current[:punctuation] &&
          previous[:style] == current[:style] &&
          current[:number] == previous[:number] + 1
      end

      def normalized_style(tag)
        tag.to_s.strip.downcase
      end
    end
  end
end
