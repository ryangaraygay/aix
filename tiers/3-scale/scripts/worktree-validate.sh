#!/bin/bash
# Worktree config validation script
#
# Usage: ./.aix/scripts/worktree-validate.sh <feature-name> [--allow-missing-config]

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
    echo "Usage: ./.aix/scripts/worktree-validate.sh <feature-name> [--allow-missing-config]"
    echo ""
    echo "Validates worktree config and port allocation for a feature."
    echo ""
    echo "Options:"
    echo "  --allow-missing-config   Exit successfully when config is missing"
}

ALLOW_MISSING=false
FEATURE_NAME=""

for arg in "$@"; do
    case $arg in
        --allow-missing-config)
            ALLOW_MISSING=true
            ;;
        -h|--help)
            print_help
            exit 0
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
CONFIG_PATH=""

if [ -f "$REPO_ROOT/.aix/config/worktree.yaml" ]; then
    CONFIG_PATH="$REPO_ROOT/.aix/config/worktree.yaml"
elif [ -f "$REPO_ROOT/.aix/worktree.yaml" ]; then
    CONFIG_PATH="$REPO_ROOT/.aix/worktree.yaml"
fi

if [ -z "$CONFIG_PATH" ]; then
    if [ "$ALLOW_MISSING" = true ]; then
        warn "No worktree config found; skipping validation"
        exit 0
    fi
    error "Missing worktree config (.aix/config/worktree.yaml)"
    exit 1
fi

SCHEMA_PATH=""
if [ -f "$REPO_ROOT/.aix/config/worktree.schema.json" ]; then
    SCHEMA_PATH="$REPO_ROOT/.aix/config/worktree.schema.json"
elif [ -f "$REPO_ROOT/.aix/worktree.schema.json" ]; then
    SCHEMA_PATH="$REPO_ROOT/.aix/worktree.schema.json"
fi

if ! command -v python3 >/dev/null 2>&1; then
    error "python3 is required for validation"
    exit 1
fi

if ! python3 - "$CONFIG_PATH" "$SCHEMA_PATH" "$REPO_ROOT" "$FEATURE_NAME" <<'PY'
import json
import os
import re
import sys
from glob import glob

config_path = sys.argv[1]
schema_path = sys.argv[2]
repo_root = os.path.abspath(sys.argv[3])
feature_name = sys.argv[4]

try:
    import yaml
except Exception as exc:
    print("Missing PyYAML; install with: python3 -m pip install pyyaml", file=sys.stderr)
    print(str(exc), file=sys.stderr)
    sys.exit(2)

errors = []
warnings = []

def add_error(msg: str) -> None:
    errors.append(msg)

def add_warning(msg: str) -> None:
    warnings.append(msg)

with open(config_path, "r", encoding="utf-8") as handle:
    data = yaml.safe_load(handle) or {}

if schema_path and os.path.exists(schema_path):
    try:
        import jsonschema
    except Exception:
        add_warning("jsonschema not installed; skipping schema validation")
    else:
        with open(schema_path, "r", encoding="utf-8") as handle:
            schema = json.load(handle)
        try:
            jsonschema.validate(instance=data, schema=schema)
        except jsonschema.ValidationError as exc:
            location = ".".join(str(part) for part in exc.absolute_path)
            if location:
                add_error(f"Schema validation failed at {location}: {exc.message}")
            else:
                add_error(f"Schema validation failed: {exc.message}")

branch_prefix = data.get("branch_prefix")
if branch_prefix is not None:
    if not isinstance(branch_prefix, str):
        add_error("branch_prefix must be a string")
    elif not re.match(r"^[A-Za-z0-9._/-]+$", branch_prefix) or ".." in branch_prefix:
        add_error(f"Invalid branch_prefix: {branch_prefix}")

def port_offset(name: str) -> int:
    h = 2166136261
    for ch in name:
        h &= 0x7FFFFFFF
        h = (h ^ ord(ch)) * 16777619
        h &= 0x7FFFFFFF
    slot = (h & 0x7FFFFFFF) % 100
    return slot * 10

