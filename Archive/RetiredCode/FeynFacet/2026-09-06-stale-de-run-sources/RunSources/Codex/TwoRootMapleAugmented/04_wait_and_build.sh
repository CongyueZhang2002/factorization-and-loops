#!/usr/bin/env bash
set -u

artifact_dir="/home/maxzhang/factorization-and-loops/Codex/TwoRootMapleAugmented"
cd "$artifact_dir" || exit 70

if [[ -f 04_build_augmented_cf254.time && ! -f 04_build_augmented_cf254.attempt1.time ]]; then
  mv 04_build_augmented_cf254.time 04_build_augmented_cf254.attempt1.time
  mv 04_build_augmented_cf254.stdout.log 04_build_augmented_cf254.attempt1.stdout.log
  mv 04_build_augmented_cf254.stderr.log 04_build_augmented_cf254.attempt1.stderr.log
fi

if [[ -f 04_license_wait.log && ! -f 04_license_wait.attempt1.log ]]; then
  mv 04_license_wait.log 04_license_wait.attempt1.log
fi

: > 04_license_wait.log
available=0
for attempt in $(seq 1 120); do
  available_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
  printf 'attempt=%d timestamp=%s\n' "$attempt" "$(date --iso-8601=seconds)" \
    >> 04_license_wait.log
  printf 'memory_available_kb=%s\n' "$available_kb" >> 04_license_wait.log
  if [[ "$available_kb" -lt 10485760 ]]; then
    printf 'result=WAITING_FOR_MEMORY\n' >> 04_license_wait.log
    sleep 30
    continue
  fi
  if wolframscript -code 'Exit[0]' \
      > 04_license_probe.stdout.tmp 2> 04_license_probe.stderr.tmp; then
    printf 'result=AVAILABLE\n' >> 04_license_wait.log
    available=1
    break
  fi
  printf 'result=UNAVAILABLE\n' >> 04_license_wait.log
  sed 's/^/stderr=/' 04_license_probe.stderr.tmp >> 04_license_wait.log
  sleep 30
done

if [[ "$available" -ne 1 ]]; then
  printf 'queue_result=NO_LICENSE_WITHIN_3600_SECONDS\n' >> 04_license_wait.log
  exit 75
fi

/usr/bin/time \
  -f 'wall_seconds=%e\nuser_seconds=%U\nsystem_seconds=%S\nmax_rss_kb=%M\nexit_status=%x' \
  -o 04_build_augmented_cf254.time \
  timeout --signal=TERM --kill-after=30s 3600s \
  wolframscript -file 04_build_augmented_cf254.wls \
  > 04_build_augmented_cf254.stdout.log \
  2> 04_build_augmented_cf254.stderr.log
