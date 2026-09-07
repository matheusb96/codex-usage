# frozen_string_literal: true

module RCodex
  # Small text-formatting helpers shared by presenters. Not domain logic —
  # just how a duration or an error becomes readable text.
  module Format
    module_function

    def duration(seconds)
      return "now" if seconds.nil? || seconds <= 0

      days, rem = seconds.divmod(86_400)
      hours, rem = rem.divmod(3600)
      minutes = rem / 60

      parts = []
      parts << "#{days}d" if days.positive?
      parts << "#{hours}h" if hours.positive?
      parts << "#{minutes}m" if minutes.positive? && days.zero?
      parts.empty? ? "<1m" : parts.join(" ")
    end

    def clock(time)
      time.strftime("%a %Y-%m-%d %H:%M %Z")
    end
  end
end