services = data.get("services") or []
if not isinstance(services, list):
    add_error("services must be a list")
    services = []

service_names = set()
ports = {}
offset = port_offset(feature_name)

for svc in services:
    if not isinstance(svc, dict):
        add_error("each service must be a mapping")
        continue
    name = svc.get("name")
    path = svc.get("path")
    port_env = svc.get("port_env")
    base_port = svc.get("base_port")
    env_file = svc.get("env_file") or ".env.local"
    env_refs = svc.get("env_refs") or {}

    if not name or not path or not port_env or base_port is None:
        add_error("service missing required fields (name, path, port_env, base_port)")
        continue

    if not re.match(r"^[A-Za-z0-9_-]+$", str(name)):
        add_error(f"service name contains invalid characters: {name}")
        continue

    if os.path.isabs(path):
        add_error(f"service path must be relative: {path}")
        continue

    resolved = os.path.abspath(os.path.join(repo_root, path))
    if os.path.commonpath([resolved, repo_root]) != repo_root:
        add_error(f"service path escapes repo root: {path}")
        continue

    try:
        base_port = int(base_port)
    except Exception:
        add_error(f"base_port must be an integer for {name}")
        continue

    port = base_port + offset
    if port < 1 or port > 65535:
        add_error(f"port out of range for {name}: {port}")
    if port in ports.values():
        add_error(f"port collision detected: {port}")
    ports[name] = port

    service_real = os.path.realpath(resolved)
    if os.path.isabs(env_file):
        env_path = os.path.realpath(env_file)
    else:
        env_path = os.path.realpath(os.path.join(service_real, env_file))
    if os.path.commonpath([env_path, service_real]) != service_real:
        add_error(f"env_file escapes service directory for {name}: {env_file}")

    if env_refs is None:
        env_refs = {}
    if not isinstance(env_refs, dict):
        add_error(f"env_refs must be a mapping for {name}")
        env_refs = {}

    for key, value in env_refs.items():
        if not isinstance(value, str):
            add_error(f"env_refs value must be string for {name}.{key}")
            continue
        for match in re.findall(r"\{\{([A-Za-z0-9_-]+)\.port\}\}", value):
            if match not in ports and match not in service_names and match not in {s.get("name") for s in services if isinstance(s, dict)}:
                add_error(f"env_refs for {name} references unknown service: {match}")

    service_names.add(str(name))

symlinks = data.get("symlinks") or []
if symlinks and not isinstance(symlinks, list):
    add_error("symlinks must be a list")
    symlinks = []

repo_real = os.path.realpath(repo_root)
for entry in symlinks:
    if isinstance(entry, str):
        matches = glob(os.path.join(repo_root, entry))
        if not matches:
            add_warning(f"symlink source not found for pattern: {entry}")
            continue
        for match in matches:
            real = os.path.realpath(match)
            if os.path.commonpath([real, repo_real]) != repo_real:
                add_warning(f"symlink target outside repo: {match}")
        continue

    if isinstance(entry, dict):
        source = entry.get("source")
        target = entry.get("target")
        if not source or not target:
            add_error("symlink mapping requires source and target")
            continue
        source_path = source if os.path.isabs(source) else os.path.join(repo_root, source)
        target_path = target if os.path.isabs(target) else os.path.join(repo_root, target)
        source_real = os.path.realpath(source_path)
        target_real = os.path.realpath(target_path)
        if os.path.commonpath([target_real, repo_real]) != repo_real:
            add_warning(f"symlink target outside repo: {target}")
        if os.path.commonpath([source_real, repo_real]) != repo_real:
            add_warning(f"symlink source outside repo: {source}")
        if not os.path.exists(source_path):
            add_warning(f"symlink source not found: {source}")
        continue

    add_error("symlink entries must be strings or mappings")

for warning in warnings:
    print(f"Warning: {warning}")

if errors:
    for err in errors:
        print(f"Error: {err}", file=sys.stderr)
    sys.exit(1)

print("Validation passed.")
PY
then
    info "Validation complete"
else
    exit 1
fi
