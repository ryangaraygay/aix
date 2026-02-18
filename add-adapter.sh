#!/bin/bash
# Add an additional adapter to an already initialized AIX repo.
# Usage:
#   ~/tools/aix/add-adapter.sh <adapter> [--model-set <name>] [--repo-root <path>]

set -e

AIX_FRAMEWORK="${AIX_FRAMEWORK:-$HOME/tools/aix}"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
MODEL_SET=""

usage() {
    echo "Usage: $0 <adapter> [--model-set <name>] [--repo-root <path>]"
    echo ""
    echo "Adapters: claude, opencode, factory, agentskills, kiro"
    echo ""
    echo "Examples:"
    echo "  $0 opencode"
    echo "  $0 opencode --model-set codex-5.3"
    echo "  $0 kiro --repo-root /path/to/repo"
}

ADAPTER_INPUT="${1:-}"
if [ -z "$ADAPTER_INPUT" ] || [ "$ADAPTER_INPUT" = "--help" ] || [ "$ADAPTER_INPUT" = "-h" ]; then
    usage
    exit 0
fi
shift

while [[ $# -gt 0 ]]; do
    case "$1" in
        --model-set)
            MODEL_SET="$2"
            shift 2
            ;;
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

ADAPTER_KEY=""
ADAPTER_DIR=""
ENTRYPOINT=""

case "$ADAPTER_INPUT" in
    claude|claude-code)
        ADAPTER_KEY="claude"
        ADAPTER_DIR="claude-code"
        ENTRYPOINT="CLAUDE.md"
        ;;
    opencode)
        ADAPTER_KEY="opencode"
        ADAPTER_DIR="opencode"
        ENTRYPOINT="AGENTS.md"
        ;;
    factory|droid)
        ADAPTER_KEY="factory"
        ADAPTER_DIR="factory"
        ENTRYPOINT="GEMINI.md"
        ;;
    agentskills|agent-skills)
        ADAPTER_KEY="agentskills"
        ADAPTER_DIR="agentskills"
        ENTRYPOINT=""
        ;;
    kiro|kiro-cli)
        ADAPTER_KEY="kiro"
        ADAPTER_DIR="kiro-cli"
        ENTRYPOINT="AGENTS.md"
        ;;
    *)
        echo "Unsupported adapter: $ADAPTER_INPUT"
        usage
        exit 1
        ;;
esac

AIX_DIR="$REPO_ROOT/.aix"
TIER_FILE="$AIX_DIR/tier.yaml"
MANIFEST_FILE="$AIX_DIR/manifest.json"
MANIFEST_TOOL="$AIX_FRAMEWORK/scripts/aix-manifest.py"
GENERATOR="$AIX_FRAMEWORK/scripts/aix-generate.py"
SOURCE_ADAPTER_DIR="$AIX_FRAMEWORK/adapters/$ADAPTER_DIR"
DEST_ADAPTER_DIR="$AIX_DIR/adapters/$ADAPTER_KEY"

if [ ! -d "$AIX_DIR" ]; then
    echo "Error: aix not initialized at $REPO_ROOT"
    exit 1
fi

if [ ! -d "$SOURCE_ADAPTER_DIR" ]; then
    echo "Error: adapter source not found: $SOURCE_ADAPTER_DIR"
    exit 1
fi

if [ ! -f "$TIER_FILE" ]; then
    echo "Error: tier file not found: $TIER_FILE"
    exit 1
fi

mkdir -p "$DEST_ADAPTER_DIR"
cp "$SOURCE_ADAPTER_DIR/adapter.yaml" "$DEST_ADAPTER_DIR/adapter.yaml"
if [ -d "$SOURCE_ADAPTER_DIR/model-sets" ]; then
    rm -rf "$DEST_ADAPTER_DIR/model-sets"
    cp -r "$SOURCE_ADAPTER_DIR/model-sets" "$DEST_ADAPTER_DIR/model-sets"
fi

if [ -z "$MODEL_SET" ] && [ -f "$SOURCE_ADAPTER_DIR/adapter.yaml" ]; then
    MODEL_SET=$(grep -A2 "model_sets:" "$SOURCE_ADAPTER_DIR/adapter.yaml" | grep "default:" | sed 's/.*default: *//' | tr -d ' ')
fi

if [ -n "$MODEL_SET" ] && [ ! -f "$DEST_ADAPTER_DIR/model-sets/$MODEL_SET.yaml" ]; then
    echo "Error: model set '$MODEL_SET' not found in $DEST_ADAPTER_DIR/model-sets"
    exit 1
fi

python3 - "$TIER_FILE" "$ADAPTER_KEY" "$MODEL_SET" << 'PY'
import sys
from pathlib import Path

try:
    import yaml
except Exception as exc:
    raise SystemExit(f"PyYAML is required to update tier.yaml: {exc}")

tier_file = Path(sys.argv[1])
adapter = sys.argv[2]
model_set = sys.argv[3]

data = yaml.safe_load(tier_file.read_text()) or {}
adapters = data.get("adapters")
if not isinstance(adapters, dict):
    adapters = {}

entry = adapters.get(adapter)
if not isinstance(entry, dict):
    entry = {}

entry["enabled"] = True
if model_set:
    entry["model_set"] = model_set

adapters[adapter] = entry
data["adapters"] = adapters

tier_file.write_text(yaml.safe_dump(data, sort_keys=False))
PY

if [ -f "$MANIFEST_TOOL" ]; then
    python3 "$MANIFEST_TOOL" init \
        --manifest "$MANIFEST_FILE"
    python3 "$MANIFEST_TOOL" record-dir \
        --manifest "$MANIFEST_FILE" \
        --repo-root "$REPO_ROOT" \
        --framework-root "$AIX_FRAMEWORK" \
        --source-root "$SOURCE_ADAPTER_DIR" \
        --dest-root "$DEST_ADAPTER_DIR" \
        --capability "adapter-$ADAPTER_KEY"
fi

if [ -f "$GENERATOR" ]; then
    if [ -n "$MODEL_SET" ]; then
        python3 "$GENERATOR" --repo-root "$REPO_ROOT" --adapter "$ADAPTER_KEY" --model-set "$MODEL_SET"
    else
        python3 "$GENERATOR" --repo-root "$REPO_ROOT" --adapter "$ADAPTER_KEY"
    fi
else
    echo "Warning: aix-generate.py not found at $GENERATOR"
fi

if [ -n "$ENTRYPOINT" ]; then
    ln -sf .aix/constitution.md "$REPO_ROOT/$ENTRYPOINT"
fi

echo ""
echo "Added adapter: $ADAPTER_KEY"
echo "- Repo: $REPO_ROOT"
echo "- Adapter dir: $DEST_ADAPTER_DIR"
if [ -n "$MODEL_SET" ]; then
    echo "- Model set: $MODEL_SET"
fi
if [ -n "$ENTRYPOINT" ]; then
    echo "- Entrypoint: $ENTRYPOINT -> .aix/constitution.md"
fi
echo ""
echo "Run 'git -C \"$REPO_ROOT\" status --short' to review changes."
