# AGENTS.md

Pure-Dart clean-architecture **domain layer** for the BPMN 2.0 Workflow (`.wfm`) and CD4Analysis Class Diagram (`.cd`) DSLs. Models only — no parsing, no I/O; entities, value objects, and the sealed `WorkflowFailure` hierarchy.

This file records the repo's local wiring, its deviations from the Dart/Flutter Bible (`staylorx/dart-flutter-bible`, `docs/` §1–§12), and its error-style declaration. It follows the structure the bible implies in §4 and §11: an agent-facing orientation (below), the deviations list, and the error-style declaration.

## Local wiring

### Tooling

- Dart SDK via FVM default (`C:/Users/stayl/fvm/default/bin`). CI targets a multi-SDK floor: `[3.10.0, stable]` (declared floor `>=3.10.0 <4.0.0` plus latest stable to catch forward drift).
- `dart pub get` — resolve dependencies. Declared `fpdart` `^1.2.0`; see the deviation note below (currently unused).

### Gate

CI (`./.github/workflows/ci.yml`) runs on push to `main` and on PRs. Local equivalent, must be green before committing/pushing:

```sh
dart pub get
dart analyze --fatal-infos --fatal-warnings   # → "No issues found!" (zero diagnostics of any severity)
dart format --output=none --set-exit-if-changed .
dart test                                     # → 124 tests
```

> Note (doctrine gate, see deviations): `dart analyze --fatal-infos --fatal-warnings` is currently RED on `main` — 61 × `deprecated_member_use` from `EquatableMixin` being deprecated in `equatable` 2.1.0 (fix: `extends Equatable` / `with EquatableMixin` → `with Equatable`). Until fixed, the repo cannot pass its own gate. Verified locally on `main` @ `c44dbff`.

### Key paths

| Thing | Location |
|---|---|
| Remote | `https://github.com/staylorx/bpmn_domain` |
| Barrel | `lib/bpmn_domain.dart` (`library;`, re-exports `lib/src/`) |
| Entities | `lib/src/entities/` |
| Class-diagram model | `lib/src/cd/` |
| Value objects | `lib/src/value_objects/` |
| Failures | `lib/src/failures/workflow_failure.dart` (sealed `WorkflowFailure` + ~28 `final` subclasses) |
| Test fixtures | `test/fixtures/` |
| Decisions | `docs/adr/` (ADR-0001 sealed-family grouping, ADR-0002 README orientation-only) |
| Tracker / changelog | `BACKLOG.md` / `CHANGELOG.md` |

### Consumption

- Consumed as a **git ref on `main`** by sibling packages (`bpmn_application`, `bpmn_infrastructure/packages/{parser,sembast}`) — a breaking change to `main` breaks all of them. Gate before pushing.
- Tests use `shouldly`.

## Deviations from the Dart/Flutter Bible

Each item is a place this repo differs from the bible where the difference is deliberate or flagged for review. Full rationale lives in `BACKLOG.md` and `docs/adr/`. A subset (sealed-family file grouping) is sanctioned by ADR.

1. **`public_member_api_docs` not enabled; docs are long-form.** §2/§9.8 require `public_member_api_docs` on and terse 1–2 line docs; this repo instead has unusually rich multi-paragraph class docs (grammar tables, DSL examples). Flagged for review — the long-form docs are genuinely useful.

2. **`errors:` block in `analysis_options.yaml` downgrades/disables rules; `todo: ignore` instead of `todo: error`.** §2 says never disable or downgrade a rule. (`prefer_const_constructors` is both enabled and ignored in two places.) Also carries a dead `strong-mode:` block that the analyzer silently ignores.

3. **One class per file is violated throughout; sealed families are SANCTIONED exceptions.** §2 requires one class per file. 20 of 27 `lib/src/**` files declare multiple public types; `workflow_failure.dart` alone hosts 28. The seven files hosting a `sealed` parent + its leaf subclasses cannot be split (Dart's same-library rule) — **SANCTIONED via ADR-0001**. The unsealed multi-class files remain candidates for a future one-class-per-file pass.

4. **Test names are not Given/When/Then.** §6 prescribes the Given…/When…/Then… group shape; this repo uses behaviour labels (`'equality is structural'`). Assertion style itself is CONVERTED to `shouldly` (§6) — only the naming shape remains a deviation.

5. **Error style (declared below).** The package models failure as a sealed `WorkflowFailure` hierarchy (28 types, `switch`-exhaustive) with **no `Either` / `TaskEither` / `Option`** anywhere on a seam. See the Error Style Declaration for the exact wording this repo is committed to.

6. **`fpdart` declared but unused.** `fpdart: ^1.2.0` is a dependency (and §4/§5 make `fpdart` "ALWAYS", `Either` the failure channel). This package declares but never imports it — its only appearance is a doc-comment reference. The pin is dead weight until the value-returning operations (or the CoCo validator layer) arrive. Flagged: drop it, or grow the operations that earn it.

7. **`EquatableMixin` (deprecated form).** Code uses `with EquatableMixin`, which `equatable` 2.1.0 deprecates in favour of `with Equatable`. Same root cause as the red analyze gate; listed as a doctrine-shape call.

8. **No `dart_arch_test` boundary test.** §2/§9.7 make package-boundary direction + cycle-freedom a CI hard gate. With a single package there is no cross-package direction to check today (harmless now), but this repo is one third of a core+adapters split the bible's §3 Topology B only half-sanctions; the boundary test is what would catch the split going wrong. Flagged for the workspace-level decision.

9. **No root `workspace:` — standalone single package, consumed as a git dependency.** The bible's workspace model (§2/§9.2-4) assumes a root pubspec with a `workspace:` list; this repo is standalone and siblings consume it as an (unpinned `ref:`) git dependency — the failure mode the workspace model exists to prevent. Deliberate topology choice.

10. **README trimmed to orientation-only (`publish_to: none`).** **RESOLVED** via ADR-0002 — because the package sets `publish_to: none` there is no pub.dev consumer surface for the README to "seam" for, so the §4 seam argument collapses.

(Formerly "no `AGENTS.md` at repo root" — this file now satisfies the orientation + declaration duty.)

## Error Style Declaration

> **This package deviates from the default `Future<Either<…>>` error style. It returns immutable data plus a `sealed` failure tree; no `Either` is used.**

Concretely: every public seam returns immutable values; failures are the sealed `WorkflowFailure` hierarchy in `lib/src/failures/workflow_failure.dart` (`sealed class WorkflowFailure extends Equatable` with ~28 `final` leaf subclasses, consumed via exhaustive `switch`). No operation returns `Either`, `TaskEither`, or `Option`, and no exception is raised across a seam. Where the layer above needs a result/failure channel it consumes this sealed tree directly.
