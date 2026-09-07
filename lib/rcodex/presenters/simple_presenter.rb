# frozen_string_literal: true

module RCodex
  module Presenters
    # Bare-bones output modeled on `sensors` with no arguments: one line
    # per reading, no bars, no color, nothing but the numbers that matter.
    class SimplePresenter
      def render(snapshot, out: $stdout)
        out.puts "rcodex-usage"

        rows = AlignedRows.new
        snapshot.ordered_windows.each { |window| rows.add(window.label, window_value(window)) }
        rows.add("plan", snapshot.plan_type) if snapshot.plan_type
        rows.each_line { |line| out.puts line }
      end

      def render_error(error, out: $stderr)
        out.puts "rcodex: #{error.message}"
      end

      private

      def window_value(window)
        reset = window.resets_at ? ", resets in #{Format.duration(window.resets_in_seconds)}" : ""
        "#{window.used_percent}% used#{reset}"
      end
    end
  end
end
