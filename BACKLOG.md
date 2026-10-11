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

- **Two declared-but-unused dependencies.** `fpdart` (`dependencies`) and
  `mocktail` (`dev_dependencies`) are imported nowhere in `lib/` or `test/`
  (verified by grep). `fpdart`'s only appearance is a doc-comment reference in
  `workflow_failure.dart:15`. **Recommendation: either use `fpdart` at the
  (future) seam, or drop it — a dependency that is declared and unused is a
  false signal.** (`shouldly`, previously listed here as unused, is now
  **CONVERTED** — the tests were migrated onto it in `297b61a` and its
  dev-dependency is retained at `^0.5.0+1`. Decision and rationale in
  `bpmn-shouldly-decision.md`.)

- **`CHANGELOG.md` version ≠ `pubspec.yaml` version.** `pubspec.yaml` declares
  `version: 0.1.0` while the changelog's only heading is `## 1.0.0`.
  `dart pub publish --dry-run` reports: *"CHANGELOG.md doesn't mention current
  version (0.1.0)"*. Fixed in this pass (see `CHANGELOG.md`); recorded here so the
  `--dry-run` warning is not mistaken for a one-off.

- **`dart_arch_test` boundary test** (see below).

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
  file. **STATUS: SANCTIONED for sealed-family files.** The 7 files hosting a
  `sealed` parent + its leaf subclasses (`workflow_failure.dart`, `gateway.dart`,
  `event_trigger.dart`, `timer_condition.dart`, `sequence_flow.dart`,
  `io_requirement.dart`, `loop_characteristic.dart`) **cannot be split** — Dart's
  same-library rule requires every direct subtype of a `sealed` class to live in
  the same file as the parent, and un-sealing would break the exhaustive-switch
  guarantee the Bible itself requires (§4). See **ADR-0001**
  (`docs/adr/0001-sealed-family-file-grouping.md`) for the full decision and
  rationale; the unsealed non-family multi-class files are NOT covered by this
  sanction and remain one-class-per-file candidates.

- Deviation: `test/bpmn_domain_test.dart` (the sole test file) - **assertion
  style: CONVERTED.** All assertions now use `shouldly` (`value.should.be(...)`)
  per §6 — converted in `297b61a` (213 `should.` calls, no `expect(` mixing;
  decision in `bpmn-shouldly-decision.md`). **Recorded deviation (remaining):
  the test names are not Given/When/Then** — they are behaviour labels
  (`'equality is structural'`, `'isSimpleName rejects qualified names'`,
  `'ProcessNotSound message'`), where §6 gives the
  `Given … / When … / Then …` group shape. A mechanical migration; the
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
  **STATUS: RESOLVED — TRIM the README to orientation-only.** Because the
  package sets `publish_to: none`, no pub.dev consumer surface exists for the
  README to "seam" for, so the public-facing seam counter-argument collapses;
  the sanctioned §4 error-style declaration (already added to the barrel doc
  comment) carries the honest seam. Planned changes (see the decision document
  `docs/adr/0002-readme-orientation-only.md`, task `t_bee74f83`; source
  `README-decision-final.md`): keep the title + one-paragraph
  intro, the §4 seam declaration, getting-started/tests, and an optional 5-line
  `lib/` layout sketch; move the roadmap `Either<...>` snippets and the 5-layer
  roadmap to `docs/roadmap.md` (or delete — the API is unimplemented); move
  illustrative `dart`/DSL blocks to tests (no `examples/`, given `publish_to:
  none`); replace the dependency table with a one-line pointer to
  `DEPENDENCY_DECISIONS.md`; drop or relocate the architecture diagram/package
  tree to `docs/adr/`; and fix the markdown corruption regardless.

