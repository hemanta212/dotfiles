# =============================================================================
# Claude AI Assistant Configuration for Zsh
# Converted from Fish shell configuration
# =============================================================================

# Claude wrapper function - equivalent to fish 'cl' function
# Original fish: function cl --wraps claude
#                    claude --ide --continue $argv || claude --ide $argv
#                end
function cl() {
    # Try with --continue first, fallback to without if it fails
    claude='/opt/homebrew/bin/claude'
    PATH=$PATH:/opt/homebrew/bin EDITOR=/opt/homebrew/bin/nvim ANTHROPIC_API_KEY='' $claude --ide --continue "$@" --dangerously-skip-permissions || EDITOR=/opt/homebrew/bin/nvim ANTHROPIC_API_KEY='' $claude --ide "$@" --dangerously-skip-permissions
}

# Completion for claude command
# Note: This assumes you have claude completion available
# If you need to set up claude completion, add it to your completion system

# Completion for named-claude (if you use it)
# Original fish: complete -c named-claude -w claude
# In zsh, you would typically handle this through your completion system
# Example for zsh completion (uncomment if needed):
# compdef named-claude=claude

# =============================================================================
# Additional Claude-related configurations
# =============================================================================

# If you want to add any claude-specific aliases or environment variables,
# add them here. For example:

# Export any claude-specific environment variables if needed
# export CLAUDE_CONFIG_PATH="$HOME/.config/claude"

# Additional aliases (add as needed)
# alias claude-help="claude --help"
# alias claude-version="claude --version"

# =============================================================================
# Usage Notes
# =============================================================================
# 
# This file contains the claude configurations converted from your fish shell setup.
# 
# Main function:
#   cl - Wrapper for claude command that tries --ide --continue first, 
#        then falls back to --ide if that fails
#
# To use this file, source it in your .zshrc:
#   source "$HOME/dotfiles/zsh/claude.zsh"
#
# Or if you have a modular zsh setup, place it in your zsh functions/autoload directory
codex_resume() {
  emulate -L zsh
  setopt localoptions extendedglob noshwordsplit
  unsetopt xtrace verbose 2>/dev/null || true
  set +x +v

  local want_last=0 list_any=0 limit=200 target_dir="" sep=$'\t' preview=1
  local preview_script="$HOME/dev/dotfiles/scripts/codex_resume_preview"
  if [[ ! -x "$preview_script" ]]; then
    local maybe_preview
    maybe_preview=$(command -v codex_resume_preview 2>/dev/null || true)
    if [[ -n "$maybe_preview" && -x "$maybe_preview" ]]; then
      preview_script="$maybe_preview"
    else
      preview_script=""
    fi
  fi
  local -a passthru

  while (( $# > 0 )); do
    case "$1" in
      --last) want_last=1; shift ;;
      --any)  list_any=1; shift ;;
      --dir)
        if [[ -z ${2-} ]]; then
          echo "codex_resume: --dir requires a path" >&2
          return 2
        fi
        target_dir=$2
        shift 2 ;;
      --limit)
        if [[ -z ${2-} ]]; then
          echo "codex_resume: --limit requires a value" >&2
          return 2
        fi
        limit=$2
        shift 2 ;;
      --no-preview) preview=0; shift ;;
      --help)
        cat <<'USAGE'
Usage: codex_resume [--last] [--any] [--dir PATH] [--limit N] [--no-preview] [--] [codex resume args...]

Select a Codex CLI session and resume it via `codex resume <session-id>`.
  --last        Resume the newest matching session without prompting.
  --any         Ignore the directory filter and show every session.
  --dir PATH    Match sessions started from PATH (defaults to $PWD).
  --limit N     Limit the number of sessions scanned (default 200).
  --no-preview  Disable the interactive preview pane.
  --help        Show this message.
