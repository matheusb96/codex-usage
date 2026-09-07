# frozen_string_literal: true

require "json"

module RCodex
  module Presenters
    class JsonPresenter
      def render(snapshot, out: $stdout)
        out.puts JSON.pretty_generate(snapshot.to_h)
      end

      def render_error(error, out: $stdout)
        out.puts JSON.generate("ok" => false, "error" => error.message, "exit_code" => error.exit_code)
      end
    end
  end
end