- Deviation: (missing) a `dart_arch_test` boundary test - **no architecture test
  exists and `dart_arch_test` appears in no pubspec.** §2/§9.7 make package-boundary
  direction + cycle-freedom a **CI hard gate**. With a single package there is no
  cross-package direction to check today, so the omission is harmless *now* — but
  this repo is one half of a core (`bpmn_domain` + `bpmn_application` +
  `bpmn_infrastructure`) that the bible's §3 Topology B only half-sanctions
  (B is core + UI, not core + adapters + a remote core). The boundary test is the
  thing that would catch the split going wrong. Flagged for the workspace-level
  decision, not for this package.
  **STATUS: DEFERRED — see ADR-001 (decision t_0e301f78).** Decision
  (2026-10-11): do not add a `dart_arch_test` boundary/cycle test now; the test
  would be vacuous while this repo is a single package with one barrel and no
  cross-package edge to assert. Deferred until a second package is added to this
  repo (the roadmapped parser/validator landing in their own Dart package).
  Trigger + eventual assertions (inward-only boundary direction, cycle freedom)
  recorded in `docs/architecture/adr-001-dart-arch-test.md`; `TODO(dart_arch_test)`
  placed in `test/bpmn_domain_test.dart` per ADR-001.

- Deviation: `pubspec.yaml` (no root/`workspace:`) - the bible's workspace model
  (§2/§9.2-4) assumes a root pubspec with a `workspace:` list and
  `resolution: workspace` in each member. This repo is a **standalone single
  package**, and its siblings (`bpmn_application`, `bpmn_infrastructure`) consume
  it as a **git dependency**, not a workspace member. §3 permits per-repo splits,
  so this is flagged as a deliberate topology choice the bible does not describe
  — noted because the git-dependency wiring (unpinned `ref:` in the siblings) is
  the failure mode the workspace model exists to prevent.
  **STATUS: SANCTIONED — KEEP STANDALONE (decision t_75b4af8e).** Decision
  (2026-10-11): keep `bpmn_domain` as a standalone single package rather than
  restructuring toward Topology A or B (bible §2/§3). Rationale: (1) this
  package is a **pure-domain centre** — no repository contracts, no datasource
  adapters, no use cases, no I/O — so the bible's ≥2-repository-adapter rule and
  shared contract suite are **vacuous** here (nothing to bind to); (2) Topology
  A/B skeletons assume a *full deliverable* (domain + use cases + ≥2 datasource
  adapters + app), which already exists across the sibling repos
  (`bpmn_application` holds the 7 use cases + 2 repository contracts,
  `bpmn_infrastructure` is already a melos workspace with 3 adapter packages over
  2 datasources) — so this package is one well-formed per-repo split within an
  already-composed system, not an incomplete monolith (see the `dart_arch_test`
  deviation above: the boundary test is the workspace-level catch, and it is
  flagged there, not here); (3) adding a `workspace:` / melos block to a
  single, already-consumed core package would add tooling without adding
  topology value. Residually, the known costs stand recorded: siblings consume
  this repo by unpinned `ref: main` git dependency, the failure mode the
  workspace model exists to prevent — tracked as the separate workspace-level
  wiring concern at `t_8ccdd421`. **REVISIT TRIGGER: when the use-case /
  application layer lands in or is added to this package (i.e. the first
  `I*Repository` contract or use case is declared here, or a second package is
  introduced into this repo), re-evaluate workspace adoption then.** See the
  related application-layer card **t_eda54b2f ("Decide use-case layer
  sequencing")** — currently sequencing the use-case/validator seam into
  `bpmn_application`, which is where this deviation gets revisited.

## Open questions

- **Do the long-form class docs stay?** Enabling `public_member_api_docs`
  (§2, required) would immediately demand `///` on ~166 members, while the same
  section caps every doc at 1–2 lines — which would cut the grammar tables and
  DSL examples that make this package usable. Decide: shrink to doctrine, or
  propose the bible allow richer docs for a domain-model package.
- **One class per file — DECIDED (ADR-0001).** Sealed-family files stay grouped
  (sanctioned, `docs/adr/0001-sealed-family-file-grouping.md`); the unsealed
  multi-class files remain candidates for a separate one-class-per-file pass.
- **Is `fpdart` load-bearing here?** If the entity package is genuinely
  operation-free, drop the dependency; if the CoCo validators live here, they
  should return `Either<WorkflowFailure, …>` and the pin earns its place.
- **Does the analyze gate get green before CI is added?** The 61 deprecations are
  a 15-minute mechanical fix; recommend fixing them first so the first CI run is
  green and the gate is trustworthy from day one.
