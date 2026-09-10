# A Wolfram script can exit zero after a parse error or before FTReport.
# Call only after recording the process exit code.
ft_wolfram_test_log_valid() {
  local log_file="$1" test_file="$2"
  if grep -Eq 'ToExpression::sntx|Syntax::sntx|Get::noopen' "$log_file"; then
    return 1
  fi
  if grep -q 'FTReport\[' "$test_file" &&
     ! grep -Eq '[1-9][0-9]* assertions, 0 failed' "$log_file"; then
    return 1
  fi
}
