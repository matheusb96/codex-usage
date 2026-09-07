# frozen_string_literal: true

module RCodex
  # Tiny ANSI colorizer. No dependency on a color gem: rcodex stays
  # stdlib-only. Respects NO_COLOR (https://no-color.org) and falls back
  # to plain text when stdout isn't a TTY, unless the caller forces it
  # via `RCodex::Color.enabled = true/false` (wired to --color/--no-color).
  module Color
    CODES = {
      reset: 0, bold: 1, dim: 2,
      red: 31, green: 32, yellow: 33, blue: 34, magenta: 35, cyan: 36, white: 37
    }.freeze

    @enabled = nil

    class << self
      # @return [Boolean, nil] explicit override, or nil to auto-detect
      attr_writer :enabled

      def enabled?
        return @enabled unless @enabled.nil?

        !ENV["NO_COLOR"] && $stdout.respond_to?(:tty?) && $stdout.tty?
      end

      def paint(text, *styles)
        return text.to_s unless enabled?

        codes = styles.map { |style| CODES.fetch(style) }.join(";")
        "\e[#{codes}m#{text}\e[0m"
      end
    end
  end
end
