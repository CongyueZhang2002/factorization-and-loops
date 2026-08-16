# FableBridge — standardized consults of Fable (Max) from this project

Mirror of Codex's ChatGPT-Pro bridge (their General/ChatGPT/
pro_bridge_state.json pattern), adapted to our stack.

## Why this shape
The claude.ai chat "Fable Max" runs the same claude-fable-5 model that
powers this session.  A consult is therefore reproduced faithfully by a
FRESH-CONTEXT invocation of that model on a self-contained prompt: the
value of "asking Max" is the clean context and review framing, not a
different network.

## Transport A (primary, zero-auth): in-session subagent
The coordinating agent (Fable, in Claude Code) runs, verbatim:

  Agent tool, subagent_type "general-purpose", model "fable",
  prompt: "You are an independent expert reviewer with no prior
  context.  Read <prompts/FILE.md>, answer it fully and critically,
  and Write your complete answer to <responses/FILE_response.md>.
  Do not consult other files unless the prompt names them."

Conventions:
- prompts/ files are SELF-CONTAINED (the 2026-08-16 hard-class review
  prompt is the reference example: setting, measured facts, sharp
  numbered questions, "name the decisive test" instruction).
- prepare.sh stamps a manifest (sha256, date, model) beside the prompt;
  the response file is committed with it.
- One consult = one prompt file = one response file.  Follow-ups are
  new prompt files that QUOTE the relevant part of the prior response
  (fresh context each time; no hidden conversational state).

## Transport B (fallback, shell-only): claude CLI print mode
  ~/.claude/remote/ccd-cli/<ver> -p --model claude-fable-5 < prompt.md
Requires a one-time `/login` in an interactive `claude` (the remote
bridge's auth does not extend to print mode).  Useful for scripts that
must run without the coordinating agent.

## What NOT to do
- No pasting of session-internal shorthand: a consult prompt that
  cannot be understood standalone produces review noise.
- Numerics-free claims stay numerics-free in prompts: label every
  number as measured/estimated exactly as our exchange notes do.
