#!/bin/bash
# Git worktree setup script
#
# Usage: ./.aix/scripts/worktree-setup.sh <feature-name>
#
# Creates a worktree for parallel development with isolated branch.

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
    echo "Usage: ./.aix/scripts/worktree-setup.sh <feature-name>"
    echo ""
    echo "Creates a git worktree for parallel development:"
    echo "  - Worktree at ../<feature-name> (default)"
    echo "  - Branch: feat/<feature-name> from origin/dev (or origin/main)"
    echo "  - If .aix/config/worktree.yaml exists, ports/env/symlinks are configured"
    echo ""
    echo "Examples:"
    echo "  ./.aix/scripts/worktree-setup.sh add-search"
    echo "  ./.aix/scripts/worktree-setup.sh fix-login-bug"
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

is_within_repo() {
    local path="$1"
    local repo_root="$2"
    python3 - "$path" "$repo_root" <<'PY'
import os
import sys

path = os.path.abspath(sys.argv[1])
repo_root = os.path.abspath(sys.argv[2])
try:
    common = os.path.commonpath([path, repo_root])
except ValueError:
    common = ""
print("true" if common == repo_root else "false")
PY
}

resolve_env_path() {
    local service_dir="$1"
    local env_file="$2"
    python3 - "$service_dir" "$env_file" <<'PY'
import os
import sys

service_dir = os.path.realpath(sys.argv[1])
env_file = sys.argv[2]
if os.path.isabs(env_file):
    target = os.path.realpath(env_file)
else:
    target = os.path.realpath(os.path.join(service_dir, env_file))

if os.path.commonpath([target, service_dir]) != service_dir:
    print("ERROR: env_file escapes service directory: " + env_file, file=sys.stderr)
    sys.exit(2)

print(target)
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

if [ -z "${1:-}" ]; then
    error "Feature name required"
    print_help
    exit 1
fi

FEATURE_NAME="$1"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    error "Not inside a git repository"
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
MAIN_REPO=$(git worktree list --porcelain | awk '/^worktree / {print $2; exit}')
CURRENT_DIR=$(pwd)
if [ "$CURRENT_DIR" != "$MAIN_REPO" ]; then
    error "Must run from main worktree"
    echo ""
    echo "You are in: $CURRENT_DIR"
    echo "Main repo:  $MAIN_REPO"
    exit 1
fi

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
PACKAGE_MANAGER=""
CONFIG_JSON=""
WORKTREE_ROOT_SET=false

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
                WORKTREE_ROOT_SET=true
                ;;
            branch_prefix)
                BRANCH_PREFIX="$value"
                ;;
            package_manager)
                PACKAGE_MANAGER="$value"
                ;;
        esac
    done < <(python3 - "$CONFIG_JSON" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], "r", encoding="utf-8"))
for key in ("worktree_root", "branch_prefix", "package_manager"):
    value = data.get(key)
    if value is None:
        continue
    if isinstance(value, bool):
        value = "true" if value else "false"
    print(f"{key}={value}")
PY
    )
fi

if [[ ! "$BRANCH_PREFIX" =~ ^[A-Za-z0-9._/-]+$ ]] || [[ "$BRANCH_PREFIX" == *".."* ]]; then
    error "Invalid branch_prefix: $BRANCH_PREFIX"
    exit 1
fi

WORKTREE_ROOT_ABS=$(resolve_path "$REPO_ROOT" "$WORKTREE_ROOT")
if [ -z "$WORKTREE_ROOT_ABS" ]; then
    error "Failed to resolve worktree_root"
    exit 1
fi

if [ "$WORKTREE_ROOT_SET" = false ]; then
    if [ "$(is_within_repo "$WORKTREE_ROOT_ABS" "$REPO_ROOT")" != "true" ]; then
        warn "worktree_root defaults outside repo; set worktree_root to acknowledge"
    fi
fi

WORKTREE_PATH="$WORKTREE_ROOT_ABS/$SANITIZED_NAME"
BRANCH_NAME="${BRANCH_PREFIX}${SANITIZED_NAME}"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VALIDATE_SCRIPT="$SCRIPT_DIR/worktree-validate.sh"

if [ -n "$CONFIG_PATH" ]; then
    if [ -f "$VALIDATE_SCRIPT" ]; then
        echo "Validating worktree config..."
        if ! bash "$VALIDATE_SCRIPT" "$SANITIZED_NAME"; then
            error "Worktree config validation failed"
            exit 1
        fi
    else
        warn "Worktree validate script not found: $VALIDATE_SCRIPT"
    fi
fi

if [ -d "$WORKTREE_PATH" ]; then
    error "Directory already exists: $WORKTREE_PATH"
    exit 1
fi

if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    error "Branch already exists: $BRANCH_NAME"
    echo "Delete it first with: git branch -D $BRANCH_NAME"
    exit 1
