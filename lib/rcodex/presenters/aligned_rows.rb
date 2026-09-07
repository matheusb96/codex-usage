# frozen_string_literal: true

module RCodex
  module Presenters
    # Renders "label: value" rows so every value starts in the same
    # column, however long any individual label turns out to be — instead
    # of a hardcoded padding width, which silently misaligns (or clips)
    # the moment a label exceeds it. Shared by every presenter that prints
    # label/value pairs, so this arithmetic exists in exactly one place.
    class AlignedRows
      def initialize
        @rows = []
      end

      def add(label, value)
        @rows << [label.to_s, value.to_s]
        self
      end

      def each_line(gap: 1)
        width = @rows.map { |label, _| label.length }.max || 0
        @rows.each do |label, value|
          yield "#{"#{label}:".ljust(width + 1)}#{' ' * gap}#{value}"
        end
      end
    end
  end
end
