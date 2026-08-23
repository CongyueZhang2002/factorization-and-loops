#!/usr/bin/env bash
set -euo pipefail

artifact_dir="/home/maxzhang/factorization-and-loops/Codex/TwoRootMapleAugmented"
output="FILES_CREATED.tsv"
temporary="${output}.tmp"

cd "$artifact_dir"
printf 'file\tbytes\tsha256\n' > "$temporary"

while IFS= read -r -d '' file; do
  name="${file#./}"
  bytes=$(stat -c '%s' "$file")
  digest=$(sha256sum "$file" | awk '{print $1}')
  printf '%s\t%s\t%s\n' "$name" "$bytes" "$digest" >> "$temporary"
done < <(find . -maxdepth 1 -type f \
  ! -name "$output" ! -name "$temporary" -print0 | sort -z)

printf '%s\t%s\t%s\n' "$output" 'self' 'self-referential' >> "$temporary"
mv "$temporary" "$output"
