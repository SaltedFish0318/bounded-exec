#!/usr/bin/env bash
set -eu

project_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
home_dir="${HOME:?HOME is required}"

skill_name="bounded-output"
agents_skill_dir="$home_dir/.agents/skills/$skill_name"
codex_skill_dir="$home_dir/.codex/skills/$skill_name"
codex_bin_dir="$home_dir/.codex/bin"

mkdir -p "$home_dir/.agents/skills" "$home_dir/.codex/skills" "$codex_bin_dir"

timestamp="$(date +%Y%m%dT%H%M%S)"

link_target() {
  target="$1"
  link_path="$2"

  if [ -L "$link_path" ]; then
    current_target="$(readlink "$link_path")"
    if [ "$current_target" = "$target" ]; then
      printf 'Already linked: %s -> %s\n' "$link_path" "$target"
      return 0
    fi
  fi

  if [ -e "$link_path" ] || [ -L "$link_path" ]; then
    backup="$link_path.backup.$timestamp"
    mv "$link_path" "$backup"
    printf 'Backed up existing target: %s -> %s\n' "$link_path" "$backup"
  fi

  ln -sT "$target" "$link_path"
  printf 'Linked: %s -> %s\n' "$link_path" "$target"
}

link_target "$project_dir/skill" "$agents_skill_dir"
link_target "$project_dir/skill" "$codex_skill_dir"

link_target "$project_dir/bin/bounded-exec" "$codex_bin_dir/bounded-exec"
link_target "$project_dir/bin/bounded-preview" "$codex_bin_dir/bounded-preview"
link_target "$project_dir/bin/bounded-output-hook" "$codex_bin_dir/bounded-output-hook"

chmod 755 "$project_dir/bin/bounded-exec" "$project_dir/bin/bounded-preview" "$project_dir/bin/bounded-output-hook"

cat <<EOF
Installed bounded-output Codex skill.

Skill:
  $agents_skill_dir -> $project_dir/skill
  $codex_skill_dir -> $project_dir/skill

Commands:
  $codex_bin_dir/bounded-exec
  $codex_bin_dir/bounded-preview
  $codex_bin_dir/bounded-output-hook

Optional hook:
  Add $codex_bin_dir/bounded-output-hook to Codex PreToolUse hooks for Bash.
EOF
