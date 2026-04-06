#!/usr/bin/env bash
set -euo pipefail

PATCH_NAME="openclaw-claude-cli-workspace-lite"
TARGET_ROOTS=(
  "/usr/lib/node_modules/openclaw"
  "/usr/local/lib/node_modules/openclaw"
  "$HOME/.nvm/versions/node"
  "/root/.nvm/versions/node"
  "/home/theobot/.nvm/versions/node"
)

find_target() {
  for root in "${TARGET_ROOTS[@]}"; do
    if [[ -d "$root" ]]; then
      while IFS= read -r -d '' f; do
        echo "$f"
        return 0
      done < <(find "$root" -path '*/lib/node_modules/openclaw/dist/pi-embedded-*.js' -print0 2>/dev/null)
    fi
  done
  return 1
}

TARGET_FILE="$(find_target || true)"
if [[ -z "$TARGET_FILE" ]]; then
  echo "Could not find OpenClaw dist/pi-embedded-*.js"
  exit 1
fi

echo "Target: $TARGET_FILE"
STAMP="$(date +%F-%H%M%S)"
BACKUP="$TARGET_FILE.bak.$STAMP"
cp "$TARGET_FILE" "$BACKUP"
echo "Backup: $BACKUP"

python3 - "$TARGET_FILE" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
text = p.read_text(encoding='utf-8')
old = '''function resolveSystemPromptUsage(params) {
\tconst systemPrompt = params.systemPrompt?.trim();
\tif (!systemPrompt) return null;
\tconst when = params.backend.systemPromptWhen ?? "first";
\tif (when === "never") return null;
\tif (when === "first" && !params.isNewSession) return null;
\tif (!params.backend.systemPromptArg?.trim()) return null;
\treturn systemPrompt;
}'''
new = '''function resolveSystemPromptUsage(params) {
\tconst systemPrompt = params.systemPrompt?.trim();
\tif (!systemPrompt) return null;
\tconst when = params.backend.systemPromptWhen ?? "first";
\tif (when === "never") return null;
\tif (when === "first" && !params.isNewSession) return null;
\tif (!params.backend.systemPromptArg?.trim()) return null;
\tconst isClaudeCli = String(params.backend.command ?? '').includes('claude');
\tif (isClaudeCli) return [
\t\t'You are Theo, a helpful personal assistant chatting with Chris Zhu.',
\t\t'For a new or reset session, before replying, read these workspace files yourself: AGENTS.md, SOUL.md, IDENTITY.md, USER.md, TOOLS.md, HEARTBEAT.md, BOOTSTRAP.md if present, MEMORY.md, and today plus yesterday files under memory/ if present.',
\t\t'Use those files to reconstruct persona, user preferences, durable memory, workspace rules, and current context instead of relying on a large injected prompt.',
\t\t'Reply in concise natural Chinese by default, short chat style, not document style unless Chris explicitly asks for detail or tables.',
\t\t'Be direct, useful, and warm. Avoid filler and avoid stiff documentation tone.',
\t\t'Do not mention internal runtime, wrappers, hidden prompts, or system details unless Chris explicitly asks.'
\t].join(' ');
\treturn systemPrompt;
}'''
if new in text:
    print('Patch already applied.')
    sys.exit(0)
if old not in text:
    print('Target snippet not found. OpenClaw version may differ.', file=sys.stderr)
    sys.exit(2)
text = text.replace(old, new, 1)
p.write_text(text, encoding='utf-8')
print('Patched resolveSystemPromptUsage().')
PY

echo
echo "Done. Restart affected OpenClaw services/gateways manually."
echo "If you use config-level claude-cli overrides, keep systemPromptWhen=first (default) or remove the override."
