# frozen_string_literal: true

module RCodex
  module Presenters
    # Rich, colorized, sensors-style report.
    class HumanPresenter
      BAR_WIDTH = 20
      SEVERITY_COLOR = { ok: :green, warning: :yellow, critical: :red }.freeze

      def render(snapshot, out: $stdout)
        out.puts Color.paint("rcodex-usage", :bold)
        out.puts Color.paint("Adapter: Codex App Server (#{snapshot.codex_version || 'codex'})", :dim)
        out.puts

        rows(snapshot).each_line(gap: 2) { |line| out.puts line }
      end

      def render_error(error, out: $stderr)
        out.puts "rcodex: #{error.message}"
      end

      private

      def rows(snapshot)
        rows = AlignedRows.new
        rows.add("plan", plan_value(snapshot))
        snapshot.ordered_windows.each { |window| rows.add(window.label, window_value(window)) }
        rows.add("credits", snapshot.credits.description) if snapshot.credits?
        rows.add("limit", Color.paint(snapshot.rate_limit_reached_type, :red, :bold)) if snapshot.rate_limit_reached_type
        rows.add("spend cap", Color.paint("reached", :red, :bold)) if snapshot.spend_control_reached?
        if snapshot.reset_credits_available?
          count = snapshot.reset_credits_available
          rows.add("resets", "#{count} earned reset credit#{'s' unless count == 1} available")
        end
        rows.add("buckets", "+#{snapshot.other_buckets.join(', ')}") if snapshot.other_buckets?
        rows
      end

      def plan_value(snapshot)
        value = snapshot.plan_type || "n/a"
        account = snapshot.account
        value += Color.paint("  (#{account.type} auth)", :dim) if account && !account.chatgpt?
        value
      end

      def window_value(window)
        color = SEVERITY_COLOR.fetch(window.severity)
        used = Color.paint(format("%3d%% used", window.used_percent), color)
        left = format("%3d%% left", window.remaining_percent)
        "#{used}  #{left}  #{bar(window, color)}  #{window_extra(window)}"
      end

      def window_extra(window)
        return "reset time n/a" unless window.resets_at

        "resets #{Format.clock(window.resets_at)} (in #{Format.duration(window.resets_in_seconds)})"
      end

      def bar(window, color)
        filled = (window.used_percent * BAR_WIDTH / 100.0).round
        Color.paint("[#{'#' * filled}#{'.' * (BAR_WIDTH - filled)}]", color)
      end
    end
  end
end
