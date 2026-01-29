#!/bin/bash
# Git worktree cleanup script
#
# Usage: ./.aix/scripts/worktree-cleanup.sh <feature-name>
#
# Removes a worktree and optionally deletes the branch.

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

error() {
    echo -e "${RED}Error: $*${NC}" >&2
}

warn() {
    echo -e "${YELLOW}Warning: $*${NC}" >&2
}

info() {
    echo -e "${GREEN}$*${NC}"
}

print_help() {
    echo "Usage: ./.aix/scripts/worktree-cleanup.sh <feature-name>"
    echo ""
    echo "Removes a worktree created by worktree-setup.sh:"
    echo "  - Removes worktree at ../<feature-name>"
    echo "  - Optionally deletes branch feat/<feature-name>"
    echo ""
    echo "Options:"
    echo "  --keep-branch    Don't delete the branch after cleanup"
    echo "  --kill-ports     Stop processes listening on worktree ports"
    echo ""
    echo "Examples:"
    echo "  ./.aix/scripts/worktree-cleanup.sh add-search"
    echo "  ./.aix/scripts/worktree-cleanup.sh add-search --keep-branch"
}

get_port_offset() {
    local name="$1"
    local hash=2166136261
    local i char ascii
    for (( i=0; i<${#name}; i++ )); do
        char="${name:$i:1}"
        ascii=$(printf '%d' "'$char")
        hash=$(( hash & 0x7FFFFFFF ))
        hash=$(( (hash ^ ascii) * 16777619 ))
        hash=$(( hash & 0x7FFFFFFF ))
    done
    local slot=$(( (hash & 0x7FFFFFFF) % 100 ))
    echo $((slot * 10))
}

load_config_json() {
    local config_path="$1"
    local output_path="$2"

    if ! command -v python3 >/dev/null 2>&1; then
        error "python3 is required to parse $config_path"
        return 2
    fi

    python3 - "$config_path" "$output_path" <<'PY'
import json
import sys

try:
    import yaml
except Exception as exc:
    print("Missing PyYAML; install with: python3 -m pip install pyyaml", file=sys.stderr)
    print(str(exc), file=sys.stderr)
    sys.exit(2)

config_path = sys.argv[1]
output_path = sys.argv[2]
with open(config_path, "r", encoding="utf-8") as handle:
    data = yaml.safe_load(handle) or {}

with open(output_path, "w", encoding="utf-8") as handle:
    json.dump(data, handle)
PY
}

resolve_path() {
    local repo_root="$1"
    local path="$2"
    python3 - "$repo_root" "$path" <<'PY'
import os
import sys

repo_root = sys.argv[1]
path = sys.argv[2]
if os.path.isabs(path):
    resolved = os.path.abspath(path)
else:
    resolved = os.path.abspath(os.path.join(repo_root, path))
print(resolved)
PY
}

TEMP_FILES=()
register_temp() {
    TEMP_FILES+=("$1")
}

cleanup() {
    for temp in "${TEMP_FILES[@]}"; do
        if [ -f "$temp" ]; then
            rm -f "$temp"
        fi
    done
}
trap cleanup EXIT

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    print_help
    exit 0
fi

KEEP_BRANCH=false
KILL_PORTS=false
FEATURE_NAME=""

for arg in "$@"; do
    case $arg in
        --keep-branch)
            KEEP_BRANCH=true
            ;;
        --kill-ports)
            KILL_PORTS=true
            ;;
        -* )
            error "Unknown option: $arg"
            exit 1
            ;;
        * )
            FEATURE_NAME="$arg"
            ;;
    esac
done

if [ -z "$FEATURE_NAME" ]; then
    error "Feature name required"
    print_help
    exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    error "Not inside a git repository"
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
MAIN_REPO=$(git worktree list --porcelain | awk '/^worktree / {print $2; exit}')
CURRENT_DIR=$(pwd)

