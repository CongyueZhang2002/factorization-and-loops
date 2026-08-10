# FACET Repository Instructions

## Agent workspace

All agent-generated scratch scripts, intermediate Kira projects, run state,
logs, staging files, test output, and backups belong under
`/home/maxzhang/FACET/Codex`, in the matching process branch. Do not create
`.codex_tmp`, `.staging`, `.Kira`, `tmp`, `notebook_backups`, or generated log
files elsewhere in the FACET tree. Production notebooks, cards, pair data, and
final analytic results remain in their normal production directories.

## Reporting language

Use precise terms for verification and status. Call an executed calculation a
`test` and report its measured `result`. State the acceptance criterion before
saying that a test passed; otherwise report the observed values without using
`pass`. Use `regression test` only when explicitly describing a repetition of
a previously established test after a code change, and define that meaning the
first time it appears. Do not use `regression` as a generic synonym for test,
run, benchmark, or validation.

## Mathematica notebook safety

Never save or rewrite a `.nb` through a hidden or offscreen FrontEnd, and never
run a headless FrontEnd while a visible Wolfram FrontEnd is open. This can
persist `Visible -> False`, oversized `WindowSize`, and negative
`WindowMargins`, breaking mouse hit testing and cell selection.

Treat every notebook save as a high-risk operation. Package, script, and test
changes must never resave an open `.nb` as a side effect. Do not use
`NotebookSave`, `NotebookPut`, notebook `Export`, or a programmatically launched
FrontEnd unless the user explicitly requested a notebook edit.

For every requested notebook edit:

1. Back up the exact on-disk notebook first.
2. Close every FrontEnd that has the notebook open before changing the file.
3. Modify only the requested cells or options; never regenerate the notebook.
4. Persist a bounded `WindowSize`, nonnegative `WindowMargins`,
   `ShowCellBracket -> True`, and no `Visible` option.
5. Do not reopen a Linux notebook from Codex, `wsl.exe`, `wolframscript`, or an
   automated FrontEnd command. That path can evaluate initialization cells and
   rewrite outputs and window options on exit. Leave it closed for the user to
   open normally.
6. Re-read the on-disk file and verify the required options before completion.

Never automate notebook-window clicks, `Alt+F4`, or save-dialog responses. If
an automated launch occurs accidentally, restore the pre-launch backup rather
than retaining any FrontEnd-generated rewrite.
