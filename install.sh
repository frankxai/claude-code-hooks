#!/bin/bash
# Claude Code Hooks Installer (upgraded for portability/multi-harness)
# Copies hooks + lib/hook-env.sh to .claude/hooks/ (or target)
# Now supports multi-harness via hook-env (claude/codex/gemini/agy/grok)
# Also installs ACOS ported shims (quality/gsd/mcp/pre-compact)

set -e

HOOK_DIR=".claude/hooks"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/hooks"
MULTI=0

if [ "$1" = "--multi" ] || [ "$1" = "--portable" ]; then
  MULTI=1
  echo "Multi-harness / portable mode enabled (hook-env)"
fi

echo "Claude Code Hooks Installer (portable v2)"
echo "========================================="

# Create target directory
mkdir -p "$HOOK_DIR"
mkdir -p "$HOOK_DIR/lib"

# Grok support: if --multi and Grok detected or .grok dir, also seed .grok/hooks for JSON excellence (Kenya magical per SHARING/SIP)
if [ "$MULTI" = "1" ] && { [ -d "$HOME/.grok" ] || command -v grok >/dev/null 2>&1 || [ -n "$GROK_CLI" ]; }; then
  GROK_HOOK_DIR="$HOME/.grok/hooks"
  mkdir -p "$GROK_HOOK_DIR"
  echo "Grok detected: seeding .grok/hooks for JSON excellence gates (SessionStart/PreToolUse - Kenya magical only)"
  # Copy json if present in source (or create minimal excellence ones)
  for j in "$SOURCE_DIR"/*.json; do
    [ -f "$j" ] || continue
    cp "$j" "$GROK_HOOK_DIR/" 2>/dev/null || true
    echo "  INSTALLED to .grok/hooks: $(basename "$j")"
  done
  # Ensure excellence json seeds if not present (DNA, rules, catalog, gates, Kenya only)
  if [ ! -f "$GROK_HOOK_DIR/session-start-excellence.json" ]; then
    cat > "$GROK_HOOK_DIR/session-start-excellence.json" << 'GROKJSON1'
{"hooks":{"SessionStart":[{"command":"echo 'Frank DNA excellence. Read CLAUDE/AGENTS/SHARING/SIP first. Shared catalog. Use multi-harness-orchestrator + repo-mastery + excellence-review + harness-integration. Gates via gstack/santa/verification. Kenya .grok only.'"}]}}
GROKJSON1
    echo "  CREATED .grok/hooks/session-start-excellence.json (Kenya)"
  fi
  if [ ! -f "$GROK_HOOK_DIR/pretooluse-excellence.json" ]; then
    cat > "$GROK_HOOK_DIR/pretooluse-excellence.json" << 'GROKJSON2'
{"hooks":{"PreToolUse":[{"matcher":"Edit|Write|MultiEdit|Bash","command":"echo 'Excellence gate: rules/DNA/multi/repo-mastery/harnesses/gstack/santa? Kenya .grok magical only.'"}]}}
GROKJSON2
    echo "  CREATED .grok/hooks/pretooluse-excellence.json (Kenya)"
  fi
fi

# Copy lib first (hook-env.sh for all)
if [ -d "$SOURCE_DIR/lib" ]; then
  for f in "$SOURCE_DIR/lib/"*; do
    [ -f "$f" ] || continue
    NAME=$(basename "$f")
    cp "$f" "$HOOK_DIR/lib/$NAME"
    chmod +x "$HOOK_DIR/lib/$NAME" 2>/dev/null || true
    echo "  INSTALLED: lib/$NAME"
  done
fi

# Copy hooks + shims + ported advanced
COPIED=0
for hook in "$SOURCE_DIR"/*; do
  [ -f "$hook" ] || continue
  NAME=$(basename "$hook")
  # skip lib dir itself, already handled
  [ "$NAME" = "lib" ] && continue
  if [ -f "$HOOK_DIR/$NAME" ]; then
    echo "  SKIP: $NAME (already exists)"
  else
    cp "$hook" "$HOOK_DIR/$NAME"
    chmod +x "$HOOK_DIR/$NAME" 2>/dev/null || true
    echo "  INSTALLED: $NAME"
    COPIED=$((COPIED + 1))
  fi
done

# Also copy any .js advanced (quality etc) if not present
for js in "$SOURCE_DIR"/*.js; do
  [ -f "$js" ] || continue
  NAME=$(basename "$js")
  if [ ! -f "$HOOK_DIR/$NAME" ]; then
    cp "$js" "$HOOK_DIR/$NAME"
    echo "  INSTALLED: $NAME (ACOS port)"
    COPIED=$((COPIED + 1))
  fi
done

echo ""
echo "Installed $COPIED hooks + lib to $HOOK_DIR/"
echo "Hook env provides portable paths + harness detect."
echo ""
echo "Next: Add hooks to your .claude/settings.json (or .grok/hooks for Grok)"
echo "See README.md for configuration examples."
echo "For ACOS ports: wire quality-gate.sh / gsd-*.sh / mcp-*.sh / pre-compact.sh"
