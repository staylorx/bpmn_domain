# Backlog

Open / pending items only. Settled decisions and shipped changes live in
`CHANGELOG.md`; anything already fixed is deleted from here, not struck through.

## Build & analysis (Windows lane, Dart SDK 3.13.1)

Gates run fresh on `main` @ `c44dbff`:

- `dart pub get` — OK
- `dart analyze --fatal-infos` — **61 diagnostics, all `info`, all
  `deprecated_member_use`** → gate RED (exit 1)
- `dart format . --set-exit-if-changed` — 28 files checked, 0 changed
- `dart test` — 124 passed, 0 failed
- `dart pub publish --dry-run` — 1 warning (see below)
- `dart pub outdated` — `equatable 2.1.0` (3.0.0 available); dev_dependencies
  up to date

Problems found:

- **`dart analyze --fatal-infos` is RED: 61 × `deprecated_member_use`.** All 61
  are the same diagnostic — `EquatableMixin` is deprecated in `equatable` 2.1.0
  ("use `Equatable` as a mixin instead"). Infected files are the whole entity and
  value-object tree plus `lib/src/failures/workflow_failure.dart` and
  `lib/src/cd/*` (e.g. `cd_association.dart:18`, `cd_classifier.dart:81`,
  `event_trigger.dart:38`, `gateway.dart:211`, `workflow_failure.dart:24`).
  **Recommendation: mechanical fix — `class Foo extends Equatable` /
  `... with EquatableMixin` → `class Foo with Equatable`.** Note the repo
  currently resolves `equatable` 2.1.0 (constraint `^2.0.7`), so the deprecation
  is live, not theoretical. Until this is fixed the repo cannot pass its own
  doctrine gate; nothing else about the package is red.

- **Three declared-but-unused dependencies.** `fpdart` (`dependencies`) and
  `shouldly` + `mocktail` (`dev_dependencies`) are imported nowhere in `lib/` or
  `test/` (verified by grep). `fpdart`'s only appearance is a doc-comment
  reference in `workflow_failure.dart:15`. **Recommendation: either bring the
  tests onto `shouldly` and use `fpdart` at the (future) seam, or drop all three
  — a dependency that is declared and unused is a false signal.** (`shouldly` was
  added in `c44dbff` for exactly the testing-doctrine reason below.)

- **`CHANGELOG.md` version ≠ `pubspec.yaml` version.** `pubspec.yaml` declares
  `version: 0.1.0` while the changelog's only heading is `## 1.0.0`.
  `dart pub publish --dry-run` reports: *"CHANGELOG.md doesn't mention current
  version (0.1.0)"*. Fixed in this pass (see `CHANGELOG.md`); recorded here so the
  `--dry-run` warning is not mistaken for a one-off.

- **No CI workflow.** `.github/` does not exist, so nothing runs
  `dart analyze` / `dart test` on push or PR — the red analyze gate above was
  free to land. §9.10 makes CI (analyze + test across every package) part of the
  bootstrap checklist. **Recommendation: add a `dart analyze --fatal-infos
  --fatal-warnings` + `dart test` workflow.**

- **No `dart_arch_test` boundary test, and no workspace root.** The repo is a
  single package with no root `pubspec.yaml` `workspace:` list and no
  architecture test. Related deviation below.

- **No `AGENTS.md`.** The repo carries no agent-facing conventions file and does
  not declare its error style anywhere; see the error-style deviation below.

- **Dead analyzer config.** `analysis_options.yaml:3-5` sets
  `strong-mode: implicit-casts: false / implicit-dynamic: false`. `strong-mode`
  was removed from the analyzer years ago and is **silently ignored** in Dart 3;
  the real switches are the `language: strict-casts / strict-raw-types` block
  already present below it. **Recommendation: delete the `strong-mode` block so
  the file does not advertise enforcement it does not have.**

- **`publish_to: none`** (`pubspec.yaml`) — `dart pub publish --dry-run` still
  validates the package and does pass, but nothing here is publishable as
  configured. Recorded so the gate is not mistaken for skipped.

