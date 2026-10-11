# ADR-0003: Convert non-conforming single-positional constructors to named parameters

Status: Accepted
Date: 2026-10-11
Applies to: `bpmn_domain` (`lib/src/entities/**`, `lib/src/value_objects/**`, `lib/src/cd/**`, `lib/src/failures/workflow_failure.dart`)
Reference: single-positional audit report `audit_report.md` (task `t_0cecd5fc`); Dart/Flutter Bible §2.5 ("Dart parameter style", `02-toolchain.md`), §1.4 (`01-architecture.md`), checklist 10.11 (`10-review-checklist.md`)

## Context

The audit (task `t_0cecd5fc`) catalogued **62 single-positional constructors** across
`bpmn_domain`: 43 in entities/value_objects/cd and 19 `WorkflowFailure` leaf
constructors. The Bible's parameter rule is unconditional:

> **Named parameters, always** — with exactly three exceptions: a single positional
> parameter named `ref`, `message`, or `value`. (§2.5)

The three-word exception list is the whole carve-out. The Bible draws the line at
the **parameter name**, not at "value object vs. behaviour call site." The open
question is whether some of these constructors already conform via those three
names, and whether the rest merit a *sanctioned deviation* or conversion.

## Verdict on the grace names

Re-checking every constructor against the exact exception list, **three** already
conform and need **no change**:

| Constructor | Param name | Verdict |
|---|---|---|
| `NodeId(this.value)` (`value_objects/node_id.dart:23`) | `value` | conforms (exception) |
| `CronTimerCondition(this.value)` (`value_objects/timer_condition.dart:237`) | `value` | conforms (exception) |
| `FlowTarget.element(NodeId ref, …)` (`entities/sequence_flow.dart:96`) | `ref` | conforms (exception) |

These stay **positional**, matching the author's intent (`NodeId('x')` is natural
Dart and the Bible explicitly permits it). The `value`/`ref` grace names resolve
the bulk of the "obviously natural" cases — which is exactly why the Bible
carved them out.

## Decision

**CONVERT.** Every remaining single-positional constructor (whose sole — or, for
the named-exception factories, leading — positional parameter is **not** one of
`ref`/`message`/`value`) moves to a `required` named parameter. Keep the existing
parameter/field name under the named form wherever the audit does not dictate a
better one. This is **not** a sanctioned deviation; it is a conformance migration.

Rationale, in priority order:

1. **The Bible is explicit and grants no general value-object exception.** §2.5
   says "always" and enumerates exactly three names. It deliberately chose
   `ref`/`message`/`value` and *not* a blanket "value construction is exempt"
   carve-out. The operator's own reading of the rule ("single params named
   `value` are fine as positional") matches the written exception list exactly
   — confirming the rule already captures the natural cases and that the rest
   are genuine, unmatched violations.
2. **Self-documenting signatures.** For `PackagePath(['de','example'])`,
   `DeadNode(NodeId('X'))`, or `WfLoopCardinality.count(5)` a caller cannot tell
   what the lone argument is without the doc. `PackagePath(segments: [...])`,
   `DeadNode(nodeId: ...)`, `WfLoopCardinality.count(n: 5)` document themselves —
   the Bible's stated purpose.
3. **Repo trajectory is conform-to-bible.** Every sibling doctrine decision in
   this run converted rather than parked a deviation: `shouldly` (CONVERT,
   `297b61a`), README doctrine restatement (trim, not deviation, `t_66b651fb`),
   `EquatableMixin` → `with Equatable` (converted, `t_edef216c`), test names →
   Given/When/Then (converted). A *new* sanctioned deviation here would invert
   the established pattern without a doctrine-shaped reason.
4. **The "keep" case rests on a premise the Bible rejects.** "A lone positional
   argument on a value object is natural Dart" is true — and the Bible already
   accommodates it *for the names that are genuinely unambiguous* (`value`,
   `ref`, `message`). For the rest, named parameters are the intended form, and
   the churn is bounded: the highest-frequency constructor (`NodeId`, 197 call
   sites) is in the conform set and does **not** move.

