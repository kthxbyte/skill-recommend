#!/usr/bin/env bash
# sync-registry.sh
# Caches metadata for Anthropic's official skill marketplace (anthropic-agent-skills).
#
# Source of truth is the marketplace manifest in the anthropics/skills repo. It lists
# every plugin and the skills each plugin ships — which is exactly what we need, since
# official skills are installed by *plugin*, not individually. We read it once and build
# a flat skill -> plugin -> install-command registry.
#
# Runs at session start if the cache is stale (> 7 days old) or missing.

set -euo pipefail

REGISTRY_DIR="$HOME/.claude/skill-recommend"
REGISTRY_FILE="$REGISTRY_DIR/registry.json"
SYNC_FILE="$REGISTRY_DIR/last-sync.txt"

MARKETPLACE_URL="https://raw.githubusercontent.com/anthropics/skills/main/.claude-plugin/marketplace.json"
SKILLS_RAW_BASE="https://raw.githubusercontent.com/anthropics/skills/main"

mkdir -p "$REGISTRY_DIR"

# ── Skip if the cache is still fresh ───────────────────────────────────────────
if [ -f "$SYNC_FILE" ]; then
  last_sync=$(cat "$SYNC_FILE")
  now=$(date -u +%s)
  last_sync_epoch=$(date -u -d "$last_sync" +%s 2>/dev/null \
    || date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_sync" +%s 2>/dev/null \
    || echo 0)
  age_days=$(( (now - last_sync_epoch) / 86400 ))
  if [ "$age_days" -lt 7 ]; then
    echo "Registry is fresh ($age_days days old). Skipping sync."
    exit 0
  fi
fi

echo "Syncing Anthropic official skill registry..."

manifest=$(curl -sf "$MARKETPLACE_URL" || true)
if [ -z "$manifest" ]; then
  echo "Warning: could not fetch marketplace manifest. Keeping existing registry." >&2
  exit 0
fi

tmp_registry=$(mktemp)

# Build registry.json: one entry per skill, mapped to the plugin that ships it and the
# exact install command. The per-skill description is read from each SKILL.md frontmatter.
# The manifest is passed on stdin; SKILLS_RAW_BASE is exported to the python process.
printf '%s' "$manifest" | SKILLS_RAW_BASE="$SKILLS_RAW_BASE" python3 -c '
import sys, json, re, os, urllib.request, urllib.error

try:
    manifest = json.loads(sys.stdin.read())
except json.JSONDecodeError:
    print("[]"); sys.exit(0)

market = manifest.get("name", "anthropic-agent-skills")
base = os.environ["SKILLS_RAW_BASE"]
registry = []

def fetch_description(skill_path):
    url = f"{base}/{skill_path}/SKILL.md"
    try:
        with urllib.request.urlopen(url, timeout=5) as resp:
            content = resp.read().decode("utf-8")
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError):
        return ""
    m = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not m:
        return ""
    fm = m.group(1)
    d = re.search(r"^description:\s*(.+?)(?=\n\w+:|\Z)", fm, re.DOTALL | re.MULTILINE)
    if not d:
        return ""
    text = d.group(1).strip()
    text = re.sub(r"^[|>][-+]?\s*", "", text)        # drop leading YAML block-scalar token
    text = re.sub(r"\s+", " ", text).strip()
    text = re.sub(r"^[\"\x27]+|[\"\x27]+$", "", text) # drop surrounding quotes (\x27 = apostrophe)
    return text.strip()

for plugin in manifest.get("plugins", []):
    plugin_name = plugin["name"]
    install = f"/plugin install {plugin_name}@{market}"
    for skill_ref in plugin.get("skills", []):
        skill_path = skill_ref.lstrip("./").rstrip("/")   # e.g. skills/pdf
        skill_name = skill_path.split("/")[-1]
        description = fetch_description(skill_path)
        words = re.findall(r"\b[a-z]{4,}\b", (skill_name + " " + description).lower())
        keywords = list(dict.fromkeys(words))[:12]        # deduped, first 12
        registry.append({
            "skill": skill_name,
            "plugin": plugin_name,
            "description": description,
            "keywords": keywords,
            "install_command": install,
            "source": f"anthropics/skills/{skill_path}",
        })

print(json.dumps(registry, indent=2))
' > "$tmp_registry"

mv "$tmp_registry" "$REGISTRY_FILE"
date -u +"%Y-%m-%dT%H:%M:%SZ" > "$SYNC_FILE"

skill_count=$(python3 -c "import json; print(len(json.load(open('$REGISTRY_FILE'))))" 2>/dev/null || echo "?")
echo "Registry synced: $skill_count skills cached at $REGISTRY_FILE"
