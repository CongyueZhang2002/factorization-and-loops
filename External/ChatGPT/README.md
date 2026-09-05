# ChatGPT Pro bridge

This directory contains the workspace connector to the signed-in **ChatGPT
Classic desktop app**. It does not launch or automate Edge, Chrome, or another
browser.

## Files

- `pro_bridge.sh`: WSL entry point.
- `ProBridge.ps1` and `ProBridge.cmd`: Windows entry points.
- `ensure_pro_bridge.py`: prepares the background desktop-app endpoint without
  taking foreground focus.
- `pro_bridge.mjs`: creates, continues, monitors, and retrieves one tracked Pro
  conversation, including verified source-file uploads.

Runtime conversation state and pending prompt/response files are written to
`Codex/General/ChatGPT` and are intentionally excluded from Git. Each permanent
exchange is one Markdown file under `Records/YYYY-MM-DD/NN_summary_name.md`:
the question and Pro response are sections of that same file, and therefore
share one number. Uploaded files live below that exchange's `Sources`
directory and do not consume record numbers. Shared background material is in
`Context`; superseded connector utilities are in `Legacy/Tools`.

## WSL usage

```bash
mkdir -p Codex/General/ChatGPT
printf '%s\n' 'Your prompt' > Codex/General/ChatGPT/pending_topic_prompt.md
External/ChatGPT/pro_bridge.sh new Codex/General/ChatGPT/pending_topic_prompt.md
External/ChatGPT/pro_bridge.sh wait Codex/General/ChatGPT/pending_topic_response.md 7200
```

Use `send` instead of `new` to continue the tracked conversation. Other
commands are `status`, `retrieve`, `resend`, and `cancel`.

After retrieval, place the pending question and answer under `## Question` and
`## Pro response` in the next single numbered record. A retry or added context
sent before that answer remains in the same record. If one side was never
preserved, say so explicitly rather than reconstructing it.

To send source files, create a temporary JSON manifest next to the pending
prompt. Relative paths are resolved from the manifest directory:

```json
{
  "promptPath": "rewrite_prompt.txt",
  "files": [
    "Boundary_Integrals_and_Equivalence_Levels.tex"
  ]
}
```

The Classic composer accepts one source attachment reliably per turn. To add
several source files to one conversation, call `send-files` once for each
file. Each manifest must therefore contain exactly one entry in `files`.

Start a new conversation with `new-files`, or continue the tracked conversation
with `send-files`:

```bash
External/ChatGPT/pro_bridge.sh send-files Codex/General/ChatGPT/pending_rewrite_manifest.json
External/ChatGPT/pro_bridge.sh wait Codex/General/ChatGPT/pending_rewrite_response.md 7200
```

The connector waits until the filename is visible and no upload is in progress.
It then verifies that the outgoing conversation request contains the expected
file reference. A resubmission reuses the recorded source file and checks that
it still exists.

The bridge enforces `gpt-6-pro` and verifies the outgoing request before it
accepts a turn.
