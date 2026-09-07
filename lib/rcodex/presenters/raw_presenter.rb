# frozen_string_literal: true

require "json"

module RCodex
  module Presenters
    # Prints the untouched account/rateLimits/read result, bypassing the
    # domain mapping entirely — useful when the backend adds a field the
    # mapper doesn't know about yet.
    class RawPresenter
      def render(raw_rate_limits, out: $stdout)
        out.puts JSON.pretty_generate(raw_rate_limits)
      end

      def render_error(error, out: $stdout)
        out.puts JSON.generate("ok" => false, "error" => error.message, "exit_code" => error.exit_code)
      end
    end
  end
end
