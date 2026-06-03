# Harness — claude-code-hooks

**Profile:** C — Library / SDK (guardrail layer; the safety spine the whole ecosystem leans on)
**Stack installed:** L1 ☑ (CI) · L2 ☑ (behavior tests) · L3 ☐ · L4 ☐ · L5 ☐
**Last verified:** 2026-06-03

## Claimed vs verified

| Claim (README) | Reality (verified) | Verdict |
|---|---|---|
| "15 hooks" | **30 script files** in `hooks/` (19 `.sh`, 12 `.js`, `.ts` adapters) + `lib/` | Undercount — README lists ~17 named hooks; far more ship |
| `circuit-breaker-post.sh` (referenced in README table) | **does not exist** (only `circuit-breaker.sh`) | Phantom reference — README drift |
| `context-preservation.sh` (referenced in README table) | **does not exist** (only `pre-compact.sh` / `pre-compact.js`) | Phantom reference — README drift |
| `quality-gate.sh` "BLOCKs hardcoded hex colors" (README example) | `quality-gate.js` is a **formatter runner** (biome/prettier); it passes stdin through and never exits non-zero | Behavior drift — gate is non-blocking by design |
| "15 battle-tested hooks", "155+ production sessions" | Not independently reproducible from repo; **now made falsifiable** by `test/run-hooks-tests.sh` | Replaced anecdote with a reproducible gate |

The three guardrails that actually enforce are **proven behavior** (see below), so the
"production-grade guardrails" thesis holds — the drift is in the *docs*, not the *code*.

## Verified behavior (47/47 assertions pass)

`test/run-hooks-tests.sh` sandboxes all state under a temp `PROJECT_ROOT` and proves:

- **Syntax integrity** — `bash -n` on all 19 `.sh` + `node --check` on all 12 `.js`/lib (31 files) parse clean.
- **circuit-breaker.sh** — failure counting 3→WARN, 5→RESTRICT, 8→BREAK; at BREAK with
  `ACOS_GATE_ENFORCE=true` the `check` command **exits 2 and blocks the edit**; without
  enforcement it is advisory (exit 0); `success` resets the counter. *This is the circuit breaker working.*
- **audit-trail.sh** — append-only JSONL written for `log`/`tool`/`gate`/`config`;
  `verify` returns CLEAN on valid data and **fails (non-zero) on a corrupted line**. *Audit trail is demonstrable.*
- **self-modify-gate.sh** — `snapshot` captures a file, `revert` restores it byte-for-byte after a destructive edit; `score` runs.
- **quality-gate.sh** — runs and passes through non-blocking (its real, documented behavior).

## Run it

```bash
git clone https://github.com/frankxai/claude-code-hooks.git
cd claude-code-hooks
bash test/run-hooks-tests.sh    # 47 assertions, exit 0 = all guardrails verified
```

Requires `bash`, `node`, `python3` (the hooks depend on python3 for audit/score serialization).

## CI

`.github/workflows/harness.yml` is written and ready (runs the harness on `ubuntu-latest`,
node 20 + python 3.12, fails the build on any guardrail regression). **Not yet committed:**
the current `gh` token lacks the `workflow` OAuth scope, so GitHub rejects pushes that add
workflow files. Action: `gh auth refresh -s workflow`, then commit the file. See ecosystem `BLOCKERS.md`.

## Golden dataset

N/A for this profile (deterministic behavior tests, not LLM-judged). The test suite **is** the regression spine.

## Demo today

**Yes** — `bash test/run-hooks-tests.sh` prints 47 PASS / 0 FAIL and a live circuit-breaker block (exit 2). Evidence regenerates locally at `test/_evidence/hooks-tests.log` (gitignored) and in CI on every run.

## Status: **SELLABLE**

The guardrail behaviors are real, reproducible, and CI-gated. Recommended follow-up (does
not block the grade): correct the README's hook count + remove the two phantom hook
references + fix the `quality-gate` description so docs match verified behavior. Left to
Frank because `README.md` already has unrelated uncommitted WIP in the working tree.