fi

git fetch origin
if git show-ref --verify --quiet "refs/remotes/origin/dev"; then
    BASE_BRANCH="origin/dev"
elif git show-ref --verify --quiet "refs/remotes/origin/main"; then
    BASE_BRANCH="origin/main"
else
    error "Neither origin/dev nor origin/main found"
    exit 1
fi

if [ ! -d "$WORKTREE_ROOT_ABS" ]; then
    mkdir -p "$WORKTREE_ROOT_ABS"
fi

echo "Creating worktree..."
echo "  Path: $WORKTREE_PATH"
echo "  Branch: $BRANCH_NAME"
echo "  Base: $BASE_BRANCH"
echo ""

git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "$BASE_BRANCH"

if [ -z "$CONFIG_PATH" ]; then
    echo ""
    info "✅ Worktree created successfully"
    echo ""
    echo "Next steps:"
    echo "  cd $WORKTREE_PATH"
    echo "  # Install dependencies (npm install, pip install, etc.)"
    echo "  # Start working on your feature"
    echo ""
    echo "When done:"
    echo "  # From main repo:"
    echo "  ./.aix/scripts/worktree-cleanup.sh $SANITIZED_NAME"
    exit 0
fi

PORT_OFFSET=$(get_port_offset "$SANITIZED_NAME")

SERVICE_NAMES=()
SERVICE_PATHS=()
SERVICE_PORT_ENVS=()
SERVICE_BASE_PORTS=()
SERVICE_ENV_FILES=()
SERVICE_ENV_REFS=()

SERVICES_TMP=$(mktemp)
register_temp "$SERVICES_TMP"
if ! python3 - "$CONFIG_JSON" "$REPO_ROOT" >"$SERVICES_TMP" <<'PY'
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
    port_env = svc.get("port_env")
    base_port = svc.get("base_port")
    env_file = svc.get("env_file") or ".env.local"
    env_refs = svc.get("env_refs") or {}

    if not name or not path or not port_env or base_port is None:
        print("service missing required fields (name, path, port_env, base_port)", file=sys.stderr)
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

    if env_refs is None:
        env_refs = {}
    if not isinstance(env_refs, dict):
        print(f"env_refs must be a mapping for {name}", file=sys.stderr)
        sys.exit(2)

    print(
        f"{name}\t{path}\t{port_env}\t{base_port}\t{env_file}\t"
        f"{json.dumps(env_refs, separators=(',', ':'))}"
    )
PY
then
    error "Failed to parse services from config"
    exit 1
fi

while IFS=$'\t' read -r name path port_env base_port env_file env_refs; do
    SERVICE_NAMES+=("$name")
    SERVICE_PATHS+=("$path")
    SERVICE_PORT_ENVS+=("$port_env")
    SERVICE_BASE_PORTS+=("$base_port")
    SERVICE_ENV_FILES+=("$env_file")
    SERVICE_ENV_REFS+=("$env_refs")
done < "$SERVICES_TMP"

declare -A SERVICE_PORTS
declare -A PORT_SEEN
for idx in "${!SERVICE_NAMES[@]}"; do
    base_port="${SERVICE_BASE_PORTS[$idx]}"
    port=$((base_port + PORT_OFFSET))
    if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        error "Port out of range for ${SERVICE_NAMES[$idx]}: $port"
        exit 1
    fi
    if [ -n "${PORT_SEEN[$port]:-}" ]; then
        error "Port collision detected: $port used by ${PORT_SEEN[$port]} and ${SERVICE_NAMES[$idx]}"
        exit 1
    fi
    PORT_SEEN["$port"]="${SERVICE_NAMES[$idx]}"
    SERVICE_PORTS["${SERVICE_NAMES[$idx]}"]="$port"
done

declare -A SERVICE_ENV_RELPATHS
for idx in "${!SERVICE_NAMES[@]}"; do
    service_name="${SERVICE_NAMES[$idx]}"
    service_path="${SERVICE_PATHS[$idx]}"
    env_file="${SERVICE_ENV_FILES[$idx]}"

    if ! env_relpath=$(python3 - "$REPO_ROOT" "$service_path" "$env_file" <<'PY'
import os
import sys

repo_root = os.path.realpath(sys.argv[1])
service_path = sys.argv[2]
env_file = sys.argv[3]

service_dir = os.path.realpath(os.path.join(repo_root, service_path))

if os.path.isabs(env_file):
    target = os.path.realpath(env_file)
else:
    target = os.path.realpath(os.path.join(service_dir, env_file))

if os.path.commonpath([target, service_dir]) != service_dir:
    print("ERROR: env_file escapes service directory: " + env_file, file=sys.stderr)
    sys.exit(2)

print(os.path.relpath(target, repo_root))
PY
    ); then
        error "Invalid env_file for $service_name"
        exit 1
    fi
    SERVICE_ENV_RELPATHS["$service_name"]="$env_relpath"
