# AGENTS.md

Pure-Dart clean-architecture **domain layer** for the BPMN 2.0 Workflow (`.wfm`) and CD4Analysis Class Diagram (`.cd`) DSLs. Models only — no parsing, no I/O; entities, value objects, and the sealed `WorkflowFailure` hierarchy.

This file records the repo's local wiring, its deviations from the Dart/Flutter Bible (`staylorx/dart-flutter-bible`, `docs/` §1–§12), and its error-style declaration. It follows the structure the bible implies in §4 and §11: an agent-facing orientation (below), the deviations list, and the error-style declaration.

## Local wiring

### Tooling

- Dart SDK via FVM default (`C:/Users/stayl/fvm/default/bin`). CI targets a multi-SDK floor: `[3.10.0, stable]` (declared floor `>=3.10.0 <4.0.0` plus latest stable to catch forward drift).
- **Melos** is the workspace + task runner (Topology C, single-package; `useRootAsPackage: true`). All local tasks go through it: `melos bs` (bootstrap / dependency resolve) and `melos run <task>`. Melos is pinned `^8.8.0` in `dev_dependencies`.
- `dart pub get` — resolve dependencies directly (the single-package equivalent of `melos bs`). Declared `fpdart` `^1.2.0`; see the deviation note below (currently unused).

### Gate

CI (`./.github/workflows/ci.yml`) runs on push to `main` and on PRs. Local equivalent, must be green before committing/pushing (also reachable in one shot via `melos run verify`, which runs analyze → format → test):

```sh
melos run analyze     # dart analyze --fatal-infos --fatal-warnings → "No issues found!"
melos run format      # dart format --output=none --set-exit-if-changed . → no diffs
melos run test        # dart test → 124 tests
```

`melos run clean:deep` is available for a nuclear reset (git clean of all untracked files, then `melos bs` re-bootstrap). It only ever removes untracked artifacts (`.dart_tool/`, `doc/` dartdoc output, IDE noise) — tracked `docs/`, `lib/`, `test/`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml` are always safe.

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

1. **Class docs are long-form, not the terse 1–2 line shape.** §2/§9.8 require `public_member_api_docs` on and terse 1–2 line docs. `public_member_api_docs` IS enabled (every public API member is documented); the remaining delta is that docs are unusually rich multi-paragraph (grammar tables, DSL examples) rather than 1–2 lines. Deliberate style choice, flagged for review — the long-form docs are genuinely useful.

2. **Dead `strong-mode:` block in `analysis_options.yaml`.** `analyzer.strong-mode` (`implicit-casts` / `implicit-dynamic`) still exists at the top of the file, but the analyzer silently ignores it under modern Dart (the keys are inert) — this is the only flag worth carrying. The rest of the file is clean: the `errors:` block only raises `missing_return` and `todo` to `error` (§2.2, no downgrades or disables — the former `dead_code`/`invalid_assignment` downgrades were removed), and `prefer_const_constructors` has zero `// ignore:` annotations.

3. **One class per file is violated throughout; sealed families are SANCTIONED exceptions.** §2 requires one class per file. 18 of 26 `lib/src/**` files declare multiple public types; `workflow_failure.dart` alone hosts 28 (a sealed parent + 27 `final` leaves). The seven files hosting a `sealed` parent + its leaf subclasses cannot be split (Dart's same-library rule) — **SANCTIONED via ADR-0001**. The unsealed multi-class files remain candidates for a future one-class-per-file pass.

4. **Test names are not Given/When/Then.** **RESOLVED** — tests were fully renamed to the Given/When/Then shape (36 `group('Given …')`, 124 `test('When …' / 'Then …')` in `test/bpmn_domain_test.dart`); assertion style is `shouldly` (§6).

5. **Error style (declared below).** The package models failure as a sealed `WorkflowFailure` hierarchy (28 types, `switch`-exhaustive) with **no `Either` / `TaskEither` / `Option`** anywhere on a seam. See the Error Style Declaration for the exact wording this repo is committed to.

6. **`fpdart` declared but unused.** `fpdart: ^1.2.0` is a dependency (and §4/§5 make `fpdart` "ALWAYS", `Either` the failure channel). This package declares but never imports it — its only appearance is a doc-comment reference. The pin is dead weight until the value-returning operations (or the CoCo validator layer) arrive. Flagged: drop it, or grow the operations that earn it.

7. **`EquatableMixin` (deprecated form).** Code uses `with EquatableMixin`, which `equatable` 2.1.0 deprecates in favour of `with Equatable`. Same root cause as the red analyze gate; listed as a doctrine-shape call.

8. **No `dart_arch_test` boundary test.** §2/§9.7 make package-boundary direction + cycle-freedom a CI hard gate. With a single package there is no cross-package direction to check today (harmless now), but this repo is one third of a core+adapters split the bible's §3 Topology B only half-sanctions; the boundary test is what would catch the split going wrong. Flagged for the workspace-level decision. (The former TODO comment in `test/bpmn_domain_test.dart` was removed so the `todo: error` analyze gate stays green; this deviation entry is the permanent record.)

9. **Single-package melos workspace (Topology C, `useRootAsPackage: true`), consumed as a git dependency.** The bible's workspace model (§2/§9.2-4) assumes a root pubspec with a `workspace:` list of sub-packages; this repo instead is a Topology-C melos workspace where the root pubspec IS the only package (`useRootAsPackage: true`, no `workspace:` list). Siblings consume it as an (unpinned `ref:`) git dependency — the failure mode the workspace model exists to prevent. Deliberate topology choice.

10. **README trimmed to orientation-only (`publish_to: none`).** **RESOLVED** via ADR-0002 — because the package sets `publish_to: none` there is no pub.dev consumer surface for the README to "seam" for, so the §4 seam argument collapses.

(Formerly "no `AGENTS.md` at repo root" — this file now satisfies the orientation + declaration duty.)

## Error Style Declaration

> **This package deviates from the default `Future<Either<…>>` error style. It returns immutable data plus a `sealed` failure tree; no `Either` is used.**

Concretely: every public seam returns immutable values; failures are the sealed `WorkflowFailure` hierarchy in `lib/src/failures/workflow_failure.dart` (`sealed class WorkflowFailure extends Equatable` with ~28 `final` leaf subclasses, consumed via exhaustive `switch`). No operation returns `Either`, `TaskEither`, or `Option`, and no exception is raised across a seam. Where the layer above needs a result/failure channel it consumes this sealed tree directly.
