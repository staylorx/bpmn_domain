# AGENTS.md

Pure-Dart clean-architecture **domain layer** for the BPMN 2.0 Workflow (`.wfm`) and CD4Analysis Class Diagram (`.cd`) DSLs. Models only — no parsing, no I/O, no fpdart `Task`s; entities, value objects, and the sealed `WorkflowFailure` hierarchy.

## Gate

No CI workflow is configured; the gate is:

```sh
dart analyze --fatal-infos --fatal-warnings   # → "No issues found!" (zero diagnostics of any severity)
dart test                                     # → 124 tests
```

`analysis_options.yaml` enables `strict-casts`, `strict-raw-types`, `always_declare_return_types`, `avoid_print`, and `todo: ignore`.

## Key paths

| Thing | Location |
|---|---|
| Remote | `https://github.com/staylorx/bpmn_domain` |
| Barrel | `lib/bpmn_domain.dart` (`library;`, re-exports `lib/src/`) |
| Entities | `lib/src/entities/` |
| Class-diagram model | `lib/src/cd/` |
| Value objects | `lib/src/value_objects/` |
| Failures | `lib/src/failures/workflow_failure.dart` (sealed `WorkflowFailure` + ~25 CoCo subclasses) |
| Test fixtures | `test/fixtures/` |
| Tracker / changelog | `BACKLOG.md` / `CHANGELOG.md` |

## Error style

`Either<WorkflowFailure, T>` on every public seam (fpdart `^1.2.0`); failures are the sealed `WorkflowFailure` hierarchy. Behaviour-classifying sealed hierarchies (`EventTrigger`, `GatewayKind`, `TimerCondition`, `LoopCharacteristic`, `WfIORequirement`) — adding a case means revisiting every exhaustive switch over it.

## Wiring / deviations

- Consumed as a **git ref on `main`** by three sibling packages (`bpmn_application`, `bpmn_parser`, `bpmn_sembast`), so a breaking change to `main` breaks all of them. Gate before pushing.
- Tests use `shouldly`.