done

SYMLINK_TMP=$(mktemp)
register_temp "$SYMLINK_TMP"
declare -A ENV_SEED_SOURCES
if python3 - "$CONFIG_JSON" "$REPO_ROOT" >"$SYMLINK_TMP" <<'PY'
import glob
import json
import os
import sys

data = json.load(open(sys.argv[1], "r", encoding="utf-8"))
repo_root = os.path.abspath(sys.argv[2])
repo_real = os.path.realpath(repo_root)
symlinks = data.get("symlinks") or []
services = data.get("services") or []

if not isinstance(symlinks, list):
    print("symlinks must be a list", file=sys.stderr)
    sys.exit(2)

env_targets = set()
if isinstance(services, list):
    for svc in services:
        if not isinstance(svc, dict):
            continue
        path = svc.get("path")
        if not path:
            continue
        env_file = svc.get("env_file") or ".env.local"
        if os.path.isabs(path):
            continue
        service_dir = os.path.realpath(os.path.join(repo_root, path))
        try:
            if os.path.commonpath([service_dir, repo_real]) != repo_real:
                continue
        except ValueError:
            continue
        if os.path.isabs(env_file):
            target = os.path.realpath(env_file)
        else:
            target = os.path.realpath(os.path.join(service_dir, env_file))
        try:
            if os.path.commonpath([target, service_dir]) != service_dir:
                continue
        except ValueError:
            continue
        env_targets.add(os.path.relpath(target, repo_root))

def emit(source_path: str, target_path: str) -> None:
    source_real = os.path.realpath(source_path)
    target_real = os.path.realpath(target_path)
    if os.path.commonpath([target_real, repo_real]) != repo_real:
        print(f"Warning: target outside repo: {target_path}", file=sys.stderr)
        return
    rel = os.path.relpath(target_real, repo_root)
    is_env_target = rel in env_targets
    if os.path.commonpath([source_real, repo_real]) != repo_real:
        if is_env_target:
            print(f"Warning: env seed source outside repo: {source_path}", file=sys.stderr)
        else:
            print(f"Warning: skipping symlink outside repo: {source_path}", file=sys.stderr)
            return
    if is_env_target:
        print(f"{source_real}\t{rel}\tseed")
    else:
        print(f"{source_real}\t{rel}\tlink")

for entry in symlinks:
    if isinstance(entry, str):
        matches = glob.glob(os.path.join(repo_root, entry))
        if not matches:
            print(f"Warning: symlink source not found for pattern: {entry}", file=sys.stderr)
            continue
        for match in matches:
            emit(match, match)
        continue

    if isinstance(entry, dict):
        source = entry.get("source")
        target = entry.get("target")
        if not source or not target:
            print("symlink mapping requires source and target", file=sys.stderr)
            sys.exit(2)
        source_path = source if os.path.isabs(source) else os.path.join(repo_root, source)
        target_path = target if os.path.isabs(target) else os.path.join(repo_root, target)
        if not os.path.exists(source_path):
            print(f"Warning: symlink source not found: {source}", file=sys.stderr)
            continue
        emit(source_path, target_path)
        continue

    print("symlink entries must be strings or mappings", file=sys.stderr)
    sys.exit(2)
PY
then
    while IFS=$'\t' read -r source relpath mode; do
        [ -z "$source" ] && continue
        if [ "$mode" = "seed" ]; then
            if [ -n "${ENV_SEED_SOURCES[$relpath]:-}" ] && [ "${ENV_SEED_SOURCES[$relpath]}" != "$source" ]; then
                warn "Multiple env seed sources for $relpath; using first"
                continue
            fi
            ENV_SEED_SOURCES["$relpath"]="$source"
            continue
        fi
        dest="$WORKTREE_PATH/$relpath"
        if [ -e "$dest" ] && [ ! -L "$dest" ]; then
            warn "Skipping symlink, destination exists: $dest"
            continue
        fi
        mkdir -p "$(dirname "$dest")"
        if [ -L "$dest" ]; then
            rm -f "$dest"
        fi
        ln -s "$source" "$dest"
    done < "$SYMLINK_TMP"
else
    warn "Symlink setup skipped due to config errors"
fi

