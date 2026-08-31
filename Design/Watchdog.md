# The standing watchdog (house rule; standardized 2026-08-22)

## Launch allowance and auto-kill (user directive 2026-08-31)

Every launched run EMBEDS its own kill: the launcher starts the kernel
with `setsid` (its own process group), and a timer inside the SAME
launcher SIGKILLs the whole group (`kill -9 -- -$PID`) when a declared
allowance expires. Size the allowance from the DESIGN expectation
(about 3x the expected wall), never from hope. Rationale, paid for on
2026-08-31: a coordinator cannot reliably kill an escaped kernel later
(a busy WolframKernel ignores SIGTERM for an hour; SIGKILL from the
coordinator can be permission-blocked), and the user will not do it.
Corollary for the coordinator: at EVERY watchdog anomaly, the default
action is to stop the run and redesign — "it should finish soon" is a
trajectory guess, not evidence; a run that is off its design
expectation has already answered the question its allowance asks.

**Rule (user directive 2026-08-20, reaffirmed 2026-08-22 after a 10-minute
loss):** whenever any compute of ours runs in the background — a campaign,
a benchmark, a test batch, a single long solve — ONE Opus watchdog
subagent is spawned IN THE SAME TURN as the launch. It checks once
immediately and then every 5 minutes, is strictly read-only, and reports
back only on an anomaly or when everything it watches has drained. A
bash `Monitor` is NOT a substitute: it catches what the coordinator
thought to grep for; the watchdog reads the logs with judgement (the
`Set::wrsym` catch of 2026-08-21 and the idle-driver loop of 2026-08-22
are the two cases a pattern would have missed).

## Registering work

Append one line per watched output to the session watchlist:

    <scratchpad>/watchdog/watchlist.tsv      output_file <TAB> label <TAB> stall_minutes

`Scripts/watchdog_register.sh <output_file> <label> [stall_minutes=30]`
does it. For KernelPool missions the output file is `<pool>/logs/<name>.log`;
for a campaign add the driver's `campaign_status.tsv` and the pool's
`status.txt` as well (stall 15).

## The prompt (copy verbatim, fill the <> fields)

```
You are the read-only WATCHDOG for background compute in the FeynFacet project
(repository /home/maxzhang/factorization-and-loops; read CLAUDE.md "Reporting
language" before writing anything). Watchlist: <WATCHLIST> (tab-separated:
output_file, label, stall_minutes; re-read it every round -- entries may be
added while you run). Heartbeat: <HEARTBEAT> (append one line per round per
entry). State: <STATE> (overwrite with the current verdict).

Rounds: the first check NOW, then every 5 minutes. Do the rounds with a
background bash loop you write (sleep 300 between rounds) that appends to the
heartbeat and writes STATUS=ANOMALY/OK/ALL-DRAINED to the state file; then
block on the state file (Monitor or an until-loop in a background bash) and
END YOUR TURN with a report the moment it says ANOMALY or ALL-DRAINED. Your
final report is the only channel to the coordinator: make it one paragraph --
what you saw, the exact log lines, your assessment of cause -- no routine
narration.

Per entry, each round, in this order:
1. Liveness: `fuser <output_file>` (a kernel holds its log open) and, for a
   KernelPool mission, `<pool>/running/<name>.kernel`; NEVER judge liveness
   by a process-name pattern.
2. Fatal signatures in the new lines since last round: `!!`, `::` messages
   other than the known-benign ones, "not activated", "license", "Failed to
   open", "$Aborted", "Segmentation", "KERNELLOST", "EXIT", "Throw::nocatch",
   "Set::wrsym", "Part::partw".
3. Progress: bytes/lines delta and the last milestone line (sector done,
   strip solved, prime validated, MISSION end). A run SILENT for longer than
   stall_minutes is an anomaly only if its kernel is also idle (CPU of the
   PID from `<pool>/running/<name>.kernel` + pool.log's PID map, or of the
   process holding the log per fuser) -- finite-field solves print nothing
   for minutes at 100% CPU.
4. Sanity of the design, not just the process: if the log shows the run
   doing something the plan did not intend (every sample discarded, a
   fallback route engaged on every strip, the same prime repeated, the
   driver idle while a mission finished long ago, estimates off by
   multiples), that is an anomaly too.
5. Completion: a mission log ending in "MISSION end ... status OK" or a
   family "written family_epsform_<CF>.wl; GateVerdict True" is done; a
   status other than OK is an anomaly.

Hard rules: never kill, restart, cancel, resubmit, or run Wolfram; never
`pkill`/`pgrep -f` patterns (they self-match); never edit repository files;
write only to the heartbeat and state files. Quiet hours 01:00-11:00 do not
apply to you (you report to the coordinator, not the user). Stop after
<HOURS> hours even if nothing drained, reporting the state.
```

Spawn it with `Agent` (subagent_type general-purpose or claude, model opus,
run_in_background true). When it reports, the coordinator acts and respawns
(or continues it with SendMessage) while anything is still running.

## Lessons from the 2026-08-25 hardening-wave watch (4 h, 4 real findings, ~7 self-defused false positives)

A watchdog's default failure mode is crying wolf. The rules that earned
their keep were anchored to AUTHORITATIVE STATE; the ones that fired
falsely were anchored to names and text. Concretely, for future prompts:

- Judge "did a production run start" by a byte fingerprint of the
  campaign's state files (sector_state, campaign_status.tsv,
  *_solve.status, mission logs) against a baseline taken at watch
  start — never by process paths (an authorized measurement writing
  into its own evidence dir under the campaign tree is not a launch).
- Count licence seats by WolframKernel processes only; a wolframscript
  wrapper is not a seat.
- Scan for fatal signatures only in RUN logs, excluding the suite's or
  agent's own reporting lines (assertion labels and prose legitimately
  quote "$Aborted").
- Judge a suite only in the NEWEST batch that ran it; a streak counts
  distinct new results, not rounds re-reading a finished log.
- Word-boundary the tally regexes ("40 OK, 0 FAIL" is not zero
  assertions).
- Verify a stand-down instead of taking it on report: loop PID gone
  (killed by exact recorded PID — of the script, not its wrapper),
  kernel count zero, expected commits in git log, gate line in the
  artifact.

Real findings this watch that a pattern-only watch would have missed:
a suite recorded exit=0 that had aborted at line 3 (dead in the
battery), a boolean failure tally reporting fail=1 for two reds, and
the audit that a test "fix" strengthened rather than weakened its
assertions (byte-compare against HEAD, count direction).

## Lesson from the 2026-08-28 CF300 watch (rate-based idle test)

The stall rule "silent longer than stall_minutes AND kernel idle (< 50
CPU ticks per round)" missed a 15-minute blocked state: the Wolfram tree
held ~1600-1700 ticks per 5-minute round (~5% of one core — above the
tick floor) while blocked on an external Maple call that ultimately
FAILed. Future prompts: make the idle test rate-based — sustained usage
below ~20% of one core across two consecutive rounds, while the log is
silent, is a blocked-state anomaly even when absolute tick counts clear
the floor. (The blocked call was a Legacy-route Maple fallback; the
watch flagged nothing because 30 minutes of silence had not elapsed.)
