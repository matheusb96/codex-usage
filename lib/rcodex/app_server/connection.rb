# frozen_string_literal: true

require "json"
require "open3"

module RCodex
  module AppServer
    # Low-level JSON-RPC transport to a spawned `codex app-server` process:
    # newline-delimited JSON over stdio, with the "jsonrpc" header omitted
    # (that's how the app-server protocol works, not a shortcut we're taking).
    #
    # Knows nothing about account/rateLimits/read or any other method — it
    # just sends requests/notifications and waits for matching responses.
    class Connection
      def initialize(codex_bin:, timeout:, debug: false)
        @codex_bin = codex_bin
        @timeout = timeout
        @debug = debug
        @next_id = 0
        @stderr_buf = +""
      end

      def start
        @stdin, @stdout, @stderr, @wait_thread = Open3.popen3(@codex_bin, "app-server")
        @stdin.sync = true
        @stderr_thread = Thread.new { drain_stderr }
        self
      rescue Errno::ENOENT
        raise AppServerError.binary_not_found(
          "codex binary not found (#{@codex_bin}); install Codex CLI or pass --codex PATH"
        )
      end

      def request(method, params = nil)
        id = (@next_id += 1)
        message = { id: id, method: method }
        message[:params] = params unless params.nil?
        send_line(message)
        wait_for_response(id, method)
      end

      def notify(method, params = nil)
        message = { method: method }
        message[:params] = params unless params.nil?
        send_line(message)
      end

      # Close stdin (EOF) so the server exits on its own; escalate to
      # TERM then KILL if it lingers. Always safe to call, even after
      # a failed start.
      def stop
        return unless @wait_thread

        @stdin.close unless @stdin.closed?
        return if reaped?(2)

        signal("TERM")
        return if reaped?(2)

        signal("KILL")
        reaped?(2)
      ensure
        [@stdout, @stderr].each { |io| io&.close unless io.nil? || io.closed? }
        @stderr_thread&.join(0.2)
      end

      private

      def send_line(message)
        line = JSON.generate(message)
        warn "-> #{line}" if @debug
        @stdin.puts(line)
      rescue Errno::EPIPE, IOError
        raise AppServerError.new("app-server closed its stdin unexpectedly#{stderr_hint}")
      end

      def wait_for_response(id, method)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + @timeout
        loop do
          remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
          raise AppServerError.timeout("timed out after #{@timeout}s waiting for #{method}#{stderr_hint}") if remaining <= 0

          next unless IO.select([@stdout], nil, nil, remaining)

          line = @stdout.gets
          raise AppServerError.new("app-server exited before answering #{method}#{stderr_hint}") if line.nil?

          warn "<- #{line.chomp}" if @debug
          message = parse_frame(line)
          next unless message

          # Notifications (no id) and server-initiated requests (id + method) aren't responses.
          next unless message.is_a?(Hash) && message["id"] == id && !message.key?("method")

          raise rpc_error(method, message["error"]) if message["error"]

          return message["result"]
        end
      end

      def parse_frame(line)
        JSON.parse(line)
      rescue JSON::ParserError
        nil
      end

      def rpc_error(method, err)
        text = err.is_a?(Hash) ? err["message"].to_s : err.to_s
        if text =~ /authentication required/i
          AppServerError.not_logged_in("#{method} failed: #{text}")
        else
          AppServerError.new("#{method} failed: #{text}")
        end
      end

      def drain_stderr
        while (chunk = @stderr.read(4096))
          @stderr_buf << chunk
          $stderr.write(chunk) if @debug
        end
      rescue IOError
        nil
      end

      def stderr_hint
        tail = @stderr_buf.strip.lines.last(3).join.strip
        tail.empty? ? "" : "\n  app-server stderr: #{tail}"
      end

      def signal(sig)
        Process.kill(sig, @wait_thread.pid)
      rescue Errno::ESRCH
        nil
      end

      def reaped?(seconds)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + seconds
        until @wait_thread.join(0.05)
          return false if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        end
        true
      end
    end
  end
end
