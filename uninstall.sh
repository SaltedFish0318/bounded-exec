#!/usr/bin/env bash
set -eu

project_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
home_dir="${HOME:?HOME is required}"

skill_name="bounded-output"
agents_skill_dir="$home_dir/.agents/skills/$skill_name"
codex_skill_dir="$home_dir/.codex/skills/$skill_name"
codex_bin_dir="$home_dir/.codex/bin"
hooks_json_path="$home_dir/.codex/hooks.json"
bounded_hook_command="bash -lc 'exec \"\$HOME/.codex/bin/bounded-output-hook\"'"
bounded_hook_status="Checking bounded-output risk"

remove_link_if_owned() {
  target="$1"
  link_path="$2"

  if [ ! -L "$link_path" ]; then
    printf 'Skip: %s is not a symlink managed by this project\n' "$link_path"
    return 0
  fi

  current_target="$(readlink "$link_path")"
  if [ "$current_target" != "$target" ]; then
    printf 'Skip: %s points elsewhere (%s)\n' "$link_path" "$current_target"
    return 0
  fi

  rm "$link_path"
  printf 'Removed: %s\n' "$link_path"
}

remove_link_if_owned "$project_dir/skill" "$agents_skill_dir"
remove_link_if_owned "$project_dir/skill" "$codex_skill_dir"

remove_link_if_owned "$project_dir/bin/bounded-exec" "$codex_bin_dir/bounded-exec"
remove_link_if_owned "$project_dir/bin/bounded-preview" "$codex_bin_dir/bounded-preview"
remove_link_if_owned "$project_dir/bin/bounded-output-hook" "$codex_bin_dir/bounded-output-hook"

remove_bounded_hook_entry() {
  if [ ! -f "$hooks_json_path" ]; then
    printf 'Skip: %s does not exist\n' "$hooks_json_path"
    return 0
  fi

  if ! command -v jq >/dev/null 2>&1; then
    printf 'Skip: jq not found, manual cleanup needed for %s\n' "$hooks_json_path"
    return 0
  fi

  if ! jq -e --arg cmd "$bounded_hook_command" --arg status "$bounded_hook_status" '
    any(.hooks.PreToolUse[]?; .matcher == "Bash" and any(.hooks[]?; .type == "command" and .command == $cmd and .statusMessage == $status))
  ' "$hooks_json_path" >/dev/null 2>&1; then
    printf 'Skip: bounded-output hook entry not present in %s\n' "$hooks_json_path"
    return 0
  fi

  tmp_json="$(mktemp "${TMPDIR:-/tmp}/bounded-output-hooks.XXXXXX")"
  jq --arg cmd "$bounded_hook_command" --arg status "$bounded_hook_status" '
    .hooks.PreToolUse |= (
      (. // [])
      | map(
          if .matcher == "Bash" then
            .hooks |= map(select(.type != "command" or .command != $cmd or .statusMessage != $status))
          else
            .
          end
        )
      | map(select((.hooks | length) > 0))
    )
  ' "$hooks_json_path" > "$tmp_json"
  mv "$tmp_json" "$hooks_json_path"
  printf 'Removed bounded-output hook entry from %s\n' "$hooks_json_path"
}

remove_bounded_hook_entry

cat <<EOF
Uninstalled bounded-output Codex skill symlinks owned by this project.

Not removed:
  $project_dir
  $home_dir/.codex/logs/bounded-output/
  Any *.backup.* files created during install
  Any manual bounded-output edits in $home_dir/.codex/AGENTS.md or $home_dir/.codex/config.toml
EOF