## Deviations from the Dart/Flutter Bible

Repo `staylorx/dart-flutter-bible`, `docs/` §1–§12. Each item is a place the code
differs from the bible **where the bible itself may be wrong** — flag for review,
do not auto-fix. Line references are to `main` @ `c44dbff`.

- Deviation: `analysis_options.yaml` - `public_member_api_docs` is **not
  enabled**, and `todo: error` is not mapped (§2/§9.8). The consequence is
  measurable: re-running `dart analyze` in a scratch copy with the bible's lints
  enabled reports **166 × `public_member_api_docs`** on top of the 61
  deprecations — e.g. `value_objects/wf_type_ref.dart:28`. §2 requires a terse
  `///` (1–2 lines, what+why) on every public declaration and member. The
  *existing* docs are unusually rich (multi-paragraph class docs with grammar
  tables), which is the opposite failure mode: §2 says **1–2 lines, never more**,
  and these run to dozens. Flagged for review — the long-form docs are genuinely
  useful and a stricter lint would force them to shrink.

- Deviation: `analysis_options.yaml:17-22` - the `errors:` block **downgrades**
  `invalid_assignment` to `warning` and `dead_code` to `info`, **disables**
  `prefer_const_constructors`, and carries a `# todo: ignore` comment where
  `todo: error` belongs. §2 says never disable or downgrade a rule in
  `analysis_options.yaml` (and §2's "zero diagnostics of any severity" makes the
  downgrade meaningless anyway — an info still fails `--fatal-infos`). Note the
  `prefer_const_constructors` rule is *also* listed under `linter: rules:`, so the
  file both enables and ignores it in two places.

- Deviation: `lib/src/entities/**`, `lib/src/value_objects/**`, `lib/src/cd/**`,
  `lib/src/failures/workflow_failure.dart` - **one class per file is violated
  throughout.** 20 of the 27 `lib/src/**` files declare more than one public
  type: `workflow_failure.dart` has **28**, `event_trigger.dart` 9,
  `gateway.dart` 10, `timer_condition.dart` 8, `loop_characteristic.dart` 6,
  `sequence_flow.dart` 6, `io_requirement.dart` 5, `cd_classifier.dart` 4,
  `event.dart` 4, `subprocess.dart` 4, `cd_association.dart` 3, `process.dart` 3,
  `stereotype.dart` 3, `task.dart` 3, and `cd_class_diagram.dart`, `cd_method.dart`,
  `data_object.dart`, `node_id.dart` 2 each. §2/§1 (compact) say one class per
  file. Flagged for review: the grouping is *thematic* (all timer conditions
  together, the whole failure hierarchy together) and arguably more navigable
  than 28 single-class files — the bible may be wrong here, or it may intend
  "one class per file" only for non-trivial types.

- Deviation: `test/bpmn_domain_test.dart` (the sole test file) - **every test
  uses `expect()` from `package:test`; no test imports `shouldly`.** §6: shouldly
  is the assertion library (`value.should.be(...)`) and `expect()` is never mixed
  in. Compounding it, the test names are **not Given/When/Then** — they are
  behaviour labels (`'equality is structural'`, `'isSimpleName rejects qualified
  names'`, `'ProcessNotSound message'`), where §6 gives the
  `Given … / When … / Then …` group shape. Both are mechanical migrations; the
  domain-layer matrix row (unit tests, no mocks) is otherwise correct.

- Deviation: (missing) an error-style declaration - **no package declares
  whether consumers get FP-style tuples or plain exceptions.** §4 ("Declare the
  error style, loudly") requires the barrel doc comment, the README and (on
  deviation) `AGENTS.md` to state it; `lib/bpmn_domain.dart`'s doc comment
  documents the API surface but never names an error style, the README's
  "Dependencies" section does not either, and there is no `AGENTS.md`. Note the
  repo also carries no `Either`-returning operation at all, so today the package
  *is* silent-compliant — but silence is the violation, and consumers need to know
  what the parser/validator layer above will hand them.