## Migration spec (for task `t_d7d37d5f`)

**General rule:** for each constructor below, the single (or leading) positional
parameter becomes `required <Type> <name>`; call sites change from
`Ctor(<arg>)` to `Ctor(<name>: <arg>)`. Named-exception factories keep their
existing additional named parameters; only the leading positional one converts.

### Conform set — DO NOT CHANGE (keep positional)

- `NodeId(this.value)` — `value`
- `CronTimerCondition(this.value)` — `value`
- `FlowTarget.element(NodeId ref, {FlowCondition? condition})` — `ref`

### Convert set — entities & value objects & cd

| Constructor (file) | Current param | New signature |
|---|---|---|
| `QualifiedNodeId(this.segments)` `node_id.dart:46` | `this.segments` | `{required this.segments}` |
| `QualifiedNodeId.parse(String dotSeparated)` `node_id.dart:49` | `String dotSeparated` | `{required String dotSeparated}` |
| `PackagePath(this.segments)` `package_path.dart:20` | `this.segments` | `{required this.segments}` |
| `PackagePath.parse(String dotSeparated)` `package_path.dart:26` | `String dotSeparated` | `{required String dotSeparated}` |
| `Stereotype.incarnates(String referenceName)` `stereotype.dart:37` | `String referenceName` | `{required String referenceName}` |
| `AtTimerCondition(this.time)` `timer_condition.dart:106` | `this.time` | `{required this.time}` |
| `AfterPeriodCondition(this.period)` `timer_condition.dart:168` | `this.period` | `{required this.period}` |
| `WfTypeRef(this.expression)` `wf_type_ref.dart:29` | `this.expression` | `{required this.expression}` |
| `WfTypeRef.named(String name)` `wf_type_ref.dart:32` | `String name` | `{required String name}` (inner `=> WfTypeRef(expression: name)`) |
| `CdEnumConstant(this.name)` `cd_classifier.dart:211` | `this.name` | `{required this.name}` |
| `CdClass.publicData(String name, {attributes})` `cd_classifier.dart:126` | `String name` | `{required String name, attributes}` |
| `WfEvent.start(String name)` `event.dart:210` | `String name` | `{required String name}` |
| `WfEvent.end(...)` `event.dart:217` | `String name` | `{required String name}` |
| `WfEvent.terminate(...)` `event.dart:224` | `String name` | `{required String name}` |
| `WfEvent.intermediate(...)` `event.dart:232` | `String name` | `{required String name}` |
| `WfGateway.splitXor(String name)` `gateway.dart:248` | `String name` | `{required String name}` |
| `WfGateway.mergeXor(...)` `gateway.dart:255` | `String name` | `{required String name}` |
| `WfGateway.splitAnd(...)` `gateway.dart:262` | `String name` | `{required String name}` |
| `WfGateway.mergeAnd(...)` `gateway.dart:269` | `String name` | `{required String name}` |
| `WfGateway.splitIor(...)` `gateway.dart:276` | `String name` | `{required String name}` |
| `WfGateway.splitReceiveAll(...)` `gateway.dart:283` | `String name` | `{required String name}` |
| `WfGateway.splitReceiveFirst(...)` `gateway.dart:290` | `String name` | `{required String name}` |
| `WfDataSet(this.items)` `io_requirement.dart:85` | `this.items` | `{required this.items}` |
| `WfDataSet.single(WfDataIO item)` `io_requirement.dart:88` | `WfDataIO item` | `{required WfDataIO item}` |
| `WfLoopCardinality.count(int n)` `loop_characteristic.dart:127` | `int n` | `{required int n}` |
| `WfLoopCardinality.expression(String expr)` `loop_characteristic.dart:131` | `String expr` | `{required String expr}` |
| `WfLoopCardinality.collection(String name)` `loop_characteristic.dart:135` | `String name` | `{required String name}` |
| `WfMILoop.parallelOver(String collectionName)` `loop_characteristic.dart:285` | `String collectionName` | `{required String collectionName}` |
| `WfMILoop.sequential(int count)` `loop_characteristic.dart:291` | `int count` | `{required int count}` |
| `WfStandardLoop.whileLoop(String condition, {max})` `loop_characteristic.dart:61` | `String condition` | `{required String condition, max}` |
| `WfStandardLoop.untilLoop(String condition, {max})` `loop_characteristic.dart:69` | `String condition` | `{required String condition, max}` |
| `ExpressionCondition(this.expression)` `sequence_flow.dart:39` | `this.expression` | `{required this.expression}` |
| `FlowBlock(this.branches)` `sequence_flow.dart:150` | `this.branches` | `{required this.branches}` |
| `FlowTarget.gateway(WfInlineGateway gw, {condition})` `sequence_flow.dart:100` | `WfInlineGateway gw` | `{required WfInlineGateway gw, condition}` |
| `FlowTarget.block(FlowBlock blk, {condition})` `sequence_flow.dart:104` | `FlowBlock blk` | `{required FlowBlock blk, condition}` |
| `WfSubProcess.embedded(String name)` `subprocess.dart:195` | `String name` | `{required String name}` |
| `WfSubProcess.transaction(String name)` `subprocess.dart:199` | `String name` | `{required String name}` |
| `WfSubProcess.adhoc(String name, {completionCondition, parallel})` `subprocess.dart:205` | `String name` | `{required String name, completionCondition, parallel}` |
| `TaskTypeAttributes.manual(List<String> resources)` `task.dart:120` | `List<String> resources` | `{required List<String> resources}` |
| `WfTask.generic(String name)` `task.dart:239` | `String name` | `{required String name}` |

