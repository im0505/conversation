# codex-chat-log

Extract user/assistant messages from Codex `.jsonl` session logs.

## Features

- Filters only conversation messages (user / assistant)
- Supports TSV (default) and JSON (Q/A pair) output
- Works with multiple `rollout-*.jsonl` files

## Usage

```bash
./codex-chat-log.sh [--json] [files...]