- Deviation: `pubspec.yaml:15` + all of `lib/` - **`fpdart` is a declared
  dependency that nothing uses.** §4/§5 make `Either`/`TaskEither` the failure
  channel inside the bulls-eye and `fpdart` "ALWAYS". This package models failure
  as a **sealed `WorkflowFailure` hierarchy** (`lib/src/failures/workflow_failure.dart`,
  28 types, `switch`-exhaustive) but never wraps it in `Either`/`Option`. That is
  arguably correct for a *pure entity* package with no operations that can fail —
  the failure types are CoCo violations the layer above returns — but it means
  the `fpdart` pin is dead weight until that layer exists. Flagged: either the
  dependency goes, or the domain grows the value-returning operations the bible
  assumes.

- Deviation: `pubspec.yaml:14` - `equatable: ^2.0.7`, but the code uses the
  **deprecated `EquatableMixin`**. §2/§1 pin `equatable ^2.x` (correct) and
  require equatable value equality everywhere (correct — 87 `props` getters, all
  entities `const`, all operations return new instances). The divergence is the
  *mix-in form*, which `equatable` 2.1.0 deprecates in favour of `with Equatable`.
  Same root cause as the red analyze gate above; listed here because the fix is a
  doctrine-shape call, not just a lint.

- Deviation: `README.md` - restates architecture the bible already owns: a
  "bpmn_domain (this package)" layer diagram, a package-layout tree, and
  per-entity architecture prose. §1 D.R.Y. is explicit — repo READMEs *orient*
  (what it is, how to run it) and carry no rules or architecture; a rule stated
  twice is a second truth. The README is 23 KB and reads as a second copy of the
  doctrine, not an orientation. Flagged for review: for a domain-model package
  the entity catalogue may legitimately be the orientation, but it currently
  restates §1/§4 rules verbatim ("no parsing, no I/O").

- Deviation: (missing) a `dart_arch_test` boundary test - **no architecture test
  exists and `dart_arch_test` appears in no pubspec.** §2/§9.7 make package-boundary
  direction + cycle-freedom a **CI hard gate**. With a single package there is no
  cross-package direction to check today, so the omission is harmless *now* — but
  this repo is one half of a core (`bpmn_domain` + `bpmn_application` +
  `bpmn_infrastructure`) that the bible's §3 Topology B only half-sanctions
  (B is core + UI, not core + adapters + a remote core). The boundary test is the
  thing that would catch the split going wrong. Flagged for the workspace-level
  decision, not for this package.

- Deviation: `pubspec.yaml` (no root/`workspace:`) - the bible's workspace model
  (§2/§9.2-4) assumes a root pubspec with a `workspace:` list and
  `resolution: workspace` in each member. This repo is a **standalone single
  package**, and its siblings (`bpmn_application`, `bpmn_infrastructure`) consume
  it as a **git dependency**, not a workspace member. §3 permits per-repo splits,
  so this is flagged as a deliberate topology choice the bible does not describe
  — noted because the git-dependency wiring (unpinned `ref:` in the siblings) is
  the failure mode the workspace model exists to prevent.

## Open questions

- **Do the long-form class docs stay?** Enabling `public_member_api_docs`
  (§2, required) would immediately demand `///` on ~166 members, while the same
  section caps every doc at 1–2 lines — which would cut the grammar tables and
  DSL examples that make this package usable. Decide: shrink to doctrine, or
  propose the bible allow richer docs for a domain-model package.
- **One class per file — apply, or propose the exemption?** 20/27 files violate
  it; the grouping is thematic and reads better, but the bible is unambiguous.
- **Is `fpdart` load-bearing here?** If the entity package is genuinely
  operation-free, drop the dependency; if the CoCo validators live here, they
  should return `Either<WorkflowFailure, …>` and the pin earns its place.
- **Does the analyze gate get green before CI is added?** The 61 deprecations are
  a 15-minute mechanical fix; recommend fixing them first so the first CI run is
  green and the gate is trustworthy from day one.
