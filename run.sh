#!/usr/bin/env bash
# Run QueryAI on macOS / Linux.
#
#   ./run.sh                          # interactive TUI in the current directory
#   ./run.sh "explain this repo"      # one-off prompt
#   MODEL=groq/llama-3.3-70b-versatile ./run.sh "..."
#   DIR=/path/to/project ./run.sh     # open a different project

set -euo pipefail

MODEL="${MODEL:-google/gemini-3.7-flash}"
DIR="${DIR:-$PWD}"

# 1. Install if missing
if ! command -v queryai >/dev/null 2>&1; then
  echo "Installing QueryAI..."
  curl -fsSL https://raw.githubusercontent.com/QueryAI-org/QueryAI/main/install | bash
  export PATH="$HOME/.queryai/bin:$PATH"
fi
echo "QueryAI $(queryai --version)"

# 2. Make sure at least one provider key is configured
models="$(queryai models 2>/dev/null || true)"
if [ -z "$models" ]; then
  echo "No provider keys yet. Pick one (Google, Groq and OpenRouter have free tiers)."
  queryai providers login
  models="$(queryai models 2>/dev/null || true)"
  [ -n "$models" ] || { echo "Still no models available. Check: queryai providers list" >&2; exit 1; }
fi

# 3. Fall back to the first available model if the default is not unlocked
if ! grep -qxF "$MODEL" <<<"$models"; then
  MODEL="$(head -n1 <<<"$models")"
  echo "Default model not available, using $MODEL"
fi

# 4. Launch
cd "$DIR"
if [ $# -gt 0 ]; then
  exec queryai run -m "$MODEL" "$*"
else
  exec queryai -m "$MODEL"
fi
