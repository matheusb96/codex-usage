# frozen_string_literal: true

module RCodex
  module Commands
    # Orchestrates one usage report: spawn the app-server, run the
    # handshake, fetch account + rate limits, hand the result to whichever
    # presenter the caller picked, and make sure the app-server process is
    # always terminated, on success or failure.
    class UsageCommand
      PRESENTERS = {
        human: Presenters::HumanPresenter,
        simple: Presenters::SimplePresenter,
        json: Presenters::JsonPresenter,
        raw: Presenters::RawPresenter
      }.freeze

      def initialize(options)
        @options = options
        @presenter = PRESENTERS.fetch(options.format).new
      end

      # @return [Integer] process exit code
      def run(out: $stdout, err: $stderr)
        connection = AppServer::Connection.new(codex_bin: @options.codex_bin, timeout: @options.timeout, debug: @options.debug)
        install_signal_traps(connection)

        connection.start
        client = AppServer::Client.new(connection)
        codex_version = client.handshake
        account_result = client.account
        raw_rate_limits = client.rate_limits

        render_success(raw_rate_limits, account_result, codex_version, out)
        0
      rescue AppServerError => e
        render_error(e, out, err)
        e.exit_code
      ensure
        connection&.stop
      end

      private

      def render_success(raw_rate_limits, account_result, codex_version, out)
        if @options.format == :raw
          @presenter.render(raw_rate_limits, out: out)
        else
          snapshot = AppServer::UsageMapper.build(
            rate_limits_result: raw_rate_limits,
            account_result: account_result,
            codex_version: codex_version
          )
          @presenter.render(snapshot, out: out)
        end
      end

      def render_error(error, out, err)
        # json/raw error output must stay valid JSON on stdout, for scripts;
        # human/simple errors go to stderr as plain text.
        destination = %i[json raw].include?(@options.format) ? out : err
        @presenter.render_error(error, out: destination)
      end

      def install_signal_traps(connection)
        %w[INT TERM].each do |sig|
          Signal.trap(sig) do
            connection.stop
            exit(130)
          end
        end
      end
    end
  end
end
