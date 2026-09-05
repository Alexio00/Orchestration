# Orchestration

Clean-slate development of **General 5** — a small set of rules that helps an AI model complete work reliably without imposing a complex orchestration framework.

## Status

**Draft.** General 5 is not released or activated.

## Product boundary

- One agent is the default.
- Tools, planning, and subagents are used only when they add clear value.
- Product decisions belong to the Product Owner; technical execution stays within the approved scope.
- The rules should remain short enough to inspect, understand, and adapt.
- Complexity is added only after a demonstrated failure that a simpler rule cannot address.

## Repository boundary

This repository contains only the new General 5 line.

Previous versions, modules, research, releases, and implementation history remain in the read-only reference repository: [Alexio00/Orchestration_old](https://github.com/Alexio00/Orchestration_old). Nothing from that repository is normative here unless it is deliberately selected and rewritten for General 5.

## Current artifact

- [GENERAL-5.md](GENERAL-5.md) — working draft of the minimal instruction core.

## Development rule

Draft → verify → integrate → release → activate.

Each transition is explicit. Creating or editing a draft does not release or activate it.
