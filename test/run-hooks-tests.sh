#!/usr/bin/env bash
# Falsifiable test harness for claude-code-hooks.
# Proves the guardrail hooks actually behave (not just that files exist).
# Sandboxes all state under a temp PROJECT_ROOT so the repo stays clean.
#
# Run: bash test/run-hooks-tests.sh
# Exit 0 = all pass; non-zero = failures (count printed).

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS="$REPO/hooks"

PASS=0
FAIL=0
FAILURES=()

ok()   { PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); FAILURES+=("$1"); printf '  \033[31mFAIL\033[0m %s\n' "$1"; }
sect() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }

# Fresh sandbox project root for every run (deterministic, no repo pollution).
SANDBOX="$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/cch-test-$$")"
mkdir -p "$SANDBOX"
export PROJECT_ROOT="$SANDBOX"
export CLAUDE_PROJECT_DIR="$SANDBOX"
export CLAUDE_SESSION_ID="test-session"
trap 'rm -rf "$SANDBOX"' EXIT

# ────────────────────────────────────────────────────────────
sect "1. Syntax integrity (every hook parses)"
SH_COUNT=0; JS_COUNT=0
for f in "$HOOKS"/*.sh "$HOOKS"/lib/*.sh; do
  [ -f "$f" ] || continue
  SH_COUNT=$((SH_COUNT+1))
  if bash -n "$f" 2>/dev/null; then ok "bash -n $(basename "$f")"; else bad "bash -n $(basename "$f")"; fi
done
for f in "$HOOKS"/*.js "$HOOKS"/lib/*.js; do
  [ -f "$f" ] || continue
  JS_COUNT=$((JS_COUNT+1))
  if node --check "$f" 2>/dev/null; then ok "node --check $(basename "$f")"; else bad "node --check $(basename "$f")"; fi
done

# ────────────────────────────────────────────────────────────
sect "2. Inventory truth (claimed vs present) — informational, non-gating"
TOTAL_HOOKS=$(( $(ls "$HOOKS"/*.sh "$HOOKS"/*.js "$HOOKS"/*.ts 2>/dev/null | wc -l) ))
echo "  hooks present: ${TOTAL_HOOKS} script files (sh=$SH_COUNT js=$JS_COUNT + ts)"
echo "  README claims: 15 hooks"
# Phantom hooks the README references but that do not exist. Reported as DRIFT,
# not gated — README is tracked separately; see HARNESS.md for the doc-fix action.
for phantom in circuit-breaker-post.sh context-preservation.sh; do
  if [ -f "$HOOKS/$phantom" ]; then
    echo "  ok    README hook present: $phantom"
  else
    printf '  \033[33mDRIFT\033[0m README references hook that does not exist: %s\n' "$phantom"
  fi
done

# ────────────────────────────────────────────────────────────
sect "3. circuit-breaker.sh — failure counting + enforcement"
CB="$HOOKS/circuit-breaker.sh"
TARGET="$SANDBOX/some-file.ts"

# fresh check on unknown file → exit 0, silent
out=$(bash "$CB" check "$TARGET"); rc=$?
[ $rc -eq 0 ] && [ -z "$out" ] && ok "fresh file: check exits 0, no warning" || bad "fresh file check (rc=$rc out='$out')"

# 3 failures → WARN
bash "$CB" record "$TARGET" Edit >/dev/null
bash "$CB" record "$TARGET" Edit >/dev/null
out=$(bash "$CB" record "$TARGET" Edit)
echo "$out" | grep -q "WARN" && ok "3 failures → WARN" || bad "3 failures should WARN (got '$out')"

# up to 5 → RESTRICT
bash "$CB" record "$TARGET" Edit >/dev/null
out=$(bash "$CB" record "$TARGET" Edit)
echo "$out" | grep -q "RESTRICT" && ok "5 failures → RESTRICT" || bad "5 failures should RESTRICT (got '$out')"

# up to 8 → BREAK
bash "$CB" record "$TARGET" Edit >/dev/null
bash "$CB" record "$TARGET" Edit >/dev/null
out=$(bash "$CB" record "$TARGET" Edit)
echo "$out" | grep -q "BREAK" && ok "8 failures → BREAK" || bad "8 failures should BREAK (got '$out')"

# check at BREAK with enforcement ON → exit 2 (actually blocks)
out=$(ACOS_GATE_ENFORCE=true bash "$CB" check "$TARGET"); rc=$?
[ $rc -eq 2 ] && ok "BREAK + enforce → check exits 2 (BLOCKS edit)" || bad "BREAK+enforce should exit 2 (rc=$rc)"

# check at BREAK with enforcement OFF → exit 0 (advisory only)
out=$(bash "$CB" check "$TARGET"); rc=$?
[ $rc -eq 0 ] && echo "$out" | grep -q "BLOCKED" && ok "BREAK + no-enforce → advisory, exit 0" || bad "BREAK no-enforce should be advisory exit 0 (rc=$rc)"

# success resets counter → next check silent, exit 0
bash "$CB" success "$TARGET" >/dev/null
out=$(bash "$CB" check "$TARGET"); rc=$?
[ $rc -eq 0 ] && [ -z "$out" ] && ok "success resets counter" || bad "success should reset (rc=$rc out='$out')"

# status report runs
bash "$CB" status >/dev/null 2>&1 && ok "status report runs" || bad "status report failed"

# ────────────────────────────────────────────────────────────
sect "4. audit-trail.sh — append-only JSONL + integrity"
AT="$HOOKS/audit-trail.sh"
bash "$AT" log "test_event" "harness smoke" >/dev/null
bash "$AT" tool "Edit" "$TARGET" "ok" >/dev/null
bash "$AT" gate "$TARGET" "PASS" "sentinel" >/dev/null
bash "$AT" config "$TARGET" "snapshot" "snap_x" >/dev/null
AUDIT="$SANDBOX/.claude-flow/audit.jsonl"
[ -f "$AUDIT" ] && ok "audit.jsonl created" || bad "audit.jsonl missing"
n=$(wc -l < "$AUDIT" 2>/dev/null | tr -d ' ')
[ "${n:-0}" -ge 4 ] && ok "4 events appended (n=$n)" || bad "expected >=4 audit lines (n=$n)"
bash "$AT" verify >/dev/null 2>&1 && ok "verify → integrity CLEAN (exit 0)" || bad "verify should pass on valid JSONL"
# corrupt a line → verify must fail
echo "{not valid json" >> "$AUDIT"
if bash "$AT" verify >/dev/null 2>&1; then bad "verify should FAIL on corrupted line"; else ok "verify detects corruption (exit non-zero)"; fi

# ────────────────────────────────────────────────────────────
sect "5. self-modify-gate.sh — snapshot / revert"
SMG="$HOOKS/self-modify-gate.sh"
CFG="$SANDBOX/config.txt"
echo "original-content" > "$CFG"
snap=$(bash "$SMG" snapshot "$CFG" 2>/dev/null | tail -1)
[ -n "$snap" ] && ok "snapshot created ($snap)" || bad "snapshot returned no id"
echo "MODIFIED-AND-BROKEN" > "$CFG"
bash "$SMG" revert "$CFG" "$snap" >/dev/null 2>&1
if grep -q "original-content" "$CFG"; then ok "revert restores original content"; else bad "revert did NOT restore (got: $(cat "$CFG"))"; fi
smg_score=$(bash "$SMG" score 2>/dev/null)
echo "$smg_score" | grep -qi "score" && ok "score command runs" || bad "score command failed (got '$smg_score')"

# ────────────────────────────────────────────────────────────
sect "6. quality-gate.sh — runs non-blocking (documented behavior)"
QG="$HOOKS/quality-gate.sh"
out=$(printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$TARGET" | bash "$QG" 2>/dev/null); rc=$?
[ $rc -eq 0 ] && ok "quality-gate passes through, exit 0 (non-blocking by design)" || bad "quality-gate should exit 0 (rc=$rc)"

# ────────────────────────────────────────────────────────────
printf '\n\033[1m================ RESULT ================\033[0m\n'
printf '  PASS: %d   FAIL: %d\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  printf '\n  Failing assertions:\n'
  for f in "${FAILURES[@]}"; do printf '    - %s\n' "$f"; done
  exit 1
fi
echo "  All guardrail behaviors verified."
exit 0
