# ADR-001: dart_arch_test boundary-direction + cycle-freedom test

Status: Accepted
Date: 2026-10-11
Applies to: `bpmn_domain` (repo root)
Reference: Dart/Flutter Bible §2 (topology / dependency direction) and §9 step 7
(architecture test as part of `dart test`); current structure report
`docs/architecture/current-structure.md`.

## Context

The Dart/Flutter Bible, in §2, makes dependency direction a first-class
architectural property: inner layers may depend on nothing outward, and the
resolved import graph must be acyclic. Section 9 step 7 turns that property
into a test: a `dart_arch_test` boundary-direction and cycle-freedom test that
runs as part of `dart test`, asserting each package's allowed dependency edges
over the resolved import graph and failing on any cycle.

`bpmn_domain` today is a **single package with a single public barrel**
(`lib/bpmn_domain.dart`). All public types are exposed through that one barrel;
`lib/src/` holds internal libraries whose import edges are all intra-package
(entities reference value objects and flow elements via relative imports, and
so on). There is no cross-package dependency edge and no second package inside
the repo for a boundary-direction rule to constrain. A `dart_arch_test`
boundary-direction test added today would have no real edges to assert and
would pass trivially regardless of the code's structure — i.e. it would be a
**vacuous** test. That is exactly the concern recorded in `BACKLOG.md`
("...with one package and a single barrel there is no cross-package edge to
assert, so the test would be vacuous today — it becomes load-bearing the moment
the roadmapped parser/validator land in their own package").

The parser/validator are not yet in this repo's own package: they are
roadmapped to land here as a second package.

## Decision

**Defer adding the `dart_arch_test` boundary-direction + cycle-freedom test
until a second package is added to this repo.**

No `dart_arch_test` dependency is added to `pubspec.yaml` and no architecture
test file is created now. Instead, a `TODO` comment is placed in the `test/`
directory (see below) recording the trigger and pointing at this ADR.

Trigger condition (stated explicitly): **when a second package is added to the
repo** — specifically when the roadmapped parser/validator land in their own
Dart package and create a real cross-package dependency edge to assert. At that
point `dart_arch_test` must be added as a dev dependency and a boundary +
cycle-freedom test added that runs in `dart test`, asserting that the outer
package may depend only inward (and never the reverse) and that the combined
import graph is acyclic.

### What the eventual test will assert

When the trigger fires, the test should assert:

- **Boundary direction:** all imports from the barrel (and any package) are
  allowed only in the inward direction — the domain package (innermost) imports
  nothing from the parser/validator package; the parser/validator package may
  import the domain barrel but the domain must never import the
  parser/validator. In `dart_arch_test` terms: define the one allowed edge
  (parser/validator → bpmn_domain) and forbid the reverse.
- **Cycle freedom:** the resolved import graph across both packages contains no
  cycle.

### Deferred-implementation note (this repo)

Per the companion implementation card, because this ADR chooses *defer*, the
`test/` directory carries only a `TODO` comment pointing here:

```
// TODO(dart_arch_test): Add the boundary-direction + cycle-freedom
// architecture test (dart_arch_test) per ADR-001 when a second package
// (the roadmapped parser/validator) lands in this repo.
```

## Consequences

### Positive

- **No vacuous test in the suite.** We do not ship a `dart_arch_test` that
  asserts nothing, which would give false confidence and would have to be torn
  down the moment real edges appear. The vacuous-test concern that motivated
  this decision is resolved by not adding the test before it can bite.
- **The doctrine point is still recorded.** The bible §2/§9 step 7 requirement
  is not abandoned — it is captured in this ADR and the `TODO`, so the
  architecture gate is not silently forgotten when the package lands.
- **No dependency churn.** We avoid adding a dev dependency today that would be
  unused by any load-bearing assertion until the second package exists.

### Negative / costs

- **No automated architecture gate right now.** Until the parse/validator
  package lands, the import graph is only guarded by the analyzer (which
  already rejects intra-package import cycles) and by code review, not by a
  dedicated `dart test` architecture assertion.
- **The trigger depends on a roadmap item.** If the parser/validator package is
  repeatedly delayed, the dependency-direction guarantee stays manual. This is
  an accepted, bounded risk: the single-package barrel structure makes the
  boundary rule trivial (one inward direction, enforced by construction), so
  the risk is low until the second package arrives.

## Why not add now (addresses the vacuous-test concern)

The bible's step-7 test is load-bearing because it asserts *real* cross-package
dependency edges. With one package and one barrel, every legal import is already
"from the barrel or internal-to-internal," all of which any reasonable rule
would allow — the test cannot fail, so it carries no signal and would be
maintained as dead weight until the second package changes the problem
completely. Deferring is the honest reading of the bible's intent: the test
exists to govern the seam where packages meet, and that seam does not exist in
this repo yet. The single-package cycle-freedom property is already enforced by
the Dart analyzer's cyclic-import diagnostics, so the one non-vacuous check the
bible names is not lost by deferring `dart_arch_test`.
