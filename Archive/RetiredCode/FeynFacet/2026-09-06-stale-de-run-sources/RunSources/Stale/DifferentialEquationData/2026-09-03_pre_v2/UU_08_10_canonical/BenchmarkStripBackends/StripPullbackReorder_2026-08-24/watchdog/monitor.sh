#!/bin/bash
# Read-only watchdog for the strip_pullback_perf licence-retry run.
# Writes ONLY to heartbeat.log, state.txt and its own .prev cache.
# Never kills, restarts or runs Wolfram.  No pkill / pgrep -f.
W=/tmp/claude-1000/-home-maxzhang/9e941be4-c161-4634-89fb-8d0804f16b66/scratchpad/strip_pullback_perf/watchdog
WL=$W/watchlist.tsv
HB=$W/heartbeat.log
ST=$W/state.txt
MAXROUNDS=48          # 48 x 5 min = 4 h
SELF=$$

now(){ date -Is; }

# --- exact-name process helpers (no pgrep -f: it would self-match) ----------
# our task's main kernels = comm 'wolframscript' whose cmdline mentions equiv.wls
our_mains(){
  local p pid c cl
  for p in /proc/[0-9]*; do
    pid=${p#/proc/}
    [ "$pid" = "$SELF" ] && continue
    c=$(cat "$p/comm" 2>/dev/null) || continue
    [ "$c" = "wolframscript" ] || continue
    cl=$(tr '\0' ' ' < "$p/cmdline" 2>/dev/null)
    case "$cl" in *equiv.wls*) echo "$pid";; esac
  done
}
runner_alive(){
  local p pid c cl
  for p in /proc/[0-9]*; do
    pid=${p#/proc/}
    c=$(cat "$p/comm" 2>/dev/null) || continue
    [ "$c" = "runner.sh" ] || continue
    cl=$(tr '\0' ' ' < "$p/cmdline" 2>/dev/null)
    case "$cl" in *strip_pullback_perf/runner.sh*) echo "$pid";; esac
  done
}
affinity(){ grep -m1 Cpus_allowed_list "/proc/$1/status" 2>/dev/null | awk '{print $2}'; }
cputicks(){ awk '{print $14+$15}' "/proc/$1/stat" 2>/dev/null; }
descend(){ # pid -> itself plus WolframKernel children
  echo "$1"
  local p pid
  for p in /proc/[0-9]*; do
    pid=${p#/proc/}
    if [ "$(grep -m1 '^PPid' "$p/status" 2>/dev/null | awk '{print $2}')" = "$1" ]; then echo "$pid"; fi
  done
}

ANOM=""
note(){ ANOM="$ANOM; $1"; }

round=0
while [ $round -lt $MAXROUNDS ]; do
  round=$((round+1))
  ANOM=""
  DONE_ALL=1
  ENTRIES=0

  # ---- global checks (once per round) -------------------------------------
  MAINS=$(our_mains); NMAIN=$(echo "$MAINS" | grep -c '[0-9]')
  if [ "$NMAIN" -gt 1 ]; then
    note "MULTI-KERNEL: $NMAIN of our equiv.wls main kernels alive ($(echo $MAINS|tr '\n' ' '))"
  fi
  BADAFF=""
  for m in $MAINS; do
    for k in $(descend "$m"); do
      a=$(affinity "$k")
      [ -z "$a" ] && continue
      [ "$a" = "10-17" ] || BADAFF="$BADAFF $k:$a"
    done
  done
  [ -n "$BADAFF" ] && note "OFF-BAND CPU affinity (expected 10-17):$BADAFF"
  RUNNERS=$(runner_alive); NRUN=$(echo "$RUNNERS" | grep -c '[0-9]')

  # ---- per-entry ----------------------------------------------------------
  while IFS=$'\t' read -r FILE LABEL STALL; do
    [ "$FILE" = "output_file" ] && continue
    [ -z "$FILE" ] && continue
    ENTRIES=$((ENTRIES+1))
    STALL=${STALL:-45}
    PREV=$W/.prev.$(echo "$LABEL" | tr -c 'A-Za-z0-9_.-' '_')

    if [ ! -e "$FILE" ]; then
      echo "$(now) round=$round $LABEL MISSING file=$FILE" >> "$HB"
      note "$LABEL: output file missing"
      DONE_ALL=0
      continue
    fi

    SZ=$(stat -c %s "$FILE"); LN=$(wc -l < "$FILE"); AGE=$(( $(date +%s) - $(stat -c %Y "$FILE") ))
    HOLD=$(fuser "$FILE" 2>/dev/null | tr -s ' ')
    # CPU of the holders, to tell "silent but computing" from "silent and idle"
    HCPU=0; for h in $HOLD; do t=$(cputicks "$h"); HCPU=$((HCPU + ${t:-0})); done
    PSZ=0; PCPU=0
    [ -f "$PREV" ] && read -r PSZ PCPU < "$PREV"
    echo "$SZ $HCPU" > "$PREV"
    DSZ=$((SZ-PSZ)); DCPU=$((HCPU-PCPU))

    MILE=$(grep -a -n -E "OLD chart pullback|NEW chart pullback|RECORD:|SUMMARY|all equal" "$FILE" 2>/dev/null | tail -1)
    LAST=$(tail -c 400 "$FILE" 2>/dev/null | tr '\n' '|' | tail -c 200)

    LICNOISE=0
    grep -q -a -i -e "not activated" -e "license-related" "$FILE" && LICNOISE=1

    # (a) runner gave up / bad exit
    if grep -q -a "GAVE UP: no licence in 60 attempts" "$FILE"; then
      note "$LABEL: runner GAVE UP after 60 licence attempts"
    fi
    EXITLINE=$(grep -a "finished exit=" "$FILE" | tail -1)
    if [ -n "$EXITLINE" ]; then
      case "$EXITLINE" in
        *"finished exit=0 "*) : ;;
        *) note "$LABEL: nonzero runner exit -- $EXITLINE" ;;
      esac
    fi

    # (b) fatal Wolfram signatures, only once past the licence gate
    if [ $LICNOISE -eq 0 ]; then
      FS=$(grep -a -o -E '\$Aborted|Segmentation|KERNELLOST|Throw::nocatch|Set::wrsym|Part::partw|Failed to open|[A-Za-z]+::[a-z][A-Za-z0-9]*|!!' "$FILE" \
           | grep -v -E '^(General::stop|Syntax::newl)$' | sort -u | tr '\n' ' ')
      [ -n "$FS" ] && note "$LABEL: fatal signature(s): $FS"
    fi

    # (d) design sanity
    if grep -q -a -E "no chart|artifact unreadable|all equal: False|both orderings timed out|comparison: False" "$FILE"; then
      note "$LABEL: design-sanity failure -- $(grep -a -E 'no chart|artifact unreadable|all equal: False|both orderings timed out|comparison: False' "$FILE" | tail -1)"
    fi

    # (c) stall: silent past stall_minutes AND nobody is working on it
    if [ $AGE -gt $((STALL*60)) ]; then
      if [ -z "$HOLD" ] && [ "$NRUN" -eq 0 ]; then
        note "$LABEL: silent ${AGE}s (> ${STALL}m), no holder, runner gone"
      elif [ -n "$HOLD" ] && [ "$DCPU" -eq 0 ]; then
        note "$LABEL: silent ${AGE}s (> ${STALL}m) and holder [$HOLD] burned 0 CPU ticks this round"
      fi
    fi

    # completion
    CASEDONE=0
    grep -q -a "all equal: True" "$FILE" && CASEDONE=1
    case "$FILE" in
      *runner.log) grep -q -a "finished exit=0 " "$FILE" && CASEDONE=1 ;;
    esac
    [ $CASEDONE -eq 1 ] || DONE_ALL=0

    echo "$(now) round=$round $LABEL bytes=$SZ(+$DSZ) lines=$LN age=${AGE}s holder=[${HOLD:-none}] dcpu=$DCPU lic_noise=$LICNOISE mains=$NMAIN runner=$NRUN milestone=[${MILE:-none}] tail=[$LAST]" >> "$HB"
  done < "$WL"

  # runner vanished with no completion line = it was killed
  if [ "$NRUN" -eq 0 ] && [ $DONE_ALL -eq 0 ] \
     && ! grep -q -a -e "finished exit=" -e "GAVE UP" "$W/../runner.log" 2>/dev/null; then
    note "runner.sh process is gone but runner.log logged neither 'finished exit=' nor 'GAVE UP'"
  fi

  if [ -n "$ANOM" ]; then
    { echo "STATUS=ANOMALY"; echo "round=$round time=$(now)"; echo "detail=${ANOM#; }"; } > "$ST"
    echo "$(now) round=$round STATUS=ANOMALY ${ANOM#; }" >> "$HB"
    exit 0
  elif [ $DONE_ALL -eq 1 ] && [ $ENTRIES -gt 0 ]; then
    { echo "STATUS=ALL-DRAINED"; echo "round=$round time=$(now)"; } > "$ST"
    echo "$(now) round=$round STATUS=ALL-DRAINED" >> "$HB"
    exit 0
  else
    { echo "STATUS=OK"; echo "round=$round time=$(now) mains=$NMAIN runner=$NRUN"; } > "$ST"
  fi
  sleep 300
done
{ echo "STATUS=TIMEOUT"; echo "round=$round time=$(now) -- 4 h cap reached, nothing drained"; } > "$ST"
echo "$(now) STATUS=TIMEOUT after $round rounds" >> "$HB"