for idx in "${!SERVICE_NAMES[@]}"; do
    service_name="${SERVICE_NAMES[$idx]}"
    service_path="${SERVICE_PATHS[$idx]}"
    port_env="${SERVICE_PORT_ENVS[$idx]}"
    env_file="${SERVICE_ENV_FILES[$idx]}"
    env_refs_json="${SERVICE_ENV_REFS[$idx]}"
    port="${SERVICE_PORTS[$service_name]}"

    service_dir="$WORKTREE_PATH/$service_path"
    if [ ! -d "$service_dir" ]; then
        warn "Service directory not found: $service_dir"
        continue
    fi

    if ! env_path=$(resolve_env_path "$service_dir" "$env_file"); then
        error "Invalid env_file for $service_name"
        exit 1
    fi

    if [ -L "$env_path" ]; then
        warn "Env file is a symlink, skipping: $env_path"
        continue
    fi

    if [ -e "$env_path" ]; then
        warn "Env file exists, skipping: $env_path"
        continue
    fi

    env_relpath="${SERVICE_ENV_RELPATHS[$service_name]:-}"
    seed_source="${ENV_SEED_SOURCES[$env_relpath]:-}"
    seed_content=""
    if [ -n "$seed_source" ]; then
        if [ -f "$seed_source" ]; then
            seed_content=$(cat "$seed_source" 2>/dev/null || true)
        else
            warn "Env seed source not found: $seed_source"
        fi
    fi

    mkdir -p "$(dirname "$env_path")"

    {
        if [ -n "$seed_content" ]; then
            printf "%s\n" "$seed_content"
            case "$seed_content" in
                *$'\n') ;;
                *) printf "\n" ;;
            esac
        fi
        printf "%s=%s\n" "$port_env" "$port"

        if [ -n "$env_refs_json" ] && [ "$env_refs_json" != "null" ]; then
            while IFS=$'\t' read -r key value; do
                for ref in "${!SERVICE_PORTS[@]}"; do
                    placeholder="{{${ref}.port}}"
                    value="${value//${placeholder}/${SERVICE_PORTS[$ref]}}"
                done
                if [[ "$value" == *"{{"*"}}"* ]]; then
                    error "Unresolved env_refs for $service_name: $key"
                    exit 1
                fi
                printf "%s=%s\n" "$key" "$value"
            done < <(python3 - "$env_refs_json" <<'PY'
import json
import sys

env_refs = json.loads(sys.argv[1]) if sys.argv[1] else {}
if not isinstance(env_refs, dict):
    sys.exit(0)

for key, value in env_refs.items():
    print(f"{key}\t{value}")
PY
            )
        fi
    } > "$env_path"
done

POST_SETUP=()
POST_TMP=$(mktemp)
register_temp "$POST_TMP"
if python3 - "$CONFIG_JSON" >"$POST_TMP" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], "r", encoding="utf-8"))
post_setup = data.get("post_setup") or []

if not isinstance(post_setup, list):
    print("post_setup must be a list", file=sys.stderr)
    sys.exit(2)

for item in post_setup:
    if isinstance(item, str) and item.strip():
        print(item)
PY
then
    while IFS= read -r cmd; do
        [ -n "$cmd" ] && POST_SETUP+=("$cmd")
    done < "$POST_TMP"
else
    warn "Failed to parse post_setup commands"
fi

if [ "${#POST_SETUP[@]}" -gt 0 ]; then
    echo ""
    echo "Running post-setup commands..."
    for cmd in "${POST_SETUP[@]}"; do
        echo "  $cmd"
        (cd "$WORKTREE_PATH" && bash -c "$cmd")
    done
fi

if [ -z "$PACKAGE_MANAGER" ] || [ "$PACKAGE_MANAGER" = "auto" ]; then
    PACKAGE_MANAGER=""
fi

if [ "${#SERVICE_NAMES[@]}" -gt 0 ]; then
    echo ""
    echo "Detected services:"
    for idx in "${!SERVICE_NAMES[@]}"; do
        service_name="${SERVICE_NAMES[$idx]}"
        service_path="${SERVICE_PATHS[$idx]}"
        service_dir="$WORKTREE_PATH/$service_path"
        detected=""

        if [ -n "$PACKAGE_MANAGER" ] && [ "$PACKAGE_MANAGER" != "none" ]; then
            detected="$PACKAGE_MANAGER"
        else
            if [ -f "$service_dir/bun.lockb" ]; then
                detected="bun"
            elif [ -f "$service_dir/pnpm-lock.yaml" ]; then
                detected="pnpm"
            elif [ -f "$service_dir/yarn.lock" ]; then
                detected="yarn"
            elif [ -f "$service_dir/package-lock.json" ]; then
                detected="npm"
            else
                detected="none"
            fi
        fi

        echo "  - $service_name ($service_path): $detected"
    done
fi

echo ""
info "✅ Worktree created successfully"
echo ""
echo "Next steps:"
echo "  cd $WORKTREE_PATH"
echo "  # Install dependencies for each service"
echo "  # Start working on your feature"
echo ""
echo "When done:"
echo "  # From main repo:"
echo "  ./.aix/scripts/worktree-cleanup.sh $SANITIZED_NAME"
