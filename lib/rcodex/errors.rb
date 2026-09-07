# frozen_string_literal: true

module RCodex
  # Base class for errors rcodex raises deliberately (as opposed to bugs).
  class Error < StandardError
    # @return [Integer] process exit code this error should map to
    attr_reader :exit_code

    def initialize(message, exit_code: 1)
      super(message)
      @exit_code = exit_code
    end
  end

  # Raised for anything that goes wrong talking to `codex app-server`:
  # the binary is missing, the handshake fails, a request errors out,
  # or the server doesn't answer in time.
  class AppServerError < Error
    NOT_LOGGED_IN = 2
    BINARY_NOT_FOUND = 3
    TIMEOUT = 4

    def self.not_logged_in(message)
      new(message, exit_code: NOT_LOGGED_IN)
    end

    def self.binary_not_found(message)
      new(message, exit_code: BINARY_NOT_FOUND)
    end

    def self.timeout(message)
      new(message, exit_code: TIMEOUT)
    end
  end
end
