#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# FINANCIAL-CONTENT GUARD for the PUBLIC ultrawinning/share repo.
#
# WHY THIS EXISTS: on 2026-08-06 HPF's monthly P&L was found being served
# publicly at https://ultrawinning.github.io/share/previews/pnl-mar-may-2026/
# (verified live: HTTP 200, $101,790 / $103,923 / $102,683 / $91,000).
# Root cause was structural, not carelessness — ~/.claude/CLAUDE.md instructs
# every Claude session to publish visual work to this repo, so internal
# business artefacts land on a public host BY DESIGN. A one-time cleanup would
# have recurred. This is the mechanism half (rule-25).
#
# THE LINE IT ENFORCES: product PRICES are fine (HPF sells publicly — $1,250,
# $4,800, $5,000, $9,600 are not secrets). REVENUE, P&L, ad spend and expense
# detail are not.
#
# Sourced by .git/hooks/pre-commit. Exit 1 blocks the commit.
# ─────────────────────────────────────────────────────────────────────────────

FIN_FAIL=0
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)
[ -z "$STAGED_FILES" ] && return 0 2>/dev/null || true

# Escape hatch: a file may carry `share-financial-ok` (e.g. in an HTML comment)
# when the figures are deliberately public. Must be a conscious act, in-file.
OVERRIDE_RE='share-financial-ok'

while IFS= read -r file; do
  [ -f "$file" ] || continue
  case "$file" in
    *.html|*.md|*.htm|*.txt|*.json|*.csv) ;;
    *) continue ;;
  esac

  if grep -q "$OVERRIDE_RE" "$file" 2>/dev/null; then
    echo "ℹ️  financial-guard: '$file' carries share-financial-ok — allowed."
    continue
  fi

  # ── Signal 1: filename/path smells of financial reporting ────────────────
  if echo "$file" | grep -qiE '(^|/)(pnl|p-and-l|profit|financial|finance|revenue|expenses|payroll|margin)'; then
    echo "❌ BLOCKED (financial-guard): '$file'"
    echo "   Path indicates financial reporting. This repo is PUBLIC."
    FIN_FAIL=1
    continue
  fi

  # ── Signal 2: P&L vocabulary ─────────────────────────────────────────────
  if grep -qiE '(gross|net) (revenue|profit|margin|cash)|profit *(and|&|&amp;) *loss|\bP&L\b|\bP&amp;L\b|total (revenue|expenses)|cash collected|contracted value|\bMRR\b|\bARR\b|burn rate|ad spend|\bROAS\b' "$file" 2>/dev/null; then
    echo "❌ BLOCKED (financial-guard): '$file'"
    echo "   Contains P&L / revenue / ad-spend vocabulary. This repo is PUBLIC."
    FIN_FAIL=1
    continue
  fi

  # ── Signal 3: the P&L SIGNATURE — 3+ distinct figures >= $10,000 ─────────
  # One big number is a mockup or a package price. Several is a financial report.
  BIGCOUNT=$(grep -oE '\$[0-9]{2,3},[0-9]{3}' "$file" 2>/dev/null | sort -u | wc -l | tr -d ' ')
  if [ "${BIGCOUNT:-0}" -ge 3 ]; then
    echo "❌ BLOCKED (financial-guard): '$file'"
    echo "   Contains $BIGCOUNT distinct figures >= \$10,000 — reads as a financial report."
    echo "   Product prices are fine; revenue tables are not."
    FIN_FAIL=1
    continue
  fi
done <<< "$STAGED_FILES"

if [ "$FIN_FAIL" = "1" ]; then
  echo ""
  echo "──────────────────────────────────────────────────────────────────"
  echo " ultrawinning/share is a PUBLIC GitHub Pages site."
  echo " Internal financials must not be published here."
  echo ""
  echo " If the figures are genuinely safe to publish, add the marker"
  echo " 'share-financial-ok' inside the file (e.g. an HTML comment) and"
  echo " re-commit. Make that a deliberate decision, not a reflex."
  echo "──────────────────────────────────────────────────────────────────"
fi

return $FIN_FAIL 2>/dev/null || exit $FIN_FAIL
