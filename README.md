# bpmn_domain

A clean-architecture domain model for the MontiCore **Workflow DSL** (`.wfm`) and **CD4Analysis Class Diagram** (`.cd`) languages. Provides richly documented, immutable domain entities for a workflow model and its class-diagram type system — a pure domain layer with no parsing, I/O, or validation logic.

## Background

This package models the constructs found in the MontiCore BPMN grammar and example files (`lib/src/entities` for workflow, `lib/src/cd` for class diagrams, `lib/src/value_objects` for shared value types) so that a parser can produce fully typed domain objects and a validator can check them against all known context conditions. Parsing and validation live in future layers, not here.

## Error style

This package throws nothing across a public seam. Public seams return failures as `Future<Either<WorkflowFailure, T>>` over the sealed `WorkflowFailure` hierarchy. This Either-over-sealed-failure surface is a planned API; it is not yet implemented (see [docs/roadmap.md](docs/roadmap.md)).

## Getting started

```sh
dart pub get
dart test               # 124 tests, fixture-driven
dart analyze --fatal-infos
```

## Package layout

```
lib/
├── bpmn_domain.dart     barrel export (all public entities)
└── src/
    ├── value_objects/   shared value types (NodeId, PackagePath, TimerCondition, ...)
    ├── entities/        workflow entities (WfProcess, WfTask, WfEvent, ...)
    ├── cd/              class-diagram entities (CdClassDiagram, CdClass, ...)
    └── failures/        WorkflowFailure sealed hierarchy (~25 CoCo subclasses)
```

Type-level details live in the source doc-comments under those directories; illustrative DSL/`dart` examples are exercised by the test suite under `test/`.

## Documentation

- [docs/roadmap.md](docs/roadmap.md) — planned parser / validator / conformance layers (all unimplemented).
- [docs/adr/](docs/adr/) — architecture decision records.
- [DEPENDENCY_DECISIONS.md](DEPENDENCY_DECISIONS.md) — dependency versions and drift decisions.
