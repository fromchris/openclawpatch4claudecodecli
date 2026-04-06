# openclawpatch4claudecodecli

Patch for making OpenClaw's built-in `claude-cli` backend usable with Claude Code CLI.

## Prerequisite

The target machine must already have **Claude Code CLI** installed and working.

At minimum:

```bash
claude --version
claude --print "hi"
```

must work for the target user.

## Usage

### 1. Update OpenClaw settings

Configure the bot / agent to use `claude-cli` as its model backend.

Example:

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "claude-cli/claude-opus-4-6"
      },
      "models": {
        "claude-cli/claude-opus-4-6": {}
      },
      "cliBackends": {
        "claude-cli": {
          "command": "/usr/bin/claude",
          "systemPromptWhen": "first"
        }
      }
    }
  }
}
```

### 2. Apply the patch

```bash
git clone git@github.com:fromchris/openclawpatch4claudecodecli.git
cd openclawpatch4claudecodecli
./install.sh
```

The installer will:

- locate OpenClaw's `dist/pi-embedded-*.js`
- create a backup
- patch `resolveSystemPromptUsage()`

Then restart the affected OpenClaw service / gateway.

## What the patch does

Instead of injecting the full OpenClaw runtime system prompt into Claude Code CLI, it swaps that for a short **workspace-lite boot prompt**.

The boot prompt tells Claude to reconstruct context from workspace files itself:

- `AGENTS.md`
- `SOUL.md`
- `IDENTITY.md`
- `USER.md`
- `TOOLS.md`
- `HEARTBEAT.md`
- `BOOTSTRAP.md` (if present)
- `MEMORY.md`
- `memory/<today>.md`
- `memory/<yesterday>.md`

This avoids the failing full-prompt injection path while preserving persona / memory via file reads.

The boot prompt also includes **Kichi World status sync** — when kichi MCP tools are available, Claude will automatically sync avatar status (Thinking → Typing → Yay) during responses.

## Prerequisites for Kichi sync

The Kichi MCP daemon must be running for status sync to work. See [fromchris/kichimcp](https://github.com/fromchris/kichimcp) for setup.

## Files

- `install.sh`
- `openclaw-claude-cli-workspace-lite.patch`