### Convert set — WorkflowFailure leaves (`workflow_failure.dart`)

Each named by the same rule (`this.<field>` → `{required this.<field>}`):

- With live call sites: `DeadNode(nodeId)`, `InfiniteLoop(loopNodes)`,
  `LackOfSync(mergeGatewayId)`, `ProcessNotSound(reason)`,
  `TaskNotIncarnated(taskId)`.
- No call sites (declared only): `AdHocSubProcessEmpty(subProcessId)`,
  `AdHocSubProcessHasStartOrEndEvent(subProcessId)`,
  `BoundaryEventHasIncomingFlow(eventId)`, `CompensationActivityHasFlow(activityId)`,
  `DefaultBranchNotLast(gatewayId)`, `DisconnectedComponent(componentNodes)`,
  `EndEventHasOutgoingFlow(eventId)`, `EndEventIsCatching(eventId)`,
  `EventGatewayIsNotSplit(gatewayId)`, `EventGatewayMixedTargetTypes(gatewayId)`,
  `EventSubProcessHasFlow(subProcessId)`, `MultipleDefaultBranches(splitGatewayId)`,
  `StartEventIsThrowing(eventId)`, `SyncDeadlock(mergeGatewayId)`.

## Consequences

- **Versioned APIs / wiring.** All internal call sites, the sembast codec
  (`wf_codec.dart`, `cd_codec.dart`), the petitparser workflow parser
  (`workflow_parser.dart`), `bpmn_application` (`check_conformance_use_case.dart`)
  and every test update in lockstep; the audit's call-site lists enumerate each.
- **No behaviour change.** This is a purely Syntax-level signature migration;
  value equality (`Equatable`) and semantics are untouched. Verify with the full
  `dart test` suite and `dart analyze --fatal-infos --fatal-warnings`.
- **`NodeId`, `CronTimerCondition`, `FlowTarget.element` keep positional form.**
  The three Bible-grace constructors are explicitly out of scope and must not be
  renamed — their 214 combined call sites stay untouched.
- **BACKLOG update.** The deviation entry (`BACKLOG.md` "Open — deviations"
  section) is closed **RESOLVED** (CONVERT) with a pointer to this ADR; see
  task `t_df26c8ee`.
