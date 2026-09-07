# codex-usage

Small CLI that prints your ChatGPT Plus / Codex rate-limit usage, `sensors`-style.

Talks to the locally installed [Codex CLI](https://github.com/openai/codex) through its App Server
(`codex app-server`, JSON-RPC over stdio). Never reads `~/.codex/auth.json` and never calls any
ChatGPT HTTP endpoint directly — the App Server does the authenticated fetch via the documented
`account/rateLimits/read` method.

## Usage

```sh
codex-usage              # human-readable
codex-usage --json       # normalized JSON, for scripts
codex-usage --raw        # untouched account/rateLimits/read result
codex-usage --debug      # echo JSON-RPC traffic + app-server stderr
```

Example output:

```
codex-chatgpt
Adapter: Codex App Server (codex-cli 0.149.1)
plan:      plus
5-hour:      0% used  100% left  [....................]  resets Mon 2026-09-07 02:01 -03 (in 5h)
weekly:     31% used   69% left  [######..............]  resets Sat 2026-09-12 20:14 -03 (in 5d 23h)
credits:   none
```

## Install

```sh
sudo install -m 0755 codex-usage /usr/local/bin/codex-usage
# or user-local
install -m 0755 codex-usage ~/.local/bin/codex-usage
```

Requirements:

- Ruby >= 2.7 (stdlib only: `json`, `open3`, `optparse`, `time`)
- [Codex CLI](https://github.com/openai/codex) on `PATH`, logged in with ChatGPT (`codex login`),
  not API-key auth. Override the binary with `CODEX_BIN` or `--codex PATH`.

## How it works

1. Spawns `codex app-server` (stdio, newline-delimited JSON-RPC, `"jsonrpc"` header omitted).
2. Sends `initialize` + `initialized` handshake.
3. Calls `account/read` (plan/email fallback) and `account/rateLimits/read` (no params).
4. Normalizes `primary`/`secondary` rate-limit windows by `windowDurationMins` (300 = 5-hour,
   10080 = weekly) rather than by position, so a backend reorder won't mislabel them.
5. Closes stdin so the server exits on EOF; escalates to `TERM` then `KILL` if it lingers.

Protocol verified against codex-cli 0.149.1's own `generate-json-schema` output and the
`openai/codex` source (`app-server/README.md`, `app-server-protocol`, `backend-client`).

Exit codes: `0` ok, `1` protocol/usage error, `2` not logged in / not ChatGPT auth,
`3` codex binary not found, `4` timeout.

## Notes

- `account/rateLimits/read` does not consume model usage or credits — it's a plain backend GET
  (`/wham/usage`), not a thread/turn.
- No dependencies beyond Ruby's standard library.

## License

MIT
