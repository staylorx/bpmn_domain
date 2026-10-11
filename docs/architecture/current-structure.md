# Current Package Structure & Import Graph

Date of inspection: 2026-10-11
Scope: the BPMN repository group (`C:/awork_local/mine/bpmn`) at `main`.

## Summary

The BPMN codebase is **not a single package**. It is a clean-architecture
monorepo group of three top-level Dart packages, one of which
(`bpmn_infrastructure`) is itself a Melos/Dart workspace containing three more
member packages. There are **six packages total** and **five public barrel
files** (library entry points) across them.

Onion/layer direction: `bpmn_domain` (innermost) ← `bpmn_application` ←
`bpmn_infrastructure` (workspace of parser / db / cli members). Dependency
edges point inward only; no layer imports outward.

## Package inventory

| Package | Path | Type | Barrel (`lib/<name>.dart`) | Depends on (in-group) |
|---|---|---|---|---|
| `bpmn_domain` | `bpmn_domain/` | library (domain) | `lib/bpmn_domain.dart` | — (innermost) |
| `bpmn_application` | `bpmn_application/` | library (application) | `lib/bpmn_application.dart` | `bpmn_domain` (git) |
| `bpmn_infrastructure` | `bpmn_infrastructure/` | Melos workspace root | (none — no `lib/<name>.dart`) | ws: `packages/parser`, `packages/sembast`, `packages/cli` |
| `bpmn_parser` | `bpmn_infrastructure/packages/parser/` | library (infra: parser/repo) | `lib/bpmn_parser.dart` | `bpmn_application`, `bpmn_domain` |
| `bpmn_sembast` | `bpmn_infrastructure/packages/sembast/` | library (infra: db) | `lib/bpmn_sembast.dart` | `bpmn_application`, `bpmn_domain` |
| `bpmn_cli` | `bpmn_infrastructure/packages/cli/` | executable (bin) | `lib/bpmn_cli.dart` (empty barrel) | `bpmn_parser`, `bpmn_sembast`, `bpmn_application` |

The three outer packages all pull `bpmn_domain`/`bpmn_application` via git
(`github.com/staylorx/<pkg>`, `ref: main`), and the workspace members use
`resolution: workspace` so the Melos builds resolve them together.

## Plumbing (roots of dependency edge in / out)

- `bpmn_domain` — exports only its own `src/`; no imports of any bpmn package.
  Innermost leaf.
- `bpmn_application` — its barrel re-exports `package:bpmn_domain/bpmn_domain.dart`
  plus its own `src/` (failures, value objects, repository contracts, use cases).
- `bpmn_infrastructure` (root) — a workspace meta-package (no `lib`), so it is
  not itself a public library.
- `bpmn_parser` — `lib/bpmn_parser.dart` barrel: `parse_exception`, cd + wfm
  parsers, file repositories, `file_service`.
- `bpmn_sembast` — `lib/bpmn_sembast.dart` barrel: codecs (`cd_codec`,
  `wf_codec` — exposed `show encodeX/decodeX`) + sembast repositories.
- `bpmn_cli` — `lib/bpmn_cli.dart` is an empty `library;` stub; real entry is
  the executable `bin/bpmn.dart` (`executables.bpmn: bpmn_cli`), currently a
  `print("Hello, BPMN!")` placeholder.

## Public entry points (barrels)

Five of the six packages have a public barrel at `lib/<package_name>.dart`:

1. `bpmn_domain/lib/bpmn_domain.dart` — value objects (node_id, package_path,
   stereotype, wf_type_ref, import_statement, timer_condition), flow element,
   entity groups (gateway, event, task/subprocess/loop, data/io/notification/
   operation, sequence_flow, process), cd (class-diagram) classifiers, and the
   sealed `WorkflowFailure` hierarchy.
2. `bpmn_application/lib/bpmn_application.dart` — re-exports the domain barrel
   + application failures, value objects, repository contracts, and use cases.
3. `bpmn_parser/lib/bpmn_parser.dart` — parser layer barrel (see above).
4. `bpmn_sembast/lib/bpmn_sembast.dart` — db layer barrel (see above).
5. `bpmn_cli/lib/bpmn_cli.dart` — empty barrel; public surface is `bin/bpmn.dart`.

`bpmn_infrastructure` has no barrel (workspace root only).

## Internal library structure (per package)

- `bpmn_domain/lib/src/` — `value_objects/`, `cd/`, `entities/`, `failures/`.
  Internals mirror the barrel grouping exactly; every public type is exposed
  via the single barrel.
- `bpmn_application/lib/src/` — `value_objects/`, `repositories/`, `use_cases/`,
  `failures/`. One barrel for the whole layer.
- `bpmn_parser/lib/src/` — `wfm/` (workflow_parser), `cd/`
  (class_diagram_parser), `repositories/` (file_*_repository), `file_service.dart`,
  `parse_exception.dart`. One barrel.
- `bpmn_sembast/lib/src/` — `codec/` (cd_codec, wf_codec) and two
  sembl_*_repository files. One barrel.
- `bpmn_cli/` — no `src/`; a `bin/` executable plus an empty lib barrel.

## Architecture test infrastructure (dart_arch_test)

There is **no architecture test infrastructure** anywhere in the group:

- `dart_arch_test` appears in **no pubspec** (neither dependency nor
  dev_dependencies) across all six packages.
- No test file invokes it; no `*arch*test*.dart` files exist.
- Test surface today: `bpmn_domain/test/bpmn_domain_test.dart`,
  `bpmn_application/test/bpmn_application_test.dart`, and the
  `bpmn_infrastructure` member tests (`parser/test/...`,
  `sembast/test/...`). None of these assert dependency direction or graph
  cycles.

So the answer to "single package / single barrel?" is **no**: the codebase is
already a multi-package, multi-barrel clean-architecture group. A
`dart_arch_test` boundary/cycle test is currently absent and would no longer be
vacuous — there are now real cross-package edges (domain ← application ←
parser/sembast) worth asserting, which is the trigger condition recorded in the
backlog for making such a test load-bearing.
