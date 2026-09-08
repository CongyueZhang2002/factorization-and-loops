#!/bin/bash
# Read-only watchdog for the strip_pullback_perf licence-retry run (v2:
# understands a case superseded by a later runner, e.g. rational -> ALL).
# Writes ONLY to heartbeat.log, state.txt and its own .prev cache.
# Never kills, restarts or runs Wolfram.  No pkill / pgrep -f.
S=/tmp/claude-1000/-home-maxzhang/9e941be4-c161-4634-89fb-8d0804f16b66/scratchpad/strip_pullback_perf
W=$S/watchdog
WL=$W/watchlist.tsv
HB=$W/heartbeat.log
ST=$W/state.txt
START=$(date +%s)
DEADLINE=$((START + 4*3600))
SELF=$$

now(){ date -Is; }

our_mains(){   # our task's main kernels: comm 'wolframscript' running equiv.wls
  local p pid c cl
  for p in /proc/[0-9]*; do
    pid=${p#/proc/}; [ "$pid" = "$SELF" ] && continue
    c=$(cat "$p/comm" 2>/dev/null) || continue
    [ "$c" = "wolframscript" ] || continue
    cl=$(tr '\0' ' ' < "$p/cmdline" 2>/dev/null)
    case "$cl" in *equiv.wls*) echo "$pid";; esac
  done
}
runner_pids(){
  local p pid c cl
  for p in /proc/[0-9]*; do
    pid=${p#/proc/}
    c=$(cat "$p/comm" 2>/dev/null) || continue
    [ "$c" = "runner.sh" ] || continue
    cl=$(tr '\0' ' ' < "$p/cmdline" 2>/dev/null)
    case "$cl" in *strip_pullback_perf/runner.sh*) echo "$pid";; esac
  done
}
runner_caselog(){ tr '\0' '\n' < "/proc/$1/cmdline" 2>/dev/null | tail -1; }
affinity(){ grep -m1 Cpus_allowed_list "/proc/$1/status" 2>/dev/null | awk '{print $2}'; }
cputicks(){ awk '{print $14+$15}' "/proc/$1/stat" 2>/dev/null; }
descend(){ echo "$1"; local p pid
  for p in /proc/[0-9]*; do pid=${p#/proc/}
    [ "$(grep -m1 '^PPid' "$p/status" 2>/dev/null | awk '{print $2}')" = "$1" ] && echo "$pid"
  done; }

ANOM=""
note(){ ANOM="$ANOM; $1"; }

round=0
while [ "$(date +%s)" -lt $DEADLINE ]; do
  round=$((round+1)); ANOM=""; DONE_ALL=1; ENTRIES=0

  MAINS=$(our_mains); NMAIN=$(echo "$MAINS" | grep -c '[0-9]')
  [ "$NMAIN" -gt 1 ] && note "MULTI-KERNEL: $NMAIN equiv.wls main kernels alive ($(echo $MAINS | tr '\n' ' '))"
  BADAFF=""
  for m in $MAINS; do for k in $(descend "$m"); do
      a=$(affinity "$k"); [ -z "$a" ] && continue
      [ "$a" = "10-17" ] || BADAFF="$BADAFF $k:$a"
  done; done
  [ -n "$BADAFF" ] && note "OFF-BAND CPU affinity (expected 10-17):$BADAFF"

  RPIDS=$(runner_pids); NRUN=$(echo "$RPIDS" | grep -c '[0-9]')
  ACTIVECASE=""
  for r in $RPIDS; do ACTIVECASE=$(runner_caselog "$r"); done
  REPLACED=0
  grep -q -a "replaced by" "$S/runner.log" 2>/dev/null && REPLACED=1

  while IFS=$'\t' read -r FILE LABEL STALL; do
    [ "$FILE" = "output_file" ] && continue
    [ -z "$FILE" ] && continue
    ENTRIES=$((ENTRIES+1)); STALL=${STALL:-45}
    PREV=$W/.prev.$(echo "$LABEL" | tr -c 'A-Za-z0-9_.-' '_')
    ISRUNNERLOG=0; case "$FILE" in *runner.log) ISRUNNERLOG=1;; esac

    # a case log that is neither runner.log nor the case the live runner is on,
    # once runner.log has announced a replacement, is superseded by design
    SUPER=0
    if [ $ISRUNNERLOG -eq 0 ] && [ $REPLACED -eq 1 ] && [ -n "$ACTIVECASE" ] && [ "$FILE" != "$ACTIVECASE" ]; then SUPER=1; fi

    if [ ! -e "$FILE" ]; then
      echo "$(now) round=$round $LABEL MISSING file=$FILE" >> "$HB"
      [ $SUPER -eq 1 ] || { note "$LABEL: output file missing"; DONE_ALL=0; }
      continue
    fi

    SZ=$(stat -c %s "$FILE"); LN=$(wc -l < "$FILE"); AGE=$(( $(date +%s) - $(stat -c %Y "$FILE") ))
    HOLD=$(fuser "$FILE" 2>/dev/null | tr -s ' ')
    HCPU=0; for h in $HOLD; do t=$(cputicks "$h"); HCPU=$((HCPU + ${t:-0})); done
    PSZ=0; PCPU=0; [ -f "$PREV" ] && read -r PSZ PCPU < "$PREV"
    echo "$SZ $HCPU" > "$PREV"; DSZ=$((SZ-PSZ)); DCPU=$((HCPU-PCPU))

    MILE=$(grep -a -E "OLD chart pullback|NEW chart pullback|RECORD:|SUMMARY|all equal" "$FILE" 2>/dev/null | tail -1)
    LAST=$(tail -c 300 "$FILE" 2>/dev/null | tr '\n' '|' | tail -c 160)
    LICNOISE=0; grep -q -a -i -e "not activated" -e "license-related" "$FILE" && LICNOISE=1

    if [ $SUPER -eq 0 ]; then
      grep -q -a "GAVE UP: no licence in 60 attempts" "$FILE" && \
        note "$LABEL: runner GAVE UP after 60 licence attempts"
      EXITLINE=$(grep -a "finished exit=" "$FILE" | tail -1)
      if [ -n "$EXITLINE" ]; then
        case "$EXITLINE" in *"finished exit=0 "*) : ;; *) note "$LABEL: nonzero runner exit -- $EXITLINE";; esac
      fi
      if [ $LICNOISE -eq 0 ]; then
        FS=$(grep -a -o -E '\$Aborted|Segmentation|KERNELLOST|Throw::nocatch|Set::wrsym|Part::partw|Failed to open|[A-Za-z]+::[a-z][A-Za-z0-9]*|!!' "$FILE" \
             | grep -v -E '^(General::stop|Syntax::newl)$' | sort -u | tr '\n' ' ')
        [ -n "$FS" ] && note "$LABEL: fatal signature(s): $FS"
      fi
      if grep -q -a -E "no chart|artifact unreadable|all equal: False|both orderings timed out|comparison: False" "$FILE"; then
        note "$LABEL: design-sanity failure -- $(grep -a -E 'no chart|artifact unreadable|all equal: False|both orderings timed out|comparison: False' "$FILE" | tail -1)"
      fi
      if [ $AGE -gt $((STALL*60)) ]; then
        if [ -z "$HOLD" ] && [ "$NRUN" -eq 0 ]; then
          note "$LABEL: silent ${AGE}s (> ${STALL}m), no holder, no runner alive"
        elif [ -n "$HOLD" ] && [ "$DCPU" -eq 0 ]; then
          note "$LABEL: silent ${AGE}s (> ${STALL}m), holder [$HOLD] burned 0 CPU ticks this round"
        fi
      fi
    fi

    CASEDONE=0
    grep -q -a "all equal: True" "$FILE" && CASEDONE=1
    [ $ISRUNNERLOG -eq 1 ] && grep -q -a "finished exit=0 " "$FILE" && CASEDONE=1
    [ $SUPER -eq 1 ] && CASEDONE=1
    [ $CASEDONE -eq 1 ] || DONE_ALL=0

    echo "$(now) round=$round $LABEL bytes=$SZ(+$DSZ) lines=$LN age=${AGE}s holder=[${HOLD:-none}] dcpu=$DCPU lic=$LICNOISE super=$SUPER mains=$NMAIN runners=$NRUN milestone=[${MILE:-none}] tail=[$LAST]" >> "$HB"
  done < "$WL"

  if [ "$NRUN" -eq 0 ] && [ $DONE_ALL -eq 0 ] \
     && ! grep -q -a -e "finished exit=" -e "GAVE UP" "$S/runner.log" 2>/dev/null; then
    note "runner.sh is gone but runner.log logged neither 'finished exit=' nor 'GAVE UP'"
  fi

  if [ -n "$ANOM" ]; then
    { echo "STATUS=ANOMALY"; echo "round=$round time=$(now)"; echo "detail=${ANOM#; }"; } > "$ST"
    echo "$(now) round=$round STATUS=ANOMALY ${ANOM#; }" >> "$HB"; exit 0
  elif [ $DONE_ALL -eq 1 ] && [ $ENTRIES -gt 0 ]; then
    { echo "STATUS=ALL-DRAINED"; echo "round=$round time=$(now)"; } > "$ST"
    echo "$(now) round=$round STATUS=ALL-DRAINED" >> "$HB"; exit 0
  else
    { echo "STATUS=OK"; echo "round=$round time=$(now) mains=$NMAIN runners=$NRUN active=$ACTIVECASE"; } > "$ST"
  fi
  sleep 300
done
{ echo "STATUS=TIMEOUT"; echo "round=$round time=$(now) -- 4 h cap reached, nothing drained"; } > "$ST"
echo "$(now) STATUS=TIMEOUT after $round rounds" >> "$HB"
