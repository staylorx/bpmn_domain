# README Decision — Recommendation (bpmn_domain)

Task t_bee74f83 — evaluate and recommend; feeds decide (t_66b651fb) and record
(t_05b42f3f). Sources: README-research-summary.md (t_d35c8090) and
README-restatement-options.md (t_e7eaa37d).

## Recommendation

TRIM README.md to orientation-only (Options A / A-lite). Do not keep it as a sanctioned
deviation. The public-facing seam argument — the only substantive case for keeping —
collapses here because the package sets `publish_to: none`: there is no pub.dev consumer
surface for the README to "seam" for. The genuine seam is served by the one thing the bible
explicitly permits (§4): a short error-style declaration naming the
`Either<WorkflowFailure, T>` contract near the top. Keeping the heavy sections would
preserve exactly the second-truth copies the doctrine flags, with zero seam value.

## Why trim, not keep

1. The doctrine is unambiguous. §1.3 D.R.Y.: a second copy is a second truth the moment
   the first changes; READMEs orient, carry no rules or architecture. §2.7: executable code
   lives in tests/example/, never in README. Every heavy section is a mirror: the layout
   tree of the file system, the dependency table of pubspec, the entity tables of 100+
   doc-comments, the roadmap `Either<...>` snippets of an API no code implements. None is
   orientation.
2. The seam argument does not hold here. It rests on "a consumer sees the seam at first
   contact," but a consumer exists only for a published package. With `publish_to: none`,
   the only reader is a developer inside this repo with source doc-comments and a 124-test
   suite. And the weakest part of the keep — the roadmap's `Either` signatures — is
   unimplemented, so no public-surface argument reaches it.
3. Drift is real and the doctrine names it. A 24 KB README re-deriving source is the exact
   stale-mirror §1.3 warns about, and this README already decays: heavy markdown corruption
   (over-backticked identifiers, mangled camel-case). A sanctioned deviation keeps that risk
   open permanently.
4. No grounds for a deviation exist. The ADR-0001 sealed-family deviation was
   language-mandated; nothing forces the README to restate doctrine. A voluntary deviation
   should not occupy the repo's sanctioned-deviations mechanism.

On B-hybrid: its concession to keep the entity inventory "because it is the public surface"
is the same seam argument at reduced strength, and for an unpublished package that inventory
is redundant with doc-comments and tests. Recommend against that concession.

## What the trimmed README keeps

Orientation per §1/§2 plus the §4 seam declaration:

- Title + one-paragraph intro (what it models; pure domain layer, no parsing/I/O).
- Background trimmed to provenance plus "domain layer; parser/validator live in future
  layers."
- Two-line seam declaration (sanctioned by §4): failures are returned as
  `Either<WorkflowFailure, T>` over a sealed `WorkflowFailure`.
- Getting started / tests: `dart pub get`, `dart test` (124), `dart analyze --fatal-infos`.
- Optional 5-line `lib/` layout sketch (barrel + top-level `src/` subdirs, no per-file
  type lists) — the A-lite orientation aid.
- Pointers to `docs/adr/` and `DEPENDENCY_DECISIONS.md` and the homes below.
- Fix the markdown corruption — mandatory regardless of path.

## Content relocation

- Roadmap `Either<...>` call-signature snippets and the 5 layers: move to
  `docs/roadmap.md` (or delete — the API is unimplemented), not README and not `examples/`,
  because untestable snippets would still lie (§2.7).
- Illustrative `dart`/`DSL` code blocks: move to tests — already exercised by the 124
  fixture-driven tests; create no `examples/` (`publish_to: none` makes it extra surface).
  Keep a `test/` pointer for any snippet worth preserving as prose.
- Entity / class-diagram inventory tables: drop (already fully in source doc-comments under
  `lib/src/entities`, `lib/src/cd`, `lib/src/value_objects`); keep at most a short prose
  summary.
- Architecture ASCII diagram: drop, or move to `docs/adr/` if it still has value (future
  sketch).
- Package layout tree: drop, or collapse to the 5-line sketch above.
- Dependency table: replace with a one-line pointer to `DEPENDENCY_DECISIONS.md`.
- Test-fixtures table: belongs near tests; drop or point to the test directory.

## Weakest keep case

The roadmap `Either<...>` API is the least defensible keep candidate: it documents an API
that does not exist in `lib/`, under an unpublished package — no seam or public-surface
argument reaches it. If the decision card still chooses keep, the irreducible minimum is to
relocate those snippets to `docs/roadmap.md` and fix the markdown corruption. This document
recommends trim.

## References

bible §1.3 (docs/01-architecture.md), §2.7 (docs/02-toolchain.md), §4
(docs/04-functional-core.md), 11-decisions.md L24/26, 00-compact.md L29/30; the bible's own
35-line README as exemplar. README-research-summary.md (counter-argument sets, corpus);
README-restatement-options.md (options A/B/hybrid with repo README ground truth).
