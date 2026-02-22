#!/usr/bin/env python3
"""
Generate tool-specific configurations from canonical AIX role definitions.

This script reads canonical role files from .aix/roles/ and generates
adapter-specific agent configurations for supported coding assistants.

Usage:
    python3 .aix/scripts/aix-generate.py --adapter claude
    python3 .aix/scripts/aix-generate.py --adapter opencode --model-set codex-5.3
    python3 .aix/scripts/aix-generate.py --adapter factory --model-set speed
    python3 .aix/scripts/aix-generate.py --adapter agentskills
    python3 .aix/scripts/aix-generate.py --all
    python3 .aix/scripts/aix-generate.py --adapter claude --dry-run
    python3 .aix/scripts/aix-generate.py --adapter claude --force
"""

import argparse
import hashlib
import json
import os
import re
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

try:
    import yaml
except ImportError:
    print("Error: PyYAML is required. Install with: pip install pyyaml")
    exit(1)


def _git_root() -> Path:
    """Get git repository root directory."""
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        return Path(result.stdout.strip())
    return Path.cwd()


def _sha256(content: str) -> str:
    """Compute SHA-256 hash of string content."""
    return hashlib.sha256(content.encode()).hexdigest()


def _sha256_file(path: Path) -> str:
    """Compute SHA-256 hash of file content."""
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(8192), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_adapter_config(adapter_path: Path) -> Dict[str, Any]:
    """
    Load adapter configuration from adapter.yaml.

    Args:
        adapter_path: Path to adapter directory

    Returns:
        Dict with adapter config

    Raises:
        FileNotFoundError: If adapter.yaml doesn't exist
        ValueError: If config is invalid
    """
    config_path = adapter_path / "adapter.yaml"
    if not config_path.exists():
        raise FileNotFoundError(f"Adapter config not found: {config_path}")

    config = yaml.safe_load(config_path.read_text())

    # Validate required fields
    required = ["adapter", "version"]
    for field in required:
        if field not in config:
            raise ValueError(f"Missing required field in adapter config: {field}")

    return config


def load_model_set(adapter_path: Path, model_set_name: str) -> Dict[str, Any]:
    """
    Load model set configuration from adapter's model-sets directory.

    Args:
        adapter_path: Path to adapter directory
        model_set_name: Name of model set to load

    Returns:
        Dict with model set config

    Raises:
        FileNotFoundError: If model set doesn't exist
    """
    model_set_path = adapter_path / "model-sets" / f"{model_set_name}.yaml"
    if not model_set_path.exists():
        raise FileNotFoundError(f"Model set not found: {model_set_path}")

    return yaml.safe_load(model_set_path.read_text())


def resolve_model_for_role(role_name: str, model_set: Dict[str, Any]) -> Dict[str, Any]:
    """
    Resolve model configuration for a role from model set.

    Args:
        role_name: Name of the role (e.g., 'analyst', 'coder')
        model_set: Model set configuration dict

    Returns:
        Dict with 'model' key and optional 'reasoningEffort' key
        Returns empty dict if role not found in model set
    """
    roles = model_set.get("roles", {})
    role_config = roles.get(role_name)

    if role_config is None:
        return {}

    # Handle simple string format: "role: opus"
    if isinstance(role_config, str):
        return {"model": role_config}

    # Handle object format: "role: {model: opus, reasoningEffort: high}"
    if isinstance(role_config, dict):
        result = {}
        if "model" in role_config:
            result["model"] = role_config["model"]
        if "reasoningEffort" in role_config:
            result["reasoningEffort"] = role_config["reasoningEffort"]
        return result

    return {}


def parse_role_file(role_path: Path) -> Tuple[Dict[str, Any], str]:
    """
    Parse role markdown file to extract YAML frontmatter and body.

    Args:
        role_path: Path to role markdown file

    Returns:
        Tuple of (frontmatter_dict, body_content)

    Raises:
        ValueError: If file format is invalid
    """
    content = role_path.read_text()

    # Match YAML frontmatter between --- markers (with optional leading HTML comments)
    pattern = r'^(?:<!--.*?-->\s*\n)*---\s*\n(.*?)\n---\s*\n(.*)$'
    match = re.match(pattern, content, re.DOTALL)

    if not match:
        raise ValueError(f"Invalid role file format (missing frontmatter): {role_path}")

    frontmatter_str = match.group(1)
    body = match.group(2)

    try:
        frontmatter = yaml.safe_load(frontmatter_str)
        if frontmatter is None:
            frontmatter = {}
    except yaml.YAMLError as e:
        raise ValueError(f"Invalid YAML frontmatter in {role_path}: {e}")

    return frontmatter, body


