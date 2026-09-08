#!/bin/bash
# Read-only watchdog: strip_pullback_perf equivalence run + chained suites.
# Writes ONLY to heartbeat.log, state.txt and its own .prev/.seen cache.
# Never kills, restarts or runs Wolfram.  No pkill / pgrep -f.
S=/tmp/claude-1000/-home-maxzhang/9e941be4-c161-4634-89fb-8d0804f16b66/scratchpad/strip_pullback_perf
W=$S/watchdog
WL=$W/watchlist.tsv
HB=$W/heartbeat.log
ST=$W/state.txt
DEADLINE=$(( $(date +%s) + 4*3600 ))
SELF=$$
now(){ date -Is; }

our_mains(){   # our main kernels: comm 'wolframscript' running equiv.wls or Tests/<suite>.wls
  local p pid c cl
  for p in /proc/[0-9]*; do
    pid=${p#/proc/}; [ "$pid" = "$SELF" ] && continue
    c=$(cat "$p/comm" 2>/dev/null) || continue
    [ "$c" = "wolframscript" ] || continue
    cl=$(tr '\0' ' ' < "$p/cmdline" 2>/dev/null)
    case "$cl" in *equiv.wls*|*factorization-and-loops/Tests/*|*" Tests/"*) echo "$pid";; esac
  done
}
procs_named(){ local p pid c cl
  for p in /proc/[0-9]*; do pid=${p#/proc/}
    c=$(cat "$p/comm" 2>/dev/null) || continue
    [ "$c" = "$1" ] || continue
    cl=$(tr '\0' ' ' < "$p/cmdline" 2>/dev/null)
    case "$cl" in *strip_pullback_perf/*) echo "$pid";; esac
  done; }
last_arg(){ tr '\0' '\n' < "/proc/$1/cmdline" 2>/dev/null | tail -1; }
affinity(){ grep -m1 Cpus_allowed_list "/proc/$1/status" 2>/dev/null | awk '{print $2}'; }
cputicks(){ awk '{print $14+$15}' "/proc/$1/stat" 2>/dev/null; }
descend(){ echo "$1"; local p pid
  for p in /proc/[0-9]*; do pid=${p#/proc/}
    [ "$(grep -m1 '^PPid' "$p/status" 2>/dev/null | awk '{print $2}')" = "$1" ] && echo "$pid"
  done; }

lane_alive(){ local p pid c cl n=0
  for p in /proc/[0-9]*; do pid=${p#/proc/}; [ "$pid" = "$SELF" ] && continue
    cl=$(tr '\0' ' ' < "$p/cmdline" 2>/dev/null) || continue
    case "$cl" in *watchdog*) continue;; esac
    case "$cl" in *strip_pullback_perf*) n=$((n+1));; esac
  done; echo $n; }
ANOM=""; note(){ ANOM="$ANOM; $1"; }

round=0
while [ "$(date +%s)" -lt $DEADLINE ]; do
  round=$((round+1)); ANOM=""; DONE_ALL=1; ENTRIES=0; NOW=$(date +%s)

  # ---------- global ----------
  MAINS=$(our_mains); NMAIN=$(echo "$MAINS" | grep -c '[0-9]')
  [ "$NMAIN" -gt 1 ] && note "MULTI-KERNEL: $NMAIN of our main kernels alive ($(echo $MAINS | tr '\n' ' '))"
  BADAFF=""
  for m in $MAINS; do for k in $(descend "$m"); do
      a=$(affinity "$k"); [ -z "$a" ] && continue
      [ "$a" = "10-17" ] || BADAFF="$BADAFF $k:$a"
  done; done
  [ -n "$BADAFF" ] && note "OFF-BAND CPU affinity (expected 10-17):$BADAFF"

  RPIDS=$(procs_named runner.sh); NRUN=$(echo "$RPIDS" | grep -c '[0-9]')
  CPIDS=$(procs_named chain.sh);  NCHAIN=$(echo "$CPIDS" | grep -c '[0-9]')
  SPIDS=$(procs_named suites.sh); NSUITE=$(echo "$SPIDS" | grep -c '[0-9]')
  ACTIVECASE=""; for r in $RPIDS; do ACTIVECASE=$(last_arg "$r"); done
  NALIVE=$(( $(lane_alive) + NMAIN ))

  # case logs retired before the last "replaced by" line in runner.log
  SUPERLIST=""
  if grep -q -a "replaced by" "$S/runner.log" 2>/dev/null; then
    CUT=$(grep -a -n "replaced by" "$S/runner.log" | tail -1 | cut -d: -f1)
    SUPERLIST=$(head -n "$CUT" "$S/runner.log" | grep -a -o 'log=[^ ]*' | sed 's/^log=//' | sort -u)
    # a log re-used by a later runner is NOT superseded
    for keep in $(tail -n +"$CUT" "$S/runner.log" | grep -a -o 'log=[^ ]*' | sed 's/^log=//'); do
      SUPERLIST=$(echo "$SUPERLIST" | grep -v -x -F "$keep")
    done
  fi

  # chain verdict / suite exit codes
  if grep -q -a "equivalence NOT green -> suites NOT started" "$S/runner.log" 2>/dev/null; then
    note "chain stopped: equivalence run was not green, suites NOT started"
  fi
  if [ -s "$S/suites_result.tsv" ]; then
    BAD=$(awk -F'\t' '$2!=0 {printf "%s(exit=%s,%ss) ", $1,$2,$3}' "$S/suites_result.tsv")
    [ -n "$BAD" ] && note "suite non-zero exit: $BAD"
  fi
  # hard Wolfram failures inside the per-suite logs
  if [ -d "$S/suites" ]; then
    for sl in "$S"/suites/*.log; do
      [ -e "$sl" ] || continue
      grep -q -a -i -e "not activated" -e "license-related" "$sl" && continue
      H=$(grep -a -o -E '\$Aborted|Segmentation|KERNELLOST|Throw::nocatch|Set::wrsym|Part::partw|Failed to open' "$sl" | sort -u | tr '\n' ' ')
      [ -n "$H" ] && note "$(basename "$sl"): $H"
    done
  fi

  # ---------- per entry ----------
  while IFS=$'\t' read -r FILE LABEL STALL; do
    [ "$FILE" = "output_file" ] && continue
    [ -z "$FILE" ] && continue
    ENTRIES=$((ENTRIES+1)); STALL=${STALL:-45}
    KEY=$(echo "$LABEL" | tr -c 'A-Za-z0-9_.-' '_')
    PREV=$W/.prev.$KEY; SEEN=$W/.seen.$KEY
    [ -f "$SEEN" ] || echo "$NOW" > "$SEEN"
    FIRSTSEEN=$(cat "$SEEN")
    ISRUNNER=0; case "$FILE" in *runner.log) ISRUNNER=1;; esac
    ISSUITES=0; case "$FILE" in *suites.log) ISSUITES=1;; esac
    SUPER=0
    [ -n "$SUPERLIST" ] && echo "$SUPERLIST" | grep -q -x -F "$FILE" && SUPER=1

    if [ ! -e "$FILE" ]; then
      WAIT=$((NOW-FIRSTSEEN))
      echo "$(now) round=$round $LABEL NOT-YET-CREATED waited=${WAIT}s alive=$NALIVE r=$NRUN c=$NCHAIN s=$NSUITE" >> "$HB"
      # only a problem if nothing upstream is still working toward it
      if [ "$NALIVE" -eq 0 ]; then
        note "$LABEL: $FILE never created and no process of this lane is alive"
      elif [ $WAIT -gt $((STALL*60*3)) ]; then
        note "$LABEL: $FILE still absent after ${WAIT}s"
      fi
      DONE_ALL=0
      continue
    fi

    SZ=$(stat -c %s "$FILE"); LN=$(wc -l < "$FILE"); AGE=$((NOW - $(stat -c %Y "$FILE")))
    HOLD=$(fuser "$FILE" 2>/dev/null | tr -s ' ')
    HCPU=0; for h in $HOLD; do t=$(cputicks "$h"); HCPU=$((HCPU + ${t:-0})); done
    PSZ=0; PCPU=0; [ -f "$PREV" ] && read -r PSZ PCPU < "$PREV"
    echo "$SZ $HCPU" > "$PREV"; DSZ=$((SZ-PSZ)); DCPU=$((HCPU-PCPU))
    MILE=$(grep -a -E "OLD chart pullback|NEW chart pullback|RECORD:|SUMMARY|all equal|ALL SUITES DONE|exit=" "$FILE" 2>/dev/null | tail -1)
    LAST=$(tail -c 300 "$FILE" 2>/dev/null | tr '\n' '|' | tail -c 160)
    LIC=0; grep -q -a -i -e "not activated" -e "license-related" "$FILE" && LIC=1

    if [ $SUPER -eq 0 ]; then
      grep -q -a "GAVE UP" "$FILE" && note "$LABEL: runner GAVE UP -- $(grep -a 'GAVE UP' "$FILE" | tail -1)"
      if [ $ISRUNNER -eq 1 ]; then
        EX=$(grep -a "finished exit=" "$FILE" | tail -1)
        [ -n "$EX" ] && case "$EX" in *"finished exit=0 "*) : ;; *) note "$LABEL: nonzero runner exit -- $EX";; esac
      fi
      # fatal signatures: broad on our own case logs, hard-list on runner/suites logs
      if [ $LIC -eq 0 ]; then
        if [ $ISRUNNER -eq 0 ] && [ $ISSUITES -eq 0 ]; then
          FS=$(grep -a -o -E '\$Aborted|Segmentation|KERNELLOST|Throw::nocatch|Set::wrsym|Part::partw|Failed to open|[A-Za-z]+::[a-z][A-Za-z0-9]*|!!' "$FILE" \
               | grep -v -E '^(General::stop)$' | sort -u | tr '\n' ' ')
        else
          FS=$(grep -a -o -E '\$Aborted|Segmentation|KERNELLOST|Throw::nocatch|Set::wrsym|Part::partw|Failed to open' "$FILE" | sort -u | tr '\n' ' ')
        fi
        [ -n "$FS" ] && note "$LABEL: fatal signature(s): $FS"
      fi
      if grep -q -a -E "no chart|artifact unreadable|all equal: False|both orderings timed out|comparison: False" "$FILE"; then
        note "$LABEL: design-sanity failure -- $(grep -a -E 'no chart|artifact unreadable|all equal: False|both orderings timed out|comparison: False' "$FILE" | tail -1)"
      fi
      if [ $AGE -gt $((STALL*60)) ]; then
        if [ -z "$HOLD" ] && [ "$NALIVE" -eq 0 ]; then
          note "$LABEL: silent ${AGE}s (> ${STALL}m), no holder, no process of this lane alive"
        elif [ -n "$HOLD" ] && [ "$DCPU" -eq 0 ]; then
          note "$LABEL: silent ${AGE}s (> ${STALL}m), holder [$HOLD] burned 0 CPU ticks this round"
        fi
      fi
    fi

    DONE=0
    [ $SUPER -eq 1 ] && DONE=1
    grep -q -a "all equal: True" "$FILE" && DONE=1
    [ $ISRUNNER -eq 1 ] && grep -q -a "finished exit=0 " "$FILE" && DONE=1
    [ $ISSUITES -eq 1 ] && grep -q -a "ALL SUITES DONE" "$FILE" && DONE=1
    [ $DONE -eq 1 ] || DONE_ALL=0

    echo "$(now) round=$round $LABEL bytes=$SZ(+$DSZ) lines=$LN age=${AGE}s holder=[${HOLD:-none}] dcpu=$DCPU lic=$LIC super=$SUPER done=$DONE mains=$NMAIN alive=$NALIVE r=$NRUN c=$NCHAIN s=$NSUITE milestone=[${MILE:-none}] tail=[$LAST]" >> "$HB"
  done < "$WL"

  if [ "$NALIVE" -eq 0 ] && [ $DONE_ALL -eq 0 ] \
     && ! grep -q -a -e "finished exit=" -e "GAVE UP" "$S/runner.log" 2>/dev/null; then
    note "no process of this lane alive, yet runner.log logged neither 'finished exit=' nor 'GAVE UP'"
  fi

  if [ -n "$ANOM" ]; then
    { echo "STATUS=ANOMALY"; echo "round=$round time=$(now)"; echo "detail=${ANOM#; }"; } > "$ST"
    echo "$(now) round=$round STATUS=ANOMALY ${ANOM#; }" >> "$HB"; exit 0
  elif [ $DONE_ALL -eq 1 ] && [ $ENTRIES -gt 0 ]; then
    { echo "STATUS=ALL-DRAINED"; echo "round=$round time=$(now)"; } > "$ST"
    echo "$(now) round=$round STATUS=ALL-DRAINED" >> "$HB"; exit 0
  else
    { echo "STATUS=OK"; echo "round=$round time=$(now) mains=$NMAIN alive=$NALIVE runners=$NRUN chain=$NCHAIN suites=$NSUITE active=$ACTIVECASE"; } > "$ST"
  fi
  sleep 300
done
{ echo "STATUS=TIMEOUT"; echo "round=$round time=$(now) -- 4 h cap reached, nothing drained"; } > "$ST"
echo "$(now) STATUS=TIMEOUT after $round rounds" >> "$HB"