SANITIZED_NAME=$(echo "$FEATURE_NAME" | tr -cd '[:alnum:]_-')
if [ -z "$SANITIZED_NAME" ]; then
    error "Feature name contains no valid characters"
    exit 1
fi

CONFIG_PATH=""
if [ -f "$REPO_ROOT/.aix/config/worktree.yaml" ]; then
    CONFIG_PATH="$REPO_ROOT/.aix/config/worktree.yaml"
elif [ -f "$REPO_ROOT/.aix/worktree.yaml" ]; then
    CONFIG_PATH="$REPO_ROOT/.aix/worktree.yaml"
fi

WORKTREE_ROOT=".."
BRANCH_PREFIX="feat/"
CONFIG_JSON=""

if [ -n "$CONFIG_PATH" ]; then
    CONFIG_JSON=$(mktemp)
    register_temp "$CONFIG_JSON"
    if ! load_config_json "$CONFIG_PATH" "$CONFIG_JSON"; then
        error "Failed to parse $CONFIG_PATH"
        exit 1
    fi

    while IFS='=' read -r key value; do
        case "$key" in
            worktree_root)
                WORKTREE_ROOT="$value"
                ;;
            branch_prefix)
                BRANCH_PREFIX="$value"
                ;;
        esac
    done < <(python3 - "$CONFIG_JSON" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], "r", encoding="utf-8"))
for key in ("worktree_root", "branch_prefix"):
    value = data.get(key)
    if value is None:
        continue
    print(f"{key}={value}")
PY
    )
fi

if [[ ! "$BRANCH_PREFIX" =~ ^[A-Za-z0-9._/-]+$ ]] || [[ "$BRANCH_PREFIX" == *".."* ]]; then
    error "Invalid branch_prefix: $BRANCH_PREFIX"
    exit 1
fi

WORKTREE_ROOT_ABS=$(resolve_path "$REPO_ROOT" "$WORKTREE_ROOT")
WORKTREE_PATH="$WORKTREE_ROOT_ABS/$SANITIZED_NAME"
BRANCH_NAME="${BRANCH_PREFIX}${SANITIZED_NAME}"

PORT_OFFSET=$(get_port_offset "$SANITIZED_NAME")
PORTS=()

if [ -n "$CONFIG_JSON" ]; then
    SERVICES_TMP=$(mktemp)
    register_temp "$SERVICES_TMP"
    if python3 - "$CONFIG_JSON" "$REPO_ROOT" >"$SERVICES_TMP" <<'PY'
import json
import os
import re
import sys

data = json.load(open(sys.argv[1], "r", encoding="utf-8"))
repo_root = os.path.abspath(sys.argv[2])
services = data.get("services") or []

if not isinstance(services, list):
    print("services must be a list", file=sys.stderr)
    sys.exit(2)

for svc in services:
    if not isinstance(svc, dict):
        print("each service must be a mapping", file=sys.stderr)
        sys.exit(2)
    name = svc.get("name")
    path = svc.get("path")
    base_port = svc.get("base_port")

    if not name or not path or base_port is None:
        print("service missing required fields (name, path, base_port)", file=sys.stderr)
        sys.exit(2)
    if not re.match(r"^[A-Za-z0-9_-]+$", str(name)):
        print(f"service name contains invalid characters: {name}", file=sys.stderr)
        sys.exit(2)
    if os.path.isabs(path):
        print(f"service path must be relative: {path}", file=sys.stderr)
        sys.exit(2)
    resolved = os.path.abspath(os.path.join(repo_root, path))
    if os.path.commonpath([resolved, repo_root]) != repo_root:
        print(f"service path escapes repo root: {path}", file=sys.stderr)
        sys.exit(2)

    try:
        base_port = int(base_port)
    except Exception:
        print(f"base_port must be an integer for {name}", file=sys.stderr)
        sys.exit(2)

    print(f"{name}\t{base_port}")
PY
    then
        while IFS=$'\t' read -r _ base_port; do
            [ -z "$base_port" ] && continue
            PORTS+=("$base_port")
        done < "$SERVICES_TMP"
    else
        warn "Failed to parse services from config"
    fi
