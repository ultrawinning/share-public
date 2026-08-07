# ultrawinning/share-public

**Public.** Served at https://ultrawinning.github.io/share-public/

## The rule

**Nothing lands here unless it was deliberately chosen to be public.**

This replaced `ultrawinning/share` on 2026-08-07. That repo was public *by default*: every session's
visual output went to it by standing instruction, so internal artefacts accumulated on a public host **by
design, not by carelessness**. On 2026-08-06 the monthly P&L was found being served from it live, and a
sweep then found **29 of ~40 previews carried real team names** — including individual dialer and setter
performance boards. The old repo is now a private archive; its URLs are dead and stay dead.

The default here is inverted. Empty until something is chosen.

## Before publishing, check it carries none of

- revenue / P&L / ad-spend figures
- real team member names
- client names or emails
- internal performance boards

**Product prices are fine** — HPF sells publicly, so $4,800 / $9,600 are not secrets. Revenue is.

## The guard

`.githooks-financial-guard.sh` blocks the money class at commit time on three signals:

1. a financial-looking path (`pnl`, `financial`, `revenue`, `payroll`, `margin`…)
2. P&L vocabulary — `gross revenue`, `net profit`, `ad spend`, `ROAS`, `cash collected`, `MRR`/`ARR`…
3. **three or more distinct figures ≥ $10,000** — the P&L signature. One big number is a package price;
   several is a report.

An in-file `share-financial-ok` marker overrides it, deliberately and visibly.

Install once:

```
bash install-financial-guard.sh
```

It splices **above** the hook's final `exit` (an appended block sits below the exit and never runs — that
mistake shipped a dead guard elsewhere), then self-tests block / allow / override and refuses to claim
success unless all three behave.

> ⚠️ **The guard does not catch team names, client data, or performance boards.**
> It catches money. Everything else is a human judgement, every time.

## Not for

Anything with a compliance or external dependency — privacy policies, terms, OAuth-registered URLs.
Those need a domain whose availability you control. A privacy policy lived on the old repo and went dark
the instant its visibility changed.

## Layout

- `previews/<name>/index.html` — visual previews
- `temp/<name>/index.html` — temporary docs for specific people; clean up after