Use `--` to pass flags directly to `codex resume`.
USAGE
        return 0 ;;
      --)
        shift
        passthru=("$@")
        break ;;
      --*)
        echo "codex_resume: unknown option: $1" >&2
        return 2 ;;
      *)
        passthru+=("$1")
        shift ;;
    esac
  done

  if [[ -z "$target_dir" ]]; then
    target_dir=$(pwd -P)
  else
    if [[ -d "$target_dir" ]]; then
      target_dir=$(cd "$target_dir" 2>/dev/null && pwd -P)
    else
      echo "codex_resume: --dir path does not exist: $target_dir" >&2
      return 2
    fi
  fi

  local session_root="$HOME/.codex/sessions"
  if [[ ! -d "$session_root" ]]; then
    echo "codex_resume: no sessions directory at $session_root" >&2
    return 1
  fi

  local -a files
  files=(${~session_root}/*/*/*/*.jsonl(N))
  if (( ${#files[@]} == 0 )); then
    echo "codex_resume: no session files found under $session_root" >&2
    return 1
  fi

  local have_python=0 have_jq=0
  command -v python3 >/dev/null 2>&1 && have_python=1
  command -v jq >/dev/null 2>&1 && have_jq=1

  local -a candidates sorted_entries session_paths session_ids session_cwds session_timestamps session_summaries session_mtimes session_repos session_branches
  local entry f mtime meta_tsv session_id session_cwd session_ts session_repo session_branch session_instr session_prompt session_cli

  for f in "${files[@]}"; do
    mtime=$(stat -f %m -- "$f" 2>/dev/null) || continue
    candidates+=("${mtime}${sep}${f}")
  done

  if (( ${#candidates[@]} == 0 )); then
    echo "codex_resume: unable to read session timestamps" >&2
    return 1
  fi

  IFS=$'\n' sorted_entries=($(printf '%s\n' "${candidates[@]}" | LC_ALL=C sort -t"$sep" -k1,1nr))
  unset IFS

  for entry in "${sorted_entries[@]}"; do
    f=${entry#*$sep}
    mtime=${entry%%$sep*}

    if (( have_python )); then
      meta_tsv=$(python3 - "$f" <<'PY' 2>/dev/null
import json, re, sys, pathlib
path = pathlib.Path(sys.argv[1])
meta = None
first_user = ""
try:
    with path.open() as fh:
        for raw in fh:
            obj = json.loads(raw)
            t = obj.get("type")
            if t == "session_meta" and meta is None:
                meta = obj
                if first_user:
                    break
            elif t == "response_item" and not first_user:
                payload = obj.get("payload") or {}
                if payload.get("type") != "message":
                    continue
                role = payload.get("role") or (payload.get("message") or {}).get("role")
                if role and role != "user":
                    continue
                texts = []
                for chunk in payload.get("content") or []:
                    if chunk.get("type") == "input_text":
                        texts.append(chunk.get("text") or "")
                if texts:
                    first_user = "\n".join(texts).strip()
                if meta is not None:
                    break
except (OSError, json.JSONDecodeError):
    pass

payload = (meta or {}).get("payload") or {}
git = payload.get("git") or {}

def strip_noise(text):
    if not text:
        return ""
    for marker in ("</user_instructions>", "</environment_context>"):
        idx = text.find(marker)
        if idx != -1:
            text = text[idx + len(marker):]
            break
    return text.lstrip()

def clean(text):
    if not text:
        return ""
    text = re.sub(r"\s+", " ", text.replace("\t", " "))
    return text.strip()[:160]
instr_text = strip_noise(payload.get("instructions") or "")
first_user_text = strip_noise(first_user)

fields = [
    payload.get("id", ""),
    payload.get("cwd", ""),
    payload.get("timestamp", ""),
    git.get("repository_url", ""),
    git.get("branch", ""),
    clean(instr_text),
    clean(first_user_text),
    payload.get("cli_version", ""),
]
print("\t".join(fields))
PY
)
    elif (( have_jq )); then
      meta_tsv=$(head -n 1 "$f" 2>/dev/null | jq -r '[.payload.id, .payload.cwd, .payload.timestamp, (.payload.git.repository_url // ""), (.payload.git.branch // ""), (.payload.instructions // ""), "", (.payload.cli_version // "")] | @tsv' 2>/dev/null)
    else
      meta_tsv=""
    fi

    [[ -z "$meta_tsv" ]] && continue

    IFS=$'\t' read -r session_id session_cwd session_ts session_repo session_branch session_instr session_prompt session_cli <<<"$meta_tsv"
    unset IFS

    [[ -z "$session_id" ]] && continue

    if [[ -n "$session_cwd" && -d "$session_cwd" ]]; then
      session_cwd=$(cd "$session_cwd" 2>/dev/null && pwd -P)
    fi

    if (( ! list_any )); then
      if [[ "$session_cwd" != "$target_dir" ]]; then
        continue
      fi
    fi

    local summary="$session_instr"
    if [[ -z "$summary" ]]; then
      summary="$session_prompt"
    fi
    if [[ -z "$summary" ]]; then
      summary="(no prompt captured)"
    fi
    summary=${summary//$'\r'/}
    if (( ${#summary} > 90 )); then
      summary="${summary:0:87}..."
    fi

    session_paths+=("$f")
    session_ids+=("$session_id")
    session_cwds+=("$session_cwd")
    session_timestamps+=("$session_ts")
    session_summaries+=("$summary")
    session_mtimes+=("$mtime")
    session_repos+=("$session_repo")
    session_branches+=("$session_branch")

    (( ${#session_ids[@]} >= limit )) && break
  done

  if (( ${#session_ids[@]} == 0 )); then
    if (( list_any )); then
      echo "codex_resume: no sessions available" >&2
    else
      echo "codex_resume: no sessions found for $target_dir" >&2
      echo "Tip: try 'codex_resume --any' to browse across all projects." >&2
    fi
    return 1
  fi

  local picked_index=1 picked_path="" picked_id=""
  if (( want_last || ${#session_ids[@]} == 1 )); then
    picked_index=1
  else
    if command -v fzf >/dev/null 2>&1 && [[ -t 1 ]]; then
      local -a menu_lines
      local esc=$'\033'
      local reset="${esc}[0m"
      local dim="${esc}[90m"
      local green="${esc}[32m"
      local cyan="${esc}[36m"
      local blue="${esc}[94m"
      local idx=1 max=$#session_ids
      while (( idx <= max )); do
        local ts repo branch summary cwd_display short_id repo_display
        ts=$(date -r "${session_mtimes[idx]}" +"%Y-%m-%d %H:%M" 2>/dev/null)
        if [[ -z "$ts" ]]; then
          ts="unknown"
        fi
        cwd_display="${session_cwds[idx]}"
        [[ -z "$cwd_display" ]] && cwd_display="$target_dir"
        cwd_display="${cwd_display/#$HOME/~}"
        repo="${session_repos[idx]}"
        branch="${session_branches[idx]}"
        summary="${session_summaries[idx]}"
        short_id="${session_ids[idx]}"
        short_id="${short_id:0:8}"
        repo_display=""
        if [[ -n "$repo" ]]; then
          repo_display=${repo##*/}
          repo_display=${repo_display%.git}
        fi
        local label="${dim}${ts}${reset}  ${green}${cwd_display}${reset}"
        if [[ -n "$repo_display" ]]; then
          label+="  ${dim}·${reset}  ${repo_display}"
        fi
        if [[ -n "$branch" ]]; then
          label+=" ${dim}(${cyan}${branch}${dim})${reset}"
        fi
        label+="  ${blue}${short_id}…${reset}  ${summary}"
        menu_lines+=("$label$sep${session_paths[idx]}")
        (( idx++ ))
      done

      local -a preview_opts
      if (( preview )); then
        local preview_cmd
        if [[ -n "$preview_script" && -x "$preview_script" ]]; then
          local preview_quoted
          preview_quoted=$(printf '%q' "$preview_script")
          preview_cmd="${preview_quoted} {2}"
        else
          preview_cmd="head -n 200 -- {2}"
        fi
        preview_opts=(--preview-window=up:60% --preview="$preview_cmd")
      fi

      local sel
      sel=$(printf '%s\n' "${menu_lines[@]}" | fzf --ansi --with-nth=1 --delimiter="$sep" --prompt="codex sessions » " --height=80% --reverse "${preview_opts[@]}" 2>/dev/null) || return 130
      picked_path=${sel#*$sep}

      local match_idx=1 match_max=$#session_paths
      while (( match_idx <= match_max )); do
        if [[ "${session_paths[match_idx]}" == "$picked_path" ]]; then
          picked_index=$match_idx
          break
        fi
        (( match_idx++ ))
      done
    else
      local idx=1 max=$#session_ids choice
      while (( idx <= max )); do
        printf "[%d] %s\n" "$idx" "${session_paths[idx]:t}"
        (( idx++ ))
      done
      printf "Select [1-%d]: " $max
      read choice || return 130
      if [[ -z "$choice" || "$choice" != <-> ]]; then
        echo "codex_resume: invalid selection" >&2
        return 2
      fi
      if (( choice < 1 || choice > max )); then
        echo "codex_resume: selection out of range" >&2
        return 2
      fi
      picked_index=$choice
    fi
  fi

  picked_id=${session_ids[picked_index]}
  picked_path=${session_paths[picked_index]}

  if [[ -z "$picked_id" ]]; then
    echo "codex_resume: failed to determine session id" >&2
    return 1
  fi

  echo "Resuming Codex session ${picked_id} (${picked_path:t})"
  if (( ${#passthru[@]} )); then
    codex resume "$picked_id" "${passthru[@]}"
  else
    codex resume "$picked_id"
  fi
}