fi

cleanup_ports() {
    local port="$1"
    if command -v lsof >/dev/null 2>&1; then
        local pids
        pids=$(lsof -ti "tcp:$port" -sTCP:LISTEN 2>/dev/null || true)
        if [ -n "$pids" ]; then
            echo "Stopping processes on port $port..."
            kill $pids 2>/dev/null || true
        fi
        return 0
    fi

    if command -v fuser >/dev/null 2>&1; then
        fuser -k "${port}/tcp" 2>/dev/null || true
        return 0
    fi

    return 1
}

PORT_CLEANED=false
if [ "${#PORTS[@]}" -gt 0 ]; then
    if [ "$KILL_PORTS" = true ]; then
        for base_port in "${PORTS[@]}"; do
            port=$((base_port + PORT_OFFSET))
            if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
                warn "Skipping invalid port: $port"
                continue
            fi
            if cleanup_ports "$port"; then
                PORT_CLEANED=true
            fi
        done
        if [ "$PORT_CLEANED" = false ]; then
            warn "Port cleanup skipped (missing lsof/fuser or config)"
        fi
    else
        warn "Port cleanup skipped (use --kill-ports to stop processes)"
    fi
else
    warn "No service ports found; skipping port cleanup"
fi

if [ "$CURRENT_DIR" != "$MAIN_REPO" ]; then
    echo ""
    warn "Process cleanup complete. Run full cleanup from main worktree:"
    echo "  ./.aix/scripts/worktree-cleanup.sh $SANITIZED_NAME"
    exit 0
fi

if [ ! -d "$WORKTREE_PATH" ]; then
    warn "Worktree directory not found: $WORKTREE_PATH"
else
    echo "Removing worktree at $WORKTREE_PATH..."

    if [ -d "$WORKTREE_PATH/.git" ] || [ -f "$WORKTREE_PATH/.git" ]; then
        UNCOMMITTED=$(cd "$WORKTREE_PATH" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        if [ "$UNCOMMITTED" -gt 0 ]; then
            warn "$UNCOMMITTED uncommitted changes in worktree"
            read -p "Continue anyway? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Aborted."
                exit 1
            fi
        fi
    fi

    PRE_CLEANUP=()
    if [ -n "$CONFIG_JSON" ]; then
        PRE_TMP=$(mktemp)
        register_temp "$PRE_TMP"
        if python3 - "$CONFIG_JSON" >"$PRE_TMP" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], "r", encoding="utf-8"))
pre_cleanup = data.get("pre_cleanup") or []

if not isinstance(pre_cleanup, list):
    print("pre_cleanup must be a list", file=sys.stderr)
    sys.exit(2)

for item in pre_cleanup:
    if isinstance(item, str) and item.strip():
        print(item)
PY
        then
            while IFS= read -r cmd; do
                [ -n "$cmd" ] && PRE_CLEANUP+=("$cmd")
            done < "$PRE_TMP"
        else
            warn "Failed to parse pre_cleanup commands"
        fi
    fi

    if [ "${#PRE_CLEANUP[@]}" -gt 0 ]; then
        echo "Running pre-cleanup commands..."
        for cmd in "${PRE_CLEANUP[@]}"; do
            echo "  $cmd"
            (cd "$WORKTREE_PATH" && bash -c "$cmd")
        done
    fi

    git worktree remove "$WORKTREE_PATH" --force
    info "✓ Worktree removed"
fi

if [ "$KEEP_BRANCH" = false ]; then
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        echo "Deleting branch $BRANCH_NAME..."
        git branch -D "$BRANCH_NAME"
        info "✓ Branch deleted"
    else
        warn "Branch $BRANCH_NAME not found (may have been merged/deleted)"
    fi
else
    warn "Keeping branch $BRANCH_NAME as requested"
fi

git worktree prune

echo ""
info "✅ Cleanup complete"
