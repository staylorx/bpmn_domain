# Backlog

Open / pending items only. Settled decisions and shipped changes live in
`CHANGELOG.md`; anything already fixed is deleted from here, not struck through.

## Build & analysis

- `fpdart` (`dependencies`) and `mocktail` (`dev_dependencies`) are declared
  but unused — `fpdart` appears only in a doc comment on `workflow_failure.dart`
  and `mocktail` is imported nowhere. Use them or drop them; a declared-and-unused
  dependency is a false signal.

- `analysis_options.yaml` carries the obsolete `strong-mode:` block, silently
  ignored in Dart 3 — delete it so the file stops advertising enforcement it
  does not have (the real switches are the `language: strict-casts /
  strict-raw-types` block already present).

- No `dart_arch_test` boundary test — deferred per ADR-001 until a second
  package lands in this repo; it would be vacuous for a single package today.

## Deviations from the Dart/Flutter Bible

Repo `staylorx/dart-flutter-bible`, `docs/` §1–§12. Each item is a place the
code differs from the bible where the bible itself may be wrong — flag for
review, do not auto-fix.

- Deviation: `lib/src/entities/**`, `lib/src/value_objects/**`, `lib/src/cd/**`,
  `lib/src/failures/workflow_failure.dart` - one class per file is violated in
  the unsealed multi-class files; the sealed-family files stay grouped
  (sanctioned by ADR-0001 — Dart's same-library rule for `sealed` subtypes).
  Split the remaining unsealed files.

- Deviation: (use-case layer) - no use cases / repository contracts / datasource
  adapters in this package; that layering lives in `bpmn_application` and
  `bpmn_infrastructure`. Sequencing confirmed (t_d82e5f3d / t_eda54b2f): begin
  checker/resolver/conformance bodies behind the committed
  `Either<List<WorkflowFailure>, WfProcess>` seam when the `.wfm` parser lands;
  introduce `IUnitOfWork` only when a transactional multi-store write or a 3rd
  datasource adapter appears.

## Open questions

- Do the long-form class docs stay? `public_member_api_docs` is now enabled,
  which forces terse `///` on every public member while §2 caps docs at 1–2
  lines — cutting the grammar tables and DSL examples that make this package
  usable. Shrink to doctrine, or propose the bible allow richer docs for a
  domain-model package.
