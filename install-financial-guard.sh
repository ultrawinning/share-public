#!/bin/bash
# Installs the financial-content guard into this repo's pre-commit hook.
# Idempotent. Splices BEFORE the hook's final `exit $FAIL` — never appends after
# it, because an appended block sits below the exit and never runs (that exact
# mistake shipped a dead guard in another repo on 2026-07-31).
set -euo pipefail

REPO="/Users/emil/Code/share-public"
HOOK="$REPO/.git/hooks/pre-commit"
GUARD="$REPO/.githooks-financial-guard.sh"

[ -f "$GUARD" ] || { echo "❌ guard script missing: $GUARD"; exit 1; }
[ -f "$HOOK" ]  || { echo "❌ pre-commit hook missing: $HOOK"; exit 1; }

if grep -q 'githooks-financial-guard' "$HOOK"; then
  echo "✅ already installed — nothing to do."
  exit 0
fi

grep -q '^exit \$FAIL' "$HOOK" || {
  echo "❌ could not find the hook's final 'exit \$FAIL' line — refusing to guess placement."
  exit 1
}

cp "$HOOK" "$HOOK.bak-$(date +%Y-%m-%d)"

awk '
/^exit \$FAIL/ && !inserted {
  print "GUARD=\"$(git rev-parse --show-toplevel)/.githooks-financial-guard.sh\""
  print "if [ -f \"$GUARD\" ]; then"
  print "  . \"$GUARD\" || FAIL=1"
  print "else"
  print "  echo \"BLOCKED: financial guard missing at $GUARD - refusing to commit to a PUBLIC repo without it.\""
  print "  FAIL=1"
  print "fi"
  print ""
  inserted=1
}
{ print }
' "$HOOK.bak-$(date +%Y-%m-%d)" > "$HOOK"

chmod +x "$HOOK" "$GUARD"

echo "── placement check (guard must appear ABOVE the exit) ──"
grep -n 'GUARD=\|^exit \$FAIL' "$HOOK"

# NOTE: the probes below write NEW files. `git add -f` on a tracked, UNMODIFIED file
# stages nothing, so `git diff --cached` comes back empty and the guard correctly
# passes on an empty set — which looks like a broken guard but is a broken TEST.
# That mistake produced a false "GUARD NOT BEHAVING AS EXPECTED" on 2026-08-07.
cd "$REPO"
PROBE="previews/_guardprobe"
mkdir -p "$PROBE"

echo
echo "── TEST 1: financial content (expect BLOCKED, exit 1) ──"
printf '<html><p>Gross revenue $101,790</p><p>$103,923</p><p>$102,683</p></html>\n' > "$PROBE/index.html"
git add -f "$PROBE/index.html" >/dev/null 2>&1
set +e; "$HOOK" >/tmp/_g1.txt 2>&1; RC1=$?; set -e
git reset -q
sed 's/^/    /' /tmp/_g1.txt | head -4
echo "    exit code: $RC1   (want 1)"

echo
echo "── TEST 2: product prices (expect ALLOWED, exit 0) ──"
printf '<html><p>Coaching package $4,800</p><p>Premium $9,600</p></html>\n' > "$PROBE/index.html"
git add -f "$PROBE/index.html" >/dev/null 2>&1
set +e; "$HOOK" >/tmp/_g2.txt 2>&1; RC2=$?; set -e
git reset -q
sed 's/^/    /' /tmp/_g2.txt | head -4
echo "    exit code: $RC2   (want 0)"

echo
echo "── TEST 3: the override escape hatch (expect ALLOWED, exit 0) ──"
printf '<!-- share-financial-ok -->\n<html><p>Gross revenue $101,790</p><p>$103,923</p><p>$102,683</p></html>\n' > "$PROBE/index.html"
git add -f "$PROBE/index.html" >/dev/null 2>&1
set +e; "$HOOK" >/tmp/_g3.txt 2>&1; RC3=$?; set -e
git reset -q
echo "    exit code: $RC3   (want 0)"

rm -rf "$PROBE"

echo
if [ "$RC1" = "1" ] && [ "$RC2" = "0" ] && [ "$RC3" = "0" ]; then
  echo "✅ GUARD WORKING — blocks financials, allows product prices, honours the override."
else
  echo "❌ GUARD NOT BEHAVING AS EXPECTED — do not make this repo public yet."
  echo "   want RC1=1 RC2=0 RC3=0 · got RC1=$RC1 RC2=$RC2 RC3=$RC3"
  exit 1
fi