def map_tool_names(tools: List[str], adapter_config: Dict[str, Any]) -> List[str]:
    """
    Map canonical AIX tool names to adapter-specific tool names.

    Args:
        tools: List of canonical tool names (e.g., ['Read', 'Write'])
        adapter_config: Adapter configuration dict

    Returns:
        List of adapter-specific tool names
    """
    tool_mapping = adapter_config.get("tools", {})
    return [tool_mapping.get(tool, tool) for tool in tools]


def generate_output_file(
    role_name: str,
    frontmatter: Dict[str, Any],
    body: str,
    adapter_config: Dict[str, Any],
    model_config: Dict[str, Any],
    model_set_name: str,
) -> str:
    """
    Generate output file content for a role.

    Args:
        role_name: Name of the role
        frontmatter: Role frontmatter dict
        body: Role body content
        adapter_config: Adapter configuration
        model_config: Model configuration for this role
        model_set_name: Name of model set being used

    Returns:
        Complete output file content as string
    """
    # Build new frontmatter (no header comments - they break frontmatter detection)
    new_frontmatter = {}

    # Add name and description if present
    if "name" in frontmatter:
        new_frontmatter["name"] = frontmatter["name"]
    if "description" in frontmatter:
        new_frontmatter["description"] = frontmatter["description"]

    # Add model from model set
    if "model" in model_config:
        new_frontmatter["model"] = model_config["model"]

    # Add reasoningEffort if present
    if "reasoningEffort" in model_config:
        new_frontmatter["reasoningEffort"] = model_config["reasoningEffort"]

    # Map and add tools (handle both 'tools' and 'allowed_tools' from source)
    # Get adapter name for format-specific handling
    adapter_name = adapter_config.get("adapter", "")

    # Add mode for OpenCode (required field)
    if adapter_name == "opencode":
        new_frontmatter["mode"] = "subagent"

    # Map and add tools (format varies by adapter)
    tools = frontmatter.get("tools") or frontmatter.get("allowed_tools")
    if tools and isinstance(tools, list):
        mapped_tools = map_tool_names(tools, adapter_config)

        if adapter_name == "opencode":
            # OpenCode uses object format with boolean values: {read: true, write: true}
            new_frontmatter["tools"] = {tool: True for tool in mapped_tools}
        else:
            # Claude and others use array format: [Read, Write, Bash]
            new_frontmatter["tools"] = mapped_tools

    # Convert frontmatter to YAML with flow style for tools list
    # Use custom representer to output short lists in flow style
    class FlowStyleDumper(yaml.SafeDumper):
        pass

    def represent_list(dumper, data):
        # Use flow style for short lists (like tools)
        if len(data) <= 10 and all(isinstance(item, str) for item in data):
            return dumper.represent_sequence('tag:yaml.org,2002:seq', data, flow_style=True)
        return dumper.represent_sequence('tag:yaml.org,2002:seq', data, flow_style=False)

    FlowStyleDumper.add_representer(list, represent_list)

    frontmatter_yaml = yaml.dump(new_frontmatter, Dumper=FlowStyleDumper, sort_keys=False, width=float("inf"))

    # Combine into final output
    output = "---\n" + frontmatter_yaml + "---\n\n" + body.strip() + "\n"

    return output


def replace_tool_names_in_body(body: str, adapter_config: Dict[str, Any]) -> str:
    """
    Replace canonical AIX tool names with adapter-specific names in body text.

    Replaces backtick-wrapped tool references (e.g., `Read` -> `fs_read`).

    Args:
        body: Role body content
        adapter_config: Adapter configuration dict

    Returns:
        Body with tool names replaced
    """
    tool_mapping = adapter_config.get("tools", {})
    for canonical, native in tool_mapping.items():
        if canonical != native:
            body = body.replace(f"`{canonical}`", f"`{native}`")
    return body


