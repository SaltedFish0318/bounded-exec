#!/usr/bin/env bash
set -eu

project_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
home_dir="${HOME:?HOME is required}"

skill_name="bounded-output"
agents_skill_dir="$home_dir/.agents/skills/$skill_name"
codex_skill_dir="$home_dir/.codex/skills/$skill_name"
codex_bin_dir="$home_dir/.codex/bin"

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

cat <<EOF
Uninstalled bounded-output Codex skill symlinks owned by this project.

Not removed:
  $project_dir
  $home_dir/.codex/logs/bounded-output/
  Any *.backup.* files created during install
EOF
