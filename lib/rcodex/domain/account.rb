# frozen_string_literal: true

module RCodex
  module Domain
    # A Codex account as reported by `account/read`. Knows nothing about
    # JSON-RPC — the app-server layer maps raw fields into this.
    Account = Struct.new(:type, :email, :plan_type, keyword_init: true) do
      def chatgpt?
        type == "chatgpt"
      end
    end
  end
end
