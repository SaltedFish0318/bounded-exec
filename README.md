# bounded-output Codex Skill

[中文文档](README.zh-CN.md)

A global Codex skill and helper scripts for low-token execution of noisy commands.

It keeps full command output on disk while returning compact summaries to the Codex conversation. The goal is not to block work, but to preserve execution continuity without flooding context with large logs.

## What It Covers

- build, compile, test, lint, benchmark, and CI-like commands
- dependency install/update commands
- Docker, Kubernetes, systemd, and journal logs
- large files and large logs
- broad search and directory scans
- long-running commands and progress-heavy tools

## Install

From this project directory:

```sh
./install.sh
```

The installer creates symlinks:

- `~/.agents/skills/bounded-output -> ./skill`
- `~/.codex/skills/bounded-output -> ./skill`
- `~/.codex/bin/bounded-exec -> ./bin/bounded-exec`
- `~/.codex/bin/bounded-preview -> ./bin/bounded-preview`
- `~/.codex/bin/bounded-output-hook -> ./bin/bounded-output-hook`

This makes the project easy to edit in one place while keeping Codex global paths stable.

## Usage

Run high-output commands through `bounded-exec`:

```sh
~/.codex/bin/bounded-exec --scope "focused test" -- pytest tests/test_api.py -q
~/.codex/bin/bounded-exec --scope "targeted build" -- bash -lc 'make check'
```

Preview large files, logs, or search results through `bounded-preview`:

```sh
~/.codex/bin/bounded-preview tail app.log
~/.codex/bin/bounded-preview grep "ERROR|FAILED" app.log
~/.codex/bin/bounded-preview sed 120:180 src/file.c
~/.codex/bin/bounded-preview scan app.log "timeout|denied"
~/.codex/bin/bounded-preview rg "SomeSymbol" src tests
```

`sed START:END` refuses ranges larger than `--lines` to avoid accidental large output.
`scan FILE [QUERY...]` is the fallback when targeted searches miss: it writes a full scan report to disk, prints only bounded candidates, and falls back to small head/tail samples when there are no matches.

Full output is written under:

```text
~/.codex/logs/bounded-output/
```

Long commands are truncated in `OP_SUMMARY`; the full command is kept in the adjacent `.meta` file.
Lightweight event history is appended to `~/.codex/logs/bounded-output/events.log` for later troubleshooting and tuning.
Set `BOUNDED_OUTPUT_LOG_EVENTS=0` to disable that event log.

## Optional Hook

`bin/bounded-output-hook` is a lightweight PreToolUse helper. By default it blocks obvious high-output bare commands and prints a bounded replacement command.

Codex hooks require this feature flag in `~/.codex/config.toml`:

```toml
[features]
codex_hooks = true
```

Then merge the PreToolUse entry from `docs/codex-hooks-example.json` into `~/.codex/hooks.json`. If you already have a Bash PreToolUse hook, add the `~/.codex/bin/bounded-output-hook` command after your existing preflight hook instead of replacing the whole file.

Temporary bypass:

```sh
BOUNDED_OUTPUT_DISABLE_HOOK=1
```

Warn-only mode:

```sh
export BOUNDED_OUTPUT_HOOK_MODE=warn
```

## Design

The default workflow is:

1. smallest useful scope
2. output to disk
3. compact summary in context
4. continue from the summary
5. expand scope only when justified

This reduces token usage while preserving normal edit-test-debug momentum.
