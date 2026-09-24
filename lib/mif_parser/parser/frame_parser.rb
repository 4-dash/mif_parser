# frozen_string_literal: true

require_relative "../elements/table"
require_relative "../elements/cell"
require_relative "parsed_frame"
require_relative "frame_anchor"
require_relative "graphic_value"

module MifParser
  class Parser
    # Reads <Frame> / <ImportObject> / <Inset> and resolves <AFrame> anchors.
    class FrameParser
      def initialize(context)
        @context = context
      end

      def start?(line)
        line.match?(/\A<Frame(?:\s|>|$)/)
      end

      def start
        @context.current_frame = ParsedFrame.new
        @context.current_import = nil
      end

      def finish
        finish_frame
      end

      def parse_statement(statement, closed_block)
        line = statement.text

        start_import(line)
        collect_frame_id(line)
        collect_import_properties(line)
        finish_open_blocks(closed_block)
      end

      def self.resolve_anchors(elements, frames)
        elements.flat_map do |element|
          resolve_element(element, frames)
        end
      end

      def self.resolve_element(element, frames)
        if element.is_a?(FrameAnchor)
          Array(frames[element.id])
        else
          resolve_nested(element, frames)
          [element]
        end
      end

      def self.resolve_nested(element, frames)
        case element
        when Table
          resolve_table(element, frames)
        when Cell
          element.elements.replace(
            resolve_anchors(element.elements, frames)
          )
        end
      end

      def self.resolve_table(table, frames)
        table.title.replace(
          resolve_anchors(table.title, frames)
        )

        resolve_rows(table.header_rows, frames)
        resolve_rows(table.body_rows, frames)
        resolve_rows(table.footer_rows, frames)
      end

      def self.resolve_rows(rows, frames)
        rows.each do |row|
          row.each do |cell|
            cell.elements.replace(
              resolve_anchors(cell.elements, frames)
            )
          end
        end
      end

      private

      def start_import(line)
        return if @context.current_import
        return unless import_start?(line)

        @context.current_import = ParsedImport.new
      end

      def import_start?(line)
        line.match?(/\A<(?:ImportObject|Inset)(?:\s|>|$)/)
      end

      def finish_open_blocks(closed_block)
        tracker = @context.block_tracker

        if tracker.closed?(closed_block, "ImportObject") ||
           tracker.closed?(closed_block, "Inset")
          finish_import
        elsif tracker.closed?(closed_block, "Frame")
          finish_frame
        end
      end

      def collect_frame_id(line)
        return if @context.current_import

        frame_id = GraphicValue.number(line, "ID")
        return if frame_id.nil?

        @context.current_frame.id = frame_id.to_i
      end

      def collect_import_properties(line)
        import = @context.current_import
        frame = @context.current_frame

        collect_frame_angle(frame, line) unless import
        return unless import

        collect_import_paths(import, line)
        collect_import_transform(import, line)
        collect_import_metrics(import, line)
      end

      def collect_frame_angle(frame, line)
        angle = GraphicValue.number(line, "Angle")
        frame.angle = angle unless angle.nil?
      end

      def collect_import_paths(import, line)
        assign_string(import, :file, line, "ImportObFile")
        assign_string(import, :file_di, line, "ImportObFileDI")
        assign_string(import, :url, line, "ImportObURL")
        assign_string(import, :inset_file, line, "InsetFile")
        assign_string(import, :native_file, line, "NativeFile")
      end

      def collect_import_transform(import, line)
        angle = GraphicValue.number(line, "Angle")
        import.angle = angle unless angle.nil?

        flip = GraphicValue.yes?(line, "FlipLR")
        import.flip_horizontal = flip unless flip.nil?

        scale = GraphicValue.scale(line)
        return unless scale

        import.scale_x, import.scale_y = scale
      end

      def collect_import_metrics(import, line)
        apply_rect(import, line)
        apply_dpi(import, line)

        fixed = GraphicValue.yes?(line, "ImportObFixedSize")
        import.fixed_size = fixed unless fixed.nil?
      end

      def apply_rect(import, line)
        rect = GraphicValue.rect(line, "ShapeRect")
        rect ||= GraphicValue.rect(line, "BRect") if import.width.nil?
        return unless rect

        import.width = rect[2]
        import.height = rect[3]
      end

      def apply_dpi(import, line)
        orig_dpi = GraphicValue.number(line, "ImportObOrigDPI")
        import.dpi = orig_dpi unless orig_dpi.nil?
        return unless import.dpi.nil?

        native_dpi = GraphicValue.number(line, "ImportObNativeDPI")
        import.dpi = native_dpi unless native_dpi.nil?
      end

      def assign_string(import, field, line, tag)
        value = GraphicValue.string(line, tag)
        return if value.nil?

        import.public_send("#{field}=", value)
      end

      def finish_import
        import = @context.current_import
        @context.current_import = nil
        return unless import

        @context.current_frame.imports << import
      end

      def finish_frame
        return unless @context.current_frame

        finish_import if @context.current_import

        store_frame(@context.current_frame)
        @context.current_frame = nil
        @context.current_import = nil
      end

      def store_frame(frame)
        return if frame.id.nil?

        images = frame.imports.filter_map do |import|
          import.to_image(
            frame_id: frame.id,
            frame_angle: frame.angle
          )
        end

        @context.frames[frame.id] = images
      end
    end
  end
end
