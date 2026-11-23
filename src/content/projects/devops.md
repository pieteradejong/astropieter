---
aiGenerated: true
title: "devops"
description: "The security and hygiene tooling behind a whole dev workspace: a commit/push gate in every repo, one reusable CI workflow they all call, a weekly security and privacy audit, a read-only audit of every local repo, and the policy docs they enforce"
techStack: ["Bash", "Python", "GitHub Actions", "gitleaks", "gh CLI"]
githubUrl: "https://github.com/pieteradejong/devops"
keyFeatures:
  [
    "A global git hook gate that blocks secrets, personal values, forbidden files and missing CI before a commit or push leaves the machine, stricter when the remote is public",
    "One reusable GitHub Actions workflow (full-history gitleaks plus the gate in CI mode) that every repo calls, so the rules change in one place",
    "A weekly audit across every local repo, every GitHub repo (cloned or not), the machine and the account, opening with what changed since last week",
  ]
technicalHighlights:
  [
    "The audits are read-only by construction: every git call goes through one wrapper with --no-optional-locks, and reports refuse to land inside a git repository",
    "Private values (exact personal strings, the do-not-touch list) live in a separate private repo found through one variable; the public code ships only example configs, and the skip list fails closed when absent",
    "CI judges each push under both the new and the previous rules, so a commit that weakens the gate is still checked by the rules it replaces",
    "Bash 3.2 compatible and tested offline with stub gh, git and gitleaks: 11 suites run on every push",
  ]
impact: "111 repositories call the same reusable security workflow, and every commit and push on the machine passes the same gate."
tags: ["security", "devops", "github-actions", "bash", "privacy"]
status: "active"
startDate: "2026-09"
heroAlt: "Audit dashboard rendered from sample data: five summary tiles and a line chart of weekly FAIL and WARN counts falling over four weeks"
hero: "../../assets/projects/devops.png"
syncedFrom: "devops@b591f18688df1eafd23d884413dd1c3a04b8132e"
---

The tooling that keeps a workspace of more than a hundred personal repos from leaking a secret or
a personal detail. It also enforces the same baseline everywhere: a LICENSE, security CI, pinned
dependencies and a changelog. It started inside a dotfiles repo and moved here once it governed
every repo rather than one machine.

The screenshot uses invented sample data. Real audit reports name real repositories and never
leave the machine.