def generate_json_agent(
    role_name: str,
    frontmatter: Dict[str, Any],
    body: str,
    adapter_config: Dict[str, Any],
    model_config: Dict[str, Any],
    model_set_name: str,
) -> str:
    """
    Generate Kiro CLI JSON agent config from a role definition.

    Args:
        role_name: Name of the role
        frontmatter: Role frontmatter dict
        body: Role body content
        adapter_config: Adapter configuration
        model_config: Model configuration for this role
        model_set_name: Name of model set being used

    Returns:
        JSON string of the agent config
    """
    # Map tools from frontmatter
    tools = frontmatter.get("tools") or frontmatter.get("allowed_tools") or []
    if isinstance(tools, list):
        mapped_tools = map_tool_names(tools, adapter_config)
        # Deduplicate (e.g., Write and Edit both map to fs_write)
        seen = set()
        deduped = []
        for t in mapped_tools:
            if t not in seen:
                seen.add(t)
                deduped.append(t)
        mapped_tools = deduped
    else:
        mapped_tools = ["*"]

    # Replace tool names in the body text
    prompt = replace_tool_names_in_body(body.strip(), adapter_config)

    # Resolve model (None means use kiro default)
    model = model_config.get("model") if model_config else None

    # Build agent JSON
    agent = {
        "name": role_name,
        "description": frontmatter.get("description", "").strip() if frontmatter.get("description") else "",
        "prompt": prompt,
        "mcpServers": {},
        "tools": mapped_tools,
        "toolAliases": {},
        "allowedTools": mapped_tools,
        "resources": [],
        "hooks": {},
        "toolsSettings": {},
        "model": model,
    }

    return json.dumps(agent, indent=2, ensure_ascii=False) + "\n"


def create_skills_symlink(output_dir: Path, skills_source: Path) -> None:
    """
    Create symlink from output skills directory to canonical skills directory.

    Args:
        output_dir: Directory where symlink should be created
        skills_source: Canonical skills directory (.aix/skills)
    """
    # Compute relative path from output_dir to skills_source
    try:
        rel_path = os.path.relpath(skills_source, output_dir.parent)
    except ValueError:
        # On Windows, relpath can fail if paths are on different drives
        rel_path = str(skills_source)

    # Remove existing symlink/directory if present
    if output_dir.exists() or output_dir.is_symlink():
        if output_dir.is_symlink():
            output_dir.unlink()
        elif output_dir.is_dir() and not any(output_dir.iterdir()):
            output_dir.rmdir()

    # Create parent directory if needed
    output_dir.parent.mkdir(parents=True, exist_ok=True)

    # Create symlink
    output_dir.symlink_to(rel_path)


def compute_content_hash(content: str) -> str:
    """
    Compute SHA-256 hash of content.

    Args:
        content: String content to hash

    Returns:
        Hex string of SHA-256 hash
    """
    return _sha256(content)


def load_manifest(manifest_path: Path) -> Dict[str, Any]:
    """Load manifest.json file."""
    if not manifest_path.exists():
        return {
            "manifest_version": 1,
            "files": [],
            "generated": {}
        }
    return json.loads(manifest_path.read_text())


def update_manifest(
    manifest_path: Path,
    adapter_name: str,
    generation_info: Dict[str, Any]
) -> None:
    """
    Update manifest.json with generation metadata.

    Args:
        manifest_path: Path to manifest.json
        adapter_name: Name of adapter that was generated
        generation_info: Dict with generation metadata
    """
    manifest = load_manifest(manifest_path)

    # Initialize generated section if not present
    if "generated" not in manifest:
        manifest["generated"] = {}

    # Update adapter entry
    manifest["generated"][adapter_name] = generation_info

    # Write back to file
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")


def get_enabled_adapters(repo_root: Path) -> Dict[str, Optional[str]]:
    """
    Get list of enabled adapters and their model sets from tier.yaml.

    Returns:
        Dict mapping adapter name to model set name
        Empty dict if tier.yaml doesn't exist or has no adapters section
    """
    tier_path = repo_root / ".aix" / "tier.yaml"
    if not tier_path.exists():
        return {}

    # Simple YAML parsing for tier.yaml
    content = tier_path.read_text()
    adapters: Dict[str, Optional[str]] = {}
    in_adapters = False
    adapter_name: Optional[str] = None

    for line in content.splitlines():
        line = line.rstrip()

        if line.startswith("adapters:"):
            in_adapters = True
            continue

        if in_adapters:
            # End of adapters section
            if line and not line.startswith(" "):
                break

            # Parse adapter entry: "  claude:"
            if line.strip().endswith(":") and not line.strip().startswith("#"):
                adapter_name = line.strip()[:-1]
                adapters[adapter_name] = None
                continue

            # Parse enabled field: "    enabled: true"
            if "enabled:" in line:
                parts = line.split("enabled:")
                if len(parts) == 2:
                    enabled = parts[1].strip().lower() == "true"
                    # If disabled, remove from dict
                    if not enabled and adapter_name and adapter_name in adapters:
                        del adapters[adapter_name]

            # Parse model_set field: "    model_set: default"
            if "model_set:" in line:
                parts = line.split("model_set:")
                if len(parts) == 2 and adapter_name and adapter_name in adapters:
                    adapters[adapter_name] = parts[1].strip()

    return adapters


