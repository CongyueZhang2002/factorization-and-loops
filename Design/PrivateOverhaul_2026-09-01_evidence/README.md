# Evidence of the 2026-09-02 overhaul acceptance

- `baseline_tests_2d73f71f.log`, `baseline_table.md`: the full suite on main at
  2d73f71f (driver fixes B1-B3 only), REUSE-mode KernelPool, pooled phase
  plus standalone confirmations; `baseline_tests_notes.log` records the
  three 30-minute caps.
- `overhaul_pooled_phase.log`, `overhaul_pooled_table.md`: the pooled phase
  of the `overhaul` branch (the driver died before its standalone phase;
  see the plan, 06:37).
- `seatqueue_confirm_queue1..4.log` + `confirmation_table_queue1..4.md`: the branch's standalone
  confirmations in fresh kernels (one licence seat, sequential), including
  the reruns after each fix (`fix1_` ... `fix11_`) and the certification
  diagnostics.
- `final_table.md`: the merged verdict per test (baseline vs overhaul).
- `adversarial_review_2026-09-02.md`: the review agent's report (D1-D4 fixed,
  R1-R5 fixed, notes applied or listed as not done).
- The Python/bash files are the tools that produced the tables.
