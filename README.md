<div align="center">

# Claude Code Hooks

**Production-grade hook system for Claude Code**

*Quality gates, circuit breakers, skill activation, audit trails — 15 battle-tested hooks.*

[![Claude Code](https://img.shields.io/badge/Claude_Code-hooks-blue?style=for-the-badge)](https://docs.anthropic.com/en/docs/claude-code/hooks)
[![Hooks](https://img.shields.io/badge/hooks-15-emerald?style=for-the-badge)](#hooks)
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

## What Are Hooks?

Claude Code hooks are shell scripts and Node.js modules that run automatically during AI coding sessions. They intercept lifecycle events — before edits, after tool calls, on session start/stop — giving you control over quality, safety, and intelligence.

Supports the full 5-harness fleet + grok-personal excellence layer (the 4 .grok-native seeds + personal-creative per claude-code-config/SHARING.md). Excellence gates (quality-gate, pre-compact) enforce Frank DNA + rules first + core vs grok-personal/personal-creative partition. Portable across Claude, Grok TUI, agy, gemini. See SHARING.md for the "a bit magical, not for everything" discipline.

```
You edit a file → Quality Gate checks token compliance → PASS → Edit proceeds
You edit a file → Quality Gate detects hardcoded color → BLOCK → Suggests token
```

## Install

```bash
git clone https://github.com/frankxai/claude-code-hooks.git
cd claude-code-hooks
./install.sh
```

Or copy individual hooks to your `.claude/hooks/` directory.

**Multi-harness / Grok support:** `./install.sh --multi` or `--portable` seeds for claude/codex/gemini/agy/grok (via hook-env detection). For Grok, also seeds `~/.grok/hooks/*.json` for native SessionStart/PreToolUse excellence gates (Kenya-magical per SHARING.md + SIP §5: the excellence hooks stay sovereign in .grok/ only; core hooks portable to all). Kenya magical (Grok .grok excellence tuned for TUI/subagents/MCP/image + personal) not shared to ACOS core.

## The Hooks

`hooks/` ships ~30 files: most lifecycle hooks are a thin portable `.sh` wrapper (sources `hooks/lib/hook-env.sh` for multi-harness detection) backing onto a `.js`/`.ts` file with the real logic. `settings-example.json` is the canonical wired set — 16 hook registrations (15 unique hooks; `circuit-breaker.sh` is wired both pre- and post-tool-use) across 7 lifecycle events:

### Lifecycle: Session Start
| Hook | Purpose |
|------|---------|
| `session-start.js` | Initialize session context, load previous state |

### Lifecycle: Pre-Tool Use (Before Edits)
| Hook | Purpose |
|------|---------|
| `self-modify-gate.sh` | Prevent AI from modifying its own hook/config files |
| `circuit-breaker.sh` | Detect retry loops (3 warn / 5 restrict / 8 block thresholds) |
| `quality-gate.sh` | Wrapper for `quality-gate.js` — blocks edits that violate code standards, token compliance |

### Lifecycle: Post-Tool Use (After Actions)
| Hook | Purpose |
|------|---------|
| `post-tool-track.js` | Track tool usage patterns for learning |
| `audit-trail.sh` | Append-only log of every file modification |
| `file-link-tracker.sh` | Track file references across a session |
| `gsd-context-monitor.sh` | Wrapper for `gsd-context-monitor.js` — context-usage monitoring |
| `mcp-health-check.sh` | Wrapper for `mcp-health-check.js` — flags broken/misconfigured MCP servers |
| `circuit-breaker.sh` | Also runs post-edit (same file as the pre-tool-use entry above) |

### Lifecycle: User Prompt Submit
| Hook | Purpose |
|------|---------|
| `skill-activation-prompt.sh` | Wrapper for `skill-activation-prompt.js`/`.ts` — matches keywords/file patterns to skills |
| `session-logger.sh` | Persistent session history |

### Lifecycle: Pre-Compact (Before Context Compression)
| Hook | Purpose |
|------|---------|
| `pre-compact.sh` | Wrapper for `pre-compact.js` — currently a stub; extend with real context-preservation logic before relying on it |

### Lifecycle: Stop (Session End)
| Hook | Purpose |
|------|---------|
| `stop-finalize.js` | Save session state, generate summary |
| `session-end-log.sh` | Log session metrics and outcomes |

### Lifecycle: Notification
| Hook | Purpose |
|------|---------|
| `notification.sh` | Portable notification dispatch |

### Unwired (present in `hooks/`, not in `settings-example.json`)

`activation-logger.sh`, `context-budget-tracker.ts`, `excellence-hook.sh`, `memory-check.sh`, `pre-commit.sh`, `gsd-statusline.js`/`.sh`, `gsd-workflow-guard.js`/`.sh` exist as standalone scripts but aren't referenced by the example config — wire them manually if you want them, or treat them as experimental/reference implementations.

## How It Works

### Quality Gate (Pre-Edit)

The quality gate runs before every `Edit`, `Write`, or `NotebookEdit` tool call:

```bash
# .claude/hooks/quality-gate.sh
# Triggered: PreToolUse [Edit|Write|NotebookEdit]

# Check for hardcoded colors (should use tokens)
if grep -qP '#[0-9a-fA-F]{6}' "$FILE"; then
  echo "BLOCK: Use design tokens instead of hardcoded hex colors"
  exit 1
fi
```

### Circuit Breaker (Post-Edit)

Prevents infinite retry loops:

```bash
# Tracks consecutive failures per tool
# 3 failures → WARNING
# 5 failures → RESTRICTED (suggest alternative)
# 8 failures → BLOCKED (force stop)
```

### Skill Activation (Prompt Submit)

Automatically loads relevant skills based on what you're working on:

```javascript
// Detects: file patterns (.tsx → react-patterns)
// Detects: keywords ("blog post" → article-creator)
// Detects: magic words ("ultrawork" → swarm mode)
```

## Configuration

Add hooks to your `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|NotebookEdit",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/quality-gate.sh" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write|NotebookEdit|Bash",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/audit-trail.sh" }
        ]
      }
    ]
  }
}
```

## Part of ACOS

These hooks are extracted from the [Agentic Creator OS](https://github.com/frankxai/agentic-creator-os) — a full operating system for AI coding agents with 90+ skills, 65+ commands, and 38 agents.

## License

MIT