def generate_adapter(
    repo_root: Path,
    adapter_name: str,
    model_set_name: Optional[str] = None,
    dry_run: bool = False,
    force: bool = False,
) -> Dict[str, Any]:
    """
    Generate configurations for a specific adapter.

    Args:
        repo_root: Repository root path
        adapter_name: Name of adapter to generate
        model_set_name: Optional model set override
        dry_run: If True, don't write files
        force: If True, regenerate even if unchanged

    Returns:
        Dict with generation report
    """
    aix_dir = repo_root / ".aix"
    adapter_path = aix_dir / "adapters" / adapter_name
    roles_dir = aix_dir / "roles"
    manifest_path = aix_dir / "manifest.json"

    # Load adapter config
    try:
        adapter_config = load_adapter_config(adapter_path)
    except (FileNotFoundError, ValueError) as e:
        return {
            "adapter": adapter_name,
            "status": "error",
            "error": str(e),
        }

    # Determine model set to use
    if model_set_name is None:
        # Use default from adapter config (if one is configured)
        model_sets_config = adapter_config.get("model_sets", {})
        if model_sets_config.get("enabled"):
            default_set = model_sets_config.get("default")
            if default_set:
                model_set_name = default_set

    # Load model set (if adapter uses model sets and a set is specified)
    model_set = None
    model_set_hash = None
    if adapter_config.get("model_sets", {}).get("enabled") and model_set_name:
        try:
            model_set = load_model_set(adapter_path, model_set_name)
            model_set_file = adapter_path / "model-sets" / f"{model_set_name}.yaml"
            model_set_hash = _sha256_file(model_set_file)
        except FileNotFoundError as e:
            return {
                "adapter": adapter_name,
                "status": "error",
                "error": str(e),
            }

    # Get output directories from adapter config
    output_config = adapter_config.get("output", {})

    # Setup skills symlink if configured
    skills_config = adapter_config.get("skills", {})
    if skills_config.get("strategy") == "symlink":
        skills_output_key = "skills"
        if skills_output_key in output_config:
            skills_output = repo_root / output_config[skills_output_key]
            skills_source = aix_dir / "skills"

            if not dry_run:
                create_skills_symlink(skills_output, skills_source)

    # If adapter has roles disabled (skills-only), skip role generation
    if not adapter_config.get("roles", {}).get("enabled", True):
        generation_info = {
            "last_generated": datetime.utcnow().isoformat() + "Z",
            "skills_symlink": str(output_config.get("skills", "")),
            "adapter_config_hash": _sha256_file(adapter_path / "adapter.yaml"),
        }

        if not dry_run:
            update_manifest(manifest_path, adapter_name, generation_info)

        return {
            "adapter": adapter_name,
            "status": "success",
            "model_set": None,
            "roles_generated": 0,
            "skills_symlink_created": True,
            "dry_run": dry_run,
        }

    # Get output directory for agents/droids
    agent_output_key = None
    for key in ["agents", "droids", "agent"]:
        if key in output_config:
            agent_output_key = key
            break

    if agent_output_key is None:
        return {
            "adapter": adapter_name,
            "status": "error",
            "error": "No agent output directory configured",
        }

    output_dir = repo_root / output_config[agent_output_key]

    # Find all role files
    role_files = [f for f in roles_dir.glob("*.md") if f.name != "_index.md"]

    # Generate output for each role
    generated_files = []
    skipped_files = []

    for role_file in role_files:
        role_name = role_file.stem

        # Parse role file
        try:
            frontmatter, body = parse_role_file(role_file)
        except ValueError as e:
            continue  # Skip invalid role files

        # Resolve model for this role
        model_config = {}
        if model_set:
            model_config = resolve_model_for_role(role_name, model_set)

        # Generate output content (JSON for kiro, markdown for others)
        role_format = adapter_config.get("roles", {}).get("format", "markdown")
        if role_format == "json":
            output_content = generate_json_agent(
                role_name,
                frontmatter,
                body,
                adapter_config,
                model_config,
                model_set_name or "default",
            )
        else:
            output_content = generate_output_file(
                role_name,
                frontmatter,
                body,
                adapter_config,
                model_config,
                model_set_name or "default",
            )

        # Compute hash
        content_hash = compute_content_hash(output_content)

        # Build output path
        filename_template = adapter_config.get("roles", {}).get("filename", "{name}.md")
        filename = filename_template.format(name=role_name)
        output_path = output_dir / filename

        # Check if we should skip (hash-based)
        skip = False
        if not force and output_path.exists():
            existing_hash = _sha256_file(output_path)
            if existing_hash == content_hash:
                skip = True
                skipped_files.append(str(output_path.relative_to(repo_root)))

        if not skip:
            if not dry_run:
                output_path.parent.mkdir(parents=True, exist_ok=True)
                output_path.write_text(output_content)
            generated_files.append(str(output_path.relative_to(repo_root)))

    # Update manifest
    generation_info = {
        "last_generated": datetime.utcnow().isoformat() + "Z",
        "model_set": model_set_name,
        "model_set_hash": model_set_hash,
        "adapter_config_hash": _sha256_file(adapter_path / "adapter.yaml"),
        "files": generated_files + skipped_files,
    }

    if not dry_run:
        update_manifest(manifest_path, adapter_name, generation_info)

    return {
        "adapter": adapter_name,
        "status": "success",
        "model_set": model_set_name,
        "roles_generated": len(generated_files),
        "roles_skipped": len(skipped_files),
        "skills_symlink_created": skills_config.get("strategy") == "symlink",
        "dry_run": dry_run,
        "generated_files": generated_files,
        "skipped_files": skipped_files,
    }


