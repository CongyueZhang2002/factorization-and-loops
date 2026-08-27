# Project goals

This directory records current objectives and their completion conditions. It
is deliberately separate from `Exchange/`: Exchange contains correspondence
and reviews, while Goals records what outcome is being pursued, its present
state, and the next gate.

## Layout

```text
Goals/
  Codex/YYYY-MM-DD/NN_short_goal_description.md
  Fable/YYYY-MM-DD/NN_short_goal_description.md
```

- The date is the day the owner adopts the goal into the active plan.
- `NN` is the goal's order on that day and is never reused.
- One file owns one goal. Cross-agent work names one owner and lists the other
  participants instead of duplicating the goal in both trees.
- Each dated directory may carry a `STATUS.md` dashboard. The numbered goal
  files remain the authoritative records.

## Status notation

Goals remain in their original numbered order. They are never moved merely
because their status changes.

- `[🟢]` completed and accepted;
- `[🟡]` actively in progress;
- `[ ]` not started;
- `[🔴]` blocked or failed, followed by the reason.

Every goal file contains an overall status, owner, completion conditions,
evidence, and one explicit next gate. Historical work logs and detailed review
arguments should be linked from `Exchange/` or `Results/`, not copied into the
goal.
