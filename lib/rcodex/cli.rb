# frozen_string_literal: true

require "optparse"

module RCodex
  # Top-level command-line parser. Today the only command is `--usage`;
  # options are declared as one flat parser rather than a subcommand
  # framework, which would be premature for a single-command gem.
  class CLI
    Options = Struct.new(:command, :format, :timeout, :codex_bin, :debug, :color, keyword_init: true)

    def self.start(argv)
      new.run(argv)
    end

    def run(argv)
      options = default_options
      parser = build_parser(options)

      begin
        parser.parse!(argv)
      rescue OptionParser::ParseError => e
        warn "rcodex: #{e.message}"
        warn parser
        return 1
      end

      Color.enabled = options.color unless options.color.nil?

      case options.command
      when :usage
        Commands::UsageCommand.new(options).run
      else
        puts parser
        0
      end
    end

    private

    def default_options
      Options.new(
        command: nil,
        format: :human,
        timeout: 20.0,
        codex_bin: ENV.fetch("CODEX_BIN", "codex"),
        debug: false,
        color: nil
      )
    end

    def build_parser(options)
      OptionParser.new do |o|
        o.banner = "Usage: rcodex --usage [options]"

        o.separator ""
        o.separator "Commands:"
        o.on("--usage", "Show ChatGPT / Codex rate-limit usage") { options.command = :usage }

        o.separator ""
        o.separator "Usage options:"
        o.on("--simple", "Minimal sensors-style plain output") { options.format = :simple }
        o.on("--json", "Print a normalized JSON report") { options.format = :json }
        o.on("--raw", "Print the untouched account/rateLimits/read result as JSON") { options.format = :raw }
        o.on("--color", "Force ANSI colors on") { options.color = true }
        o.on("--no-color", "Disable ANSI colors") { options.color = false }
        o.on("--timeout SECS", Float, "Per-request timeout (default 20)") { |v| options.timeout = v }
        o.on("--codex PATH", "Path to the codex binary (default: $CODEX_BIN or `codex` on PATH)") { |v| options.codex_bin = v }
        o.on("--debug", "Echo JSON-RPC traffic and app-server stderr") { options.debug = true }

        o.separator ""
        o.on("-v", "--version", "Print the rcodex version") do
          puts "rcodex #{RCodex::VERSION}"
          exit 0
        end
        o.on("-h", "--help", "Show this help") do
          puts o
          exit 0
        end
      end
    end
  end
end