def main() -> None:
    """Main entry point for aix-generate script."""
    parser = argparse.ArgumentParser(
        description="Generate tool-specific configurations from canonical AIX roles"
    )
    parser.add_argument(
        "--adapter",
        help="Adapter to generate (claude, opencode, factory, agentskills, or 'all')",
    )
    parser.add_argument(
        "--model-set",
        help="Model set to use (overrides tier.yaml and adapter default)",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Generate all enabled adapters from tier.yaml",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be generated without writing files",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Regenerate all files even if unchanged",
    )
    parser.add_argument(
        "--repo-root",
        help="Path to repository root (default: git root)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output results as JSON",
    )

    args = parser.parse_args()

    # Determine repo root
    repo_root = Path(args.repo_root) if args.repo_root else _git_root()

    # Determine which adapters to generate
    adapters_to_generate: Dict[str, Optional[str]] = {}

    if args.all:
        # Get enabled adapters from tier.yaml
        adapters_to_generate = get_enabled_adapters(repo_root)
        if not adapters_to_generate:
            # If no tier.yaml config, generate all available adapters
            adapters_dir = repo_root / ".aix" / "adapters"
            if adapters_dir.exists():
                for adapter_dir in adapters_dir.iterdir():
                    if adapter_dir.is_dir() and not adapter_dir.name.startswith("_"):
                        adapters_to_generate[adapter_dir.name] = None
    elif args.adapter:
        adapters_to_generate[args.adapter] = args.model_set
    else:
        parser.error("Must specify --adapter or --all")

    # Generate each adapter
    results = []
    for adapter_name, model_set in adapters_to_generate.items():
        result = generate_adapter(
            repo_root,
            adapter_name,
            model_set_name=model_set,
            dry_run=args.dry_run,
            force=args.force,
        )
        results.append(result)

    # Output results
    if args.json:
        print(json.dumps({"results": results}, indent=2))
    else:
        print("AIX Generate Report")
        print(f"- Repo: {repo_root}")
        print(f"- Dry Run: {args.dry_run}")
        print(f"- Force: {args.force}")
        print()

        for result in results:
            adapter = result["adapter"]
            status = result["status"]

            print(f"Adapter: {adapter}")
            print(f"  Status: {status}")

            if status == "error":
                print(f"  Error: {result['error']}")
            else:
                if result.get("model_set"):
                    print(f"  Model Set: {result['model_set']}")
                print(f"  Roles Generated: {result.get('roles_generated', 0)}")
                print(f"  Roles Skipped: {result.get('roles_skipped', 0)}")
                print(f"  Skills Symlink: {result.get('skills_symlink_created', False)}")

                if result.get("generated_files"):
                    print(f"  Generated Files:")
                    for f in result["generated_files"]:
                        print(f"    - {f}")

                if result.get("skipped_files"):
                    print(f"  Skipped Files (unchanged):")
                    for f in result["skipped_files"]:
                        print(f"    - {f}")

            print()


if __name__ == "__main__":
    main()
