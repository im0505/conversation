#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  codex-chat-log.sh [--json] [files...]

Description:
  Extract user/assistant messages from Codex rollout JSONL logs.

Options:
  --json    Output question/answer pairs as JSON
  -h, --help  Show this help

Examples:
  codex-chat-log.sh
  codex-chat-log.sh ~/.codex/sessions/2026/04/08/rollout-*.jsonl
  codex-chat-log.sh --json rollout-*.jsonl
EOF
}

json_mode=0
declare -a files=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      json_mode=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      files+=("$1")
      shift
      ;;
  esac
done

if [[ ${#files[@]} -eq 0 ]]; then
  shopt -s nullglob
  files=(rollout-*.jsonl)
  shopt -u nullglob
fi

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No rollout JSONL files found." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required but not installed." >&2
  exit 1
fi

if [[ "$json_mode" -eq 1 ]]; then
  jq -s '
    map(
      select(.type=="response_item" and .payload.type=="message")
      | {
          role: .payload.role,
          text: (
            .payload.content
            | map(select(.type=="input_text" or .type=="output_text") | .text)
            | join("")
          )
        }
      | select(.role=="user" or .role=="assistant")
    )
    | reduce .[] as $m (
        [];
        if $m.role == "user" then
          . + [{question: $m.text}]
        elif $m.role == "assistant" and (length > 0) then
          .[-1].answer = $m.text
          | .
        else
          .
        end
      )
  ' "${files[@]}"
else
  jq -r '
    select(.type=="response_item" and .payload.type=="message")
    | {
        role: .payload.role,
        text: (
          .payload.content
          | map(select(.type=="input_text" or .type=="output_text") | .text)
          | join("")
        )
      }
    | select(.role=="user" or .role=="assistant")
    | [.role, .text]
    | @tsv
  ' "${files[@]}"
fi
