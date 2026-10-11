# ADR-0001: Keep grouped sealed-family files as a sanctioned deviation

Status: Accepted
Date: 2026-10-11
Applies to: `bpmn_domain` (`lib/src/`)
Reference: sealed-family audit report `sealed_family_audit.md` (task `t_1fcd627f`); Dart/Flutter Bible §3.5 ("One class per file", `03-topology.md`) and §4 (sealed failure hierarchies, `04-functional-core.md`)

## Context

The Dart/Flutter Bible (§3.5) states **"One class per file, one file per class."**
`bpmn_domain` violates that rule throughout: 20 of its 27 `lib/src/**` files declare
more than one public type. The worst offenders are 7 files that host a **sealed**
parent class together with its leaf subclasses:

| File | Sealed parent | Leaf subclasses |
|---|---|---|
| `failures/workflow_failure.dart` | `WorkflowFailure` | 27 |
| `entities/gateway.dart` | `GatewayKind` | 6 |
| `entities/event_trigger.dart` | `EventTrigger` | 7 |
| `value_objects/timer_condition.dart` | `TimerCondition` | 5 |
| `entities/sequence_flow.dart` | `FlowCondition` | 2 |
| `entities/io_requirement.dart` | `WfIORequirement` | 2 |
| `entities/loop_characteristic.dart` | `LoopCharacteristic` | 2 |

Plus `cd/cd_classifier.dart` (abstract `CdClassifier` + 3 implementers), which is
**not** sealed and is therefore freely splittable (see Consequences).

An audit (`sealed_family_audit.md`) verified all 7 sealed families and all 7 encode +
7 decode exhaustive switches, and located them all in the sembast codec
(`bpmn_infrastructure/packages/sembast/lib/src/codec/`), not in the domain layer.

## Decision

**Option B — keep the grouped layout for sealed-family files, as an explicitly
sanctioned deviation, and PROHIBIT splitting it.**

For the 7 sealed-parent files the grouping is not a style choice: **Dart requires
every direct subtype of a `sealed` class to be declared in the same library (same
file) as the sealed parent.** Splitting the leaf subclasses out of these files is
therefore *impossible* without either (a) removing `sealed`, which breaks the
exhaustive-switch guarantee the Bible itself demands (§4: `switch` over the family
must be exhaustive), or (b) re-declaring the parent `sealed` but losing exhaustiveness
— neither is acceptable.

For the remaining multi-class files that contain **no sealed parent** (`process.dart`,
`subprocess.dart`, `task.dart`, `event.dart`, `cd_association.dart`, `cd_method.dart`,
`cd_class_diagram.dart`, `node_id.dart`, `stereotype.dart`, `cd_classifier.dart`,
`sequence_flow.dart`'s non-family helpers, etc.), "one class per file" remains the
rule in principle, but the bible's *intent* — navigable, well-factored units — is
already met by thematically grouping tightly coupled helpers with the entity they
support. See Consequences for the carve-outs that DO require action.

The rationale named in the task (exhaustive-switch readability and sealed hierarchy
shape) is confirmed by the audit: the sealed families stay intact in one file each,
and every exhaustive `switch` over them compiles and is unaffected by file layout.

## Consequences

- **7 sealed-family files stay grouped.** This is a permanent, language-mandated
  exception to §3.5. It is marked **SANCTIONED** in `BACKLOG.md`. New leaf
  subclasses added to an existing sealed family MUST be declared in the same file as
  their sealed parent; a `switch` over the family (principally in the codecs) must be
  kept exhaustive and re-linted on every addition.
- **No domain-layer switches are affected.** The audit found no exhaustive switch
  over any sealed family inside `bpmn_domain`; all live in the sembast codecs, which
  reference the types only and are unaffected by file layout.
- **`CdClassifier` is an abstract interface, not sealed.** Its implementers
  (`CdClass`/`CdInterface`/`CdEnum`) *could* legally be split out. This ADR keeps them
  grouped for now because they are tightly coupled helper types consumed together by
  the `cd_codec` classifier switch, and they are not a class-per-file risk worth
  churning. Flagged as a *known non-blocking* remainder: converting
  `cd_classifier.dart` and the other non-sealed multi-class files to one-class-per-file
  is legal and can proceed independently when desired, with no switch or test impact
  (audit §Summary shows only `cd_codec`/`wf_codec` consume these types).
- **Definition of "sanctioned".** The §3.5 rule is observed for all *unsealed*
  splittable types going forward; the sealed-family files are the documented exception.
  Do not un-seal a family to "fix" this deviation.
