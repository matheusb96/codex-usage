# frozen_string_literal: true

module RCodex
  module AppServer
    # Codex app-server methods this gem actually uses, named for what they
    # mean rather than their wire method strings. Thin on purpose: it's the
    # boundary between "talking JSON-RPC" (Connection) and "building our
    # domain model" (UsageMapper) — no business logic lives here.
    class Client
      VERSION_FROM_USER_AGENT = %r{rcodex/([\w.\-]+)}.freeze

      def self.start(codex_bin:, timeout:, debug: false)
        connection = Connection.new(codex_bin: codex_bin, timeout: timeout, debug: debug)
        connection.start
        new(connection)
      end

      def initialize(connection)
        @connection = connection
      end

      # Performs the required initialize/initialized handshake.
      # @return [String, nil] the codex-cli version, parsed from the
      #   server's echoed user-agent, when available.
      def handshake
        result = @connection.request(
          "initialize",
          clientInfo: { name: "rcodex", title: "rcodex", version: RCodex::VERSION }
        )
        @connection.notify("initialized")
        result.is_a?(Hash) ? result["userAgent"].to_s[VERSION_FROM_USER_AGENT, 1] : nil
      end

      # @return [Hash, nil] raw account/read result, or nil if it fails
      #   (non-fatal: plan type still comes from rateLimits/read)
      def account
        @connection.request("account/read", refreshToken: false)
      rescue AppServerError
        nil
      end

      # @return [Hash] raw account/rateLimits/read result
      def rate_limits
        @connection.request("account/rateLimits/read")
      end

      def close
        @connection.stop
      end
    end
  end
end
