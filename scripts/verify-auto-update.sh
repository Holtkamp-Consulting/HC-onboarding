#!/bin/bash
# Regression checks for the "Auto-update service" section of install.sh.
# This repo has no test framework or CI; run manually after touching that
# section: ./scripts/verify-auto-update.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SH="$REPO_ROOT/install.sh"
FAIL=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1" >&2; FAIL=1; }

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# 1. install.sh is syntactically valid.
if bash -n "$INSTALL_SH"; then
  pass "install.sh is syntactically valid"
else
  fail "install.sh failed bash -n"
fi

# 2. BREW_BIN assignment must not abort the script under set -e when brew is missing.
#    Resolve bash's own absolute path first so overriding PATH below (to
#    simulate "brew missing") doesn't also break bash's own command lookup.
bash_bin="$(command -v bash)"
if PATH="$tmpdir" "$bash_bin" -c 'set -euo pipefail; BREW_BIN="$(command -v brew || true)"; echo "survived: BREW_BIN=[$BREW_BIN]"' >/dev/null; then
  pass "BREW_BIN assignment does not abort under set -e when brew is missing"
else
  fail "BREW_BIN assignment aborted the script when brew was missing"
fi

# 3. Generated CASKS array must round-trip cask names containing spaces/special chars.
test_casks=("bitwarden" "displaylink" "weird cask" 'quo"te')
generated="$(printf '  %q\n' "${test_casks[@]}")"
eval "reparsed=($generated)"
if [[ "${#reparsed[@]}" -eq "${#test_casks[@]}" ]]; then
  pass "CASKS array generation preserves element count (${#test_casks[@]} in, ${#reparsed[@]} out)"
else
  fail "CASKS array generation corrupted element count (${#test_casks[@]} in, ${#reparsed[@]} out)"
fi

# 4. End-to-end: stub brew/launchctl, run the real "Auto-update service"
#    section straight out of install.sh against a fake HOME, and confirm the
#    generated artifacts are valid and bootout always precedes bootstrap.
stub_dir="$tmpdir/bin"
mkdir -p "$stub_dir"
calls_log="$tmpdir/calls.log"
: > "$calls_log"

cat > "$stub_dir/launchctl" <<STUB
#!/bin/bash
echo "launchctl \$*" >> "$calls_log"
exit 0
STUB
cat > "$stub_dir/brew" <<'STUB'
#!/bin/bash
echo "/fake/brew"
STUB
chmod +x "$stub_dir/launchctl" "$stub_dir/brew"

# Extract the section verbatim so this always exercises the current code
# rather than a hand-copied duplicate that could drift out of sync.
section="$(sed -n '/^# ── Auto-update service ─/,/^# ── Done ─/p' "$INSTALL_SH" | sed '$d')"
if [[ -z "$section" ]]; then
  fail "could not locate the 'Auto-update service' section in install.sh (header comment renamed?)"
else
  {
    echo 'set -euo pipefail'
    echo 'mkdir -p "$HOME"'
    echo 'print_step() { :; }'
    echo 'CASKS=(bitwarden displaylink)'
    printf '%s\n' "$section"
  } > "$tmpdir/run-section.sh"

  run_once() {
    HOME="$tmpdir/home" PATH="$stub_dir:$PATH" bash "$tmpdir/run-section.sh"
  }

  run_once
  run_once

  auto_update_script="$tmpdir/home/Library/Application Support/HC-onboarding/auto-update.sh"
  auto_update_plist="$tmpdir/home/Library/LaunchAgents/com.holtkamp-consulting.hc-onboarding.autoupdate.plist"

  if bash -n "$auto_update_script"; then
    pass "generated auto-update.sh is syntactically valid"
  else
    fail "generated auto-update.sh failed bash -n"
  fi

  if command -v plutil &>/dev/null; then
    if plutil -lint "$auto_update_plist" >/dev/null; then
      pass "generated plist passes plutil -lint"
    else
      fail "generated plist failed plutil -lint"
    fi
  fi

  bootout_count="$(grep -c '^launchctl bootout' "$calls_log" || true)"
  bootstrap_count="$(grep -c '^launchctl bootstrap' "$calls_log" || true)"
  if [[ "$bootout_count" -eq 2 && "$bootstrap_count" -eq 2 ]]; then
    pass "bootout and bootstrap each attempted on both runs (idempotent re-registration)"
  else
    fail "expected 2 bootout + 2 bootstrap calls, got $bootout_count bootout / $bootstrap_count bootstrap"
  fi

  # Ordering: every bootstrap call must be preceded by an unmatched bootout call.
  if awk '
    /^launchctl bootout/ { pending++ }
    /^launchctl bootstrap/ {
      if (pending < 1) { bad=1 }
      else { pending-- }
    }
    END { exit bad ? 1 : 0 }
  ' "$calls_log"; then
    pass "bootout always precedes its matching bootstrap"
  else
    fail "bootout/bootstrap ordering violated"
  fi
fi

echo ""
if [[ "$FAIL" -eq 0 ]]; then
  echo "All checks passed."
else
  echo "One or more checks failed." >&2
  exit 1
fi
