# frozen_string_literal: true

module RCodex
  module Domain
    # One usage window (5-hour, weekly, or whatever else the backend adds).
    # `kind` is a stable short identifier ("5h", "weekly", "10d", ...),
    # `label` is the human-facing name ("5-hour", "weekly", ...).
    RateLimitWindow = Struct.new(:slot, :kind, :label, :window_minutes, :used_percent, :resets_at, keyword_init: true) do
      WARN_THRESHOLD = 60
      CRITICAL_THRESHOLD = 85

      def remaining_percent
        100 - used_percent
      end

      def resets_in_seconds(now = Time.now)
        return nil unless resets_at

        [resets_at.to_i - now.to_i, 0].max
      end

      def reached_reset_time?(now = Time.now)
        !resets_at.nil? && resets_in_seconds(now).zero?
      end

      # @return [Symbol] :ok, :warning, or :critical — for presenters to color by
      def severity
        return :critical if used_percent >= CRITICAL_THRESHOLD
        return :warning if used_percent >= WARN_THRESHOLD

        :ok
      end

      def to_h
        {
          "slot" => slot,
          "kind" => kind,
          "label" => label,
          "window_minutes" => window_minutes,
          "used_percent" => used_percent,
          "remaining_percent" => remaining_percent,
          "resets_at_unix" => resets_at&.to_i,
          "resets_at" => resets_at&.iso8601,
          "resets_in_seconds" => resets_at && resets_in_seconds
        }
      end
    end
  end
end
