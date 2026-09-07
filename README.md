# rcodex

A CLI for ChatGPT Codex. Today it has one command: `rcodex --usage`, which prints your
ChatGPT Plus / Codex rate-limit usage, `sensors`-style.

Talks to the locally installed [Codex CLI](https://github.com/openai/codex) through its App Server
(`codex app-server`, JSON-RPC over stdio). Never reads `~/.codex/auth.json` and never calls any
ChatGPT HTTP endpoint directly — the App Server does the authenticated fetch via the documented
`account/rateLimits/read` method.

## Usage

```sh
rcodex --usage              # colorized, sensors-style
rcodex --usage --simple     # plain `sensors`-with-no-args style: no bars, no color
rcodex --usage --json       # normalized JSON, for scripts
rcodex --usage --raw        # untouched account/rateLimits/read result
rcodex --usage --debug      # echo JSON-RPC traffic + app-server stderr
```

Default output:

```
rcodex-usage
Adapter: Codex App Server (0.149.1)

plan:     plus
5-hour:     0% used  100% left  [....................]  resets Mon 2026-09-07 02:24 -03 (in 5h)
weekly:    31% used   69% left  [######..............]  resets Sat 2026-09-12 20:14 -03 (in 5d 22h)
credits:  none
```

`--simple` output:

```
rcodex-usage
5-hour: 0% used, resets in 5h
weekly: 31% used, resets in 5d 22h
plan:   plus
```

Colors are on by default when stdout is a terminal, respect [`NO_COLOR`](https://no-color.org),
and can be forced either way with `--color` / `--no-color`. The usage bars are colored by how
close a window is to its limit: green under 60%, yellow from 60%, red from 85%.

## Install

As a gem, from source (not published to rubygems.org):

```sh
git clone https://github.com/matheusb96/codex-usage.git
cd codex-usage
gem build rcodex.gemspec
gem install ./rcodex-*.gem
```

This installs the `rcodex` executable on your `PATH`.

Requirements:

- Ruby >= 2.6 (stdlib only: `json`, `open3`, `optparse`, `time` — no runtime gem dependencies)
- [Codex CLI](https://github.com/openai/codex) on `PATH`, logged in with ChatGPT (`codex login`),
  not API-key auth. Override the binary with `CODEX_BIN` or `--codex PATH`.

## Development

```sh
bundle install       # dev dependencies only: minitest, rake
rake test            # runs test/**/*_test.rb
ruby -Ilib bin/rcodex --usage   # run without installing
```

## Architecture

```
lib/rcodex/
  cli.rb                    entry point: option parsing, dispatches to a command
  commands/usage_command.rb orchestrates one usage report end to end
  app_server/
    connection.rb            JSON-RPC transport to `codex app-server` (stdio, newline-delimited JSON)
    client.rb                named methods for the app-server calls we use (handshake, account, rate_limits)
    usage_mapper.rb           anti-corruption layer: raw JSON -> domain objects
  domain/
    account.rb, credits_balance.rb, rate_limit_window.rb, usage_snapshot.rb
                               plain value objects / aggregate root — no JSON-RPC knowledge
  presenters/
    human_presenter.rb, simple_presenter.rb, json_presenter.rb, raw_presenter.rb
    aligned_rows.rb            shared column-alignment helper (label width derived from content, not hardcoded)
```

The domain layer never sees a raw JSON-RPC response — `AppServer::UsageMapper` is the only place
that knows the backend's field names and window-duration conventions (300 minutes = 5-hour,
10080 = weekly). Everything downstream works with `RCodex::Domain::UsageSnapshot`.

## How it works

1. Spawns `codex app-server` (stdio, newline-delimited JSON-RPC, `"jsonrpc"` header omitted).
2. Sends `initialize` + `initialized` handshake.
3. Calls `account/read` (plan/email fallback) and `account/rateLimits/read` (no params).
4. Maps the raw response into `RCodex::Domain::UsageSnapshot`, classifying `primary`/`secondary`
   windows by `windowDurationMins` rather than by position, so a backend reorder won't mislabel
   them.
5. Closes stdin so the server exits on EOF; escalates to `TERM` then `KILL` if it lingers.

Protocol verified against codex-cli 0.149.1's own `generate-json-schema` output and the
`openai/codex` source (`app-server/README.md`, `app-server-protocol`, `backend-client`).

Exit codes: `0` ok, `1` protocol/usage error, `2` not logged in / not ChatGPT auth,
`3` codex binary not found, `4` timeout.

## Notes

- `account/rateLimits/read` does not consume model usage or credits — it's a plain backend GET
  (`/wham/usage`), not a thread/turn.
- No runtime dependencies beyond Ruby's standard library.

## License

MIT
