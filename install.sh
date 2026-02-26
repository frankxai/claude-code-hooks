#!/bin/bash
# Claude Code Hooks Installer
# Copies hooks to your project's .claude/hooks/ directory

set -e

HOOK_DIR=".claude/hooks"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/hooks"

echo "Claude Code Hooks Installer"
echo "==========================="

# Create target directory
mkdir -p "$HOOK_DIR"

# Copy hooks
COPIED=0
for hook in "$SOURCE_DIR"/*; do
  NAME=$(basename "$hook")
  if [ -f "$HOOK_DIR/$NAME" ]; then
    echo "  SKIP: $NAME (already exists)"
  else
    cp "$hook" "$HOOK_DIR/$NAME"
    chmod +x "$HOOK_DIR/$NAME"
    echo "  INSTALLED: $NAME"
    COPIED=$((COPIED + 1))
  fi
done

echo ""
echo "Installed $COPIED hooks to $HOOK_DIR/"
echo ""
echo "Next: Add hooks to your .claude/settings.json"
echo "See README.md for configuration examples."
