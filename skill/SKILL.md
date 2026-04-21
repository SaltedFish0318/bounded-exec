---
name: bounded-output
description: Global low-output execution skill for build, test, install, log, large-file, search, benchmark, and long-running commands. Use when command output may be large or continuous and Codex should keep full output on disk while continuing from compact summaries.
---

# bounded-output

Global, reusable low-output execution discipline for Codex work. Use this skill whenever a task may produce large logs, continuous output, broad search results, or expensive command transcripts.

## When To Use

Use for:
- verification after code changes
- dependency installation and environment preparation
- build, compile, test, lint, benchmark, package, and CI-like commands
- container, infrastructure, and service-log commands
- large file or large log inspection
- broad search, large directory listing, archive extraction, download progress, or long-running status observation

Do not use for:
- ordinary short commands that clearly print only a few lines
- pure reasoning, pure reading, or planning with no command execution
- small targeted file reads where the expected output is already bounded

## Operating Rule

Prefer this sequence:

1. Smallest useful scope.
2. Output to disk.
3. Minimal summary in the conversation.
4. Continue from the summary.
5. Expand scope only when evidence says it is needed.

Do not stop after a bounded summary if the next safe action is clear. Continue fixing, narrowing, or expanding verification unless the next step is destructive, credential-gated, production-impacting, or materially ambiguous.

## Scope Discipline

Always prefer:
- single module over whole repository
- one test or focused test class over all tests
- compile/check over a full release pipeline
- targeted log slices over full logs
- bounded preview over `cat` of a large file
- targeted search paths and globs over whole-disk or whole-home searches
- incremental execution over clean full rebuilds

Avoid full clean rebuilds, whole-repo searches, verbose archives, infinite log follows, and broad dependency updates unless the task requires them.

## Required Wrapper Use

High-output tasks must go through a wrapper before normal shell execution.

Use:

```sh
~/.codex/bin/bounded-exec --scope "<small scope>" -- <command> [args...]
```

For shell features, wrap the command explicitly:

```sh
~/.codex/bin/bounded-exec --scope "focused test" -- bash -lc 'pytest tests/test_api.py -q'
```

The wrapper must:
- write full stdout/stderr to a timestamped log file
- print only `OP_SUMMARY` metadata and a small tail/error excerpt
- include status, command, scope, elapsed seconds, exit code, and log path
- truncate very long commands in `OP_SUMMARY` and keep the full command in `.meta`
- print only 1 to 3 summary lines on success
- on failure, print the first actionable error if detected plus a small tail
- return the wrapped command exit code

Covered command families include build/test/lint/benchmark tools, dependency install/update commands, Docker/Kubernetes/system logs, verbose archive/download commands, broad search/list commands, and any command that may stream or print large output.

## Preview Rule

Large files, large logs, and broad search output must use limited preview first:

```sh
~/.codex/bin/bounded-preview tail path/to/log
~/.codex/bin/bounded-preview head path/to/file
~/.codex/bin/bounded-preview grep "error|failed" path/to/log
~/.codex/bin/bounded-preview rg "symbol" src tests
~/.codex/bin/bounded-preview sed 120:180 path/to/file
~/.codex/bin/bounded-preview scan path/to/log "timeout|denied"
```

Preview rules:
- inspect head, tail, or key matches first
- read local context only after a specific line or error is identified
- do not directly `cat` large files
- do not directly follow infinite streams such as `tail -f`
- read recent N lines or keyword-matched slices for logs
- keep `sed START:END` ranges within the configured preview line limit
- if targeted search misses, use `scan FILE [QUERY...]` before widening to full output

## Continuity

After each bounded command:
- use `status`, `exit_code`, `first_error`, and `log_path` to decide the next action
- if the small verification passes, decide whether broader verification is warranted
- if it fails, inspect the targeted log slice and fix or narrow the problem
- if no actionable error is found, run `bounded-preview scan` on the saved log before asking for help
- poll long-running background jobs with low-frequency status checks, not full output reads
- avoid asking for confirmation unless the next action is destructive, external-production-impacting, or genuinely ambiguous

## Temporary Bypass

Only bypass when output is known to be small or when explicitly requested. If bypassing, state the reason briefly and keep tool output bounded with `max_output_tokens` where available.
