# frozen_string_literal: true

require_relative "lib/rcodex/version"

Gem::Specification.new do |spec|
  spec.name = "rcodex"
  spec.version = RCodex::VERSION
  spec.authors = ["Matheus Barbosa"]
  spec.email = ["matheusb096@gmail.com"]

  spec.summary = "CLI for ChatGPT Codex, starting with a sensors-style rate-limit usage report"
  spec.description = "rcodex talks to the locally installed Codex CLI's app-server over JSON-RPC to show " \
                      "ChatGPT Plus / Codex rate-limit usage, without reading ~/.codex/auth.json or calling " \
                      "any undocumented ChatGPT endpoint."
  spec.homepage = "https://github.com/matheusb96/codex-usage"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject { |f| f.match?(%r{\A(?:test|spec|\.git|\.github)/}) }
  end
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
