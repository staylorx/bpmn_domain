# bpmn_domain

A clean-architecture domain model influenced from the MontiCore **Workflow DSL** (`.wfm`) and **CD4Analysis Class Diagram** (`.cd`) languages. Provides richly documented, immutable domain entities ready to be consumed by a parser, validator, and conformance-checker layer above.

---

## Table of Contents

1. [Background](#background)
2. [Architecture overview](#architecture-overview)
3. [Package layout](#package-layout)
4. [Workflow domain entities](#workflow-domain-entities)
   - [Compilation unit & process](#compilation-unit--process)
   - [Lanes](#lanes)
   - [Tasks](#tasks)
   - [Events & triggers](#events--triggers)
   - [Gateways](#gateways)
   - [Sequence flows](#sequence-flows)
   - [Subprocesses & call activities](#subprocesses--call-activities)
   - [Data objects, notifications, operations](#data-objects-notifications-operations)
   - [I/O requirements](#io-requirements)
   - [Loop characteristics](#loop-characteristics)
   - [Timer conditions](#timer-conditions)
   - [Value objects](#value-objects)
5. [Class diagram domain entities](#class-diagram-domain-entities)
6. [Failure types (CoCos)](#failure-types-cocos)
7. [Test fixtures](#test-fixtures)
8. [Dependencies](#dependencies)
9. [Roadmap](#roadmap)

---

## Background

The [MontiCore BPMN project](https://github.com/MontiCore/bpmn) defines a textual DSL for BPMN 2.0 processes:

- **`.wfm` files** — Workflow Model files describing processes, activities, events, gateways, and data flows.
- **`.cd` files** — CD4Analysis Class Diagram files defining the type system referenced by workflow data objects.

This package contains the **pure domain layer** — no parsing, no I/O. It models every construct found in the MontiCore grammar and example files so that a parser can produce fully typed domain objects, and a validator can check them against all known context conditions.

---

## Architecture overview

```
┌───────────────────────────────────────────────────┐
│                   (future layers)                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────┐ │
│  │  .wfm parser │  │  .cd parser  │  │ CoCo     │ │
│  │ (petitparser)│  │ (petitparser)│  │ validator│ │
│  └──────┬───────┘  └──────┬───────┘  └────┬─────┘ │
│         │                 │               │        │
│  ┌──────▼─────────────────▼───────────────▼──────┐ │
│  │               bpmn_domain (this package)       │ │
│  │  WorkflowCompilationUnit  CdCompilationUnit    │ │
│  │  WfProcess / WfLane       CdClassDiagram       │ │
│  │  WfTask / WfEvent         CdClass / CdEnum     │ │
│  │  WfGateway / SequenceFlow CdAssociation        │ │
│  │  WorkflowFailure (sealed) …                    │ │
│  └───────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────┘
```

All domain entities are:

- **Immutable** — `final` fields, `const` constructors where possible.
- **Structurally equal** — via `equatable`.
- **Richly documented** — every class and field has a doc comment explaining the BPMN semantics and the DSL syntax that produces it.
- **Free of parsing logic** — the domain layer has no concept of source text, tokens, or grammars.

---

## Package layout

```
lib/
├── bpmn_domain.dart              ← barrel export (all public entities)
└── src/
    ├── value_objects/
    │   ├── node_id.dart          NodeId, QualifiedNodeId
    │   ├── package_path.dart     PackagePath
    │   ├── stereotype.dart       Stereotype, WfModifier, WfVisibility
    │   ├── wf_type_ref.dart      WfTypeRef
    │   ├── import_statement.dart ImportStatement
    │   └── timer_condition.dart  TimerCondition sealed hierarchy (5 variants)
    ├── entities/
    │   ├── flow_element.dart     FlowElement interface
    │   ├── process.dart          WfLane, WfProcess, WorkflowCompilationUnit
    │   ├── task.dart             WfTask, TaskType, TaskTypeAttributes
    │   ├── event.dart            WfEvent, EventRole, EventDirection, CompensationHandler
    │   ├── event_trigger.dart    EventTrigger sealed hierarchy (7 variants)
    │   ├── gateway.dart          WfGateway, WfInlineGateway, GatewayKind sealed
    │   ├── sequence_flow.dart    SequenceFlow, FlowTarget, FlowBlock, FlowCondition sealed
    │   ├── subprocess.dart       WfSubProcess, AdHocCharacteristics, WfCallActivity
    │   ├── loop_characteristic.dart  LoopCharacteristic sealed, WfStandardLoop, WfMILoop
    │   ├── io_requirement.dart   WfIORequirement sealed, WfIOSet, WfIORule, WfDataSet, WfDataIO
    │   ├── data_object.dart      WfDataObject, DataKind
    │   ├── notification.dart     WfNotification
    │   └── operation.dart        WfOperation
    ├── cd/
    │   ├── cd_visibility.dart    CdVisibility enum
    │   ├── cd_attribute.dart     CdAttribute (isDerived for `/` prefix)
    │   ├── cd_method.dart        CdMethod, CdMethodParameter
    │   ├── cd_association.dart   CdAssociation, CdMultiplicity, CdAssociationKind
    │   ├── cd_classifier.dart    CdClassifier interface, CdClass, CdInterface, CdEnum
    │   └── cd_class_diagram.dart CdClassDiagram, CdCompilationUnit
    └── failures/
        └── workflow_failure.dart WorkflowFailure sealed + ~25 typed CoCo subclasses
```

---

## Workflow domain entities

### Compilation unit & process

A `.wfm` file maps to a **`WorkflowCompilationUnit`** wrapping exactly one **`WfProcess`**:

```dart
// lib/src/entities/process.dart

WorkflowCompilationUnit(
  package: PackagePath.parse('de.monticore.bpmn.examples'),
  imports: [ImportStatement.wildcard('de.monticore.bpmn.cds.OrderToDelivery')],
  process: WfProcess(
    id: NodeId('OrderToDeliveryWorkflow'),
    ioRequirements: [...],
    elements: [...],
  ),
)
```

DSL source:

```
package de.monticore.bpmn.examples;
import de.monticore.bpmn.cds.OrderToDelivery.*;

process OrderToDeliveryWorkflow {
  data order:Order;
  ...
}
```

`WfProcess.fullyQualifiedName` → `"de.monticore.bpmn.examples.OrderToDeliveryWorkflow"`.

### Lanes

**`WfLane`** is a swimlane partition that groups `FlowElement`s by organisational role. Lanes are purely visual/organisational — they have no effect on token routing.

```
lane Sales {
  start event ReceiveOrder catch;
  service task ProcessOrder { webservice = ##webservice; }
}
lane Warehouse {
  manual task PrepareAndPackProducts { resources = order, products; }
}
```

### Tasks

**`WfTask`** is the atomic unit of work. The `TaskType` enum selects one of eight kinds:

| `TaskType` | DSL keyword    | Description                                |
| ---------- | -------------- | ------------------------------------------ |
| `generic`  | `task`         | Abstract / analysis only                   |
| `service`  | `service task` | Automated (web service / micro-service)    |
| `send`     | `send task`    | Sends a message to an external participant |
| `receive`  | `receive task` | Waits for an incoming message              |
| `user`     | `user task`    | Human + software interaction               |
| `manual`   | `manual task`  | Physical work, no software                 |
| `rule`     | `rule task`    | Business rule engine                       |
| `script`   | `script task`  | Inline script                              |

`TaskTypeAttributes` carries type-specific fields: `webservice`, `operation`, `message`, `resources`, `scriptFormat`, `script`.

Tasks may carry:

- **`boundaryEvents`** — `WfEvent`s attached to the task border (timers, errors, compensations).
- **`loop`** — a `LoopCharacteristic` for repeated or multi-instance execution.
- **`modifier`** — an `<<incarnates="X">>` stereotype for conformance checking.

```dart
WfTask.service(name: 'AuthoriseCard', webservice: '##webservice',
    operationName: 'authorisePayment')
```

### Events & triggers

**`WfEvent`** models start, end, and intermediate events. Key fields:

| Field                 | Type                   | Description                           |
| --------------------- | ---------------------- | ------------------------------------- |
| `role`                | `EventRole`            | `start`, `end`, or `intermediate`     |
| `direction`           | `EventDirection`       | `catch_`, `throw_`, or `unspecified`  |
| `trigger`             | `EventTrigger?`        | The trigger type; `null` = none event |
| `isBoundary`          | `bool`                 | Attached to a task/subprocess border  |
| `nonInterrupt`        | `bool`                 | Non-interrupting boundary event       |
| `compensationHandler` | `CompensationHandler?` | For compensate boundary events        |

**`EventTrigger`** is a sealed hierarchy with seven variants:

| Class                 | DSL keyword                       | Description                       |
| --------------------- | --------------------------------- | --------------------------------- |
| `CancelTrigger`       | `cancel`                          | Transaction cancellation          |
| `CompensateTrigger`   | `compensate X`                    | Compensation for activity X       |
| `ConditionalTrigger`  | `conditional`                     | Data condition                    |
| `TerminateTrigger`    | `terminate`                       | Cancels all active branches       |
| `TimerTrigger`        | `timer [...]`                     | Time-based (see timer conditions) |
| `NotificationTrigger` | `message/signal/error/escalation` | Named notification                |
| `MultipleTrigger`     | `multiple`                        | Multiple trigger types            |

`NotificationKind` selects the notification sub-type: `message`, `signal`, `error`, `escalation`.

**`CompensationHandler`** binds the compensated activity name to the handler activity:

```
boundary event CaptureFailed
  catch compensate CapturePayment with RefundPayment;
// compensatedActivity = CapturePayment, handlerActivity = RefundPayment
```

### Gateways

**`WfGateway`** is a named gateway declared as a standalone element. **`WfInlineGateway`** is anonymous and embedded in a flow path.

`GatewayDirection` is either `split` or `merge`. `GatewayKind` is a sealed hierarchy:

| Class                   | DSL keyword      | Split behaviour     | Merge behaviour        |
| ----------------------- | ---------------- | ------------------- | ---------------------- |
| `ExclusiveGateway`      | `xor`            | One path chosen     | First token wins       |
| `InclusiveGateway`      | `ior`            | One or more paths   | Waits for active paths |
| `ParallelGateway`       | `and`            | All paths           | Waits for all tokens   |
| `ExclusiveEventGateway` | `receive first`  | First event wins    | —                      |
| `ParallelEventGateway`  | `receive all`    | All events required | —                      |
| `ComplexGateway`        | `complex [expr]` | Guard expression    | Guard expression       |

```dart
WfGateway.splitXor('CaptureDecision')
WfGateway.mergeAnd('ChecksComplete')
WfGateway.splitReceiveFirst('WaitForPaymentOrTimeout')
```

### Sequence flows

**`SequenceFlow`** is an ordered list of **`FlowTarget`** steps. Each step targets one of:

- A named element by `NodeId` (`FlowTarget.element`)
- An anonymous `WfInlineGateway` (`FlowTarget.gateway`)
- A `FlowBlock` of branching sub-flows (`FlowTarget.block`)

Steps may carry a **`FlowCondition`**:

- `ExpressionCondition(expr)` — `[someExpression]`
- `DefaultCondition()` — `[_]` (last branch fallback)

**`FlowBlock`** contains multiple `SequenceFlow` branches enclosed in `{ … }`:

```
CaptureDecision
  -> {
       [checker.paymentValid] CapturePayment -> PaymentCaptured;
       [_] SendDeclineNotice  -> PaymentDeclined;
     };
```

```dart
SequenceFlow.linear('flow1', ['Start', 'TaskA', 'TaskB', 'End'])
```

### Subprocesses & call activities

**`WfSubProcess`** is a subprocess with its own internal flow. `SubProcessType` selects:

| Value         | DSL keyword        | Description                                       |
| ------------- | ------------------ | ------------------------------------------------- |
| `embedded`    | `subprocess`       | Standard embedded subprocess                      |
| `transaction` | `transaction`      | Transactional subprocess (cancel trigger support) |
| `adHoc`       | `adhoc`            | Ad-hoc subprocess — activities run in any order   |
| `event`       | `event subprocess` | Triggered by an event, not sequence flow          |

`AdHocCharacteristics` describes the ad-hoc ordering constraint and completion condition.

**`WfCallActivity`** reuses a named external process by reference (`calledElement`).

### Data objects, notifications, operations

**`WfDataObject`** — a named data item scoped to the process.

- `DataKind.transient` (`data`) — lives only during execution.
- `DataKind.persistent` (`store`) — survives process completion.

**`WfNotification`** — a typed named notification (`message`, `signal`, `error`, `escalation`).

**`WfOperation`** — a WSDL-like operation declaration with typed input/output parameters and thrown errors.

```
operation authorisePayment(
  in paymentRequest;
  out captureConfirmation
) throws CardDeclinedError;
```

### I/O requirements

**`WfIORequirement`** is a sealed hierarchy for data input/output declarations on tasks and events:

- `WfIOSet` — a named set of data items consumed or produced.
- `WfIORule` — a rule combining sets (`WfDataSet`) via `WfDataIO` (input/output associations).

### Loop characteristics

**`LoopCharacteristic`** is sealed:

- `WfStandardLoop(condition, testBefore)` — repeat while condition holds.
- `WfMILoop(cardinality, isParallel, ...)` — multi-instance: `count [expr] parallel` or `count [expr] sequential`.

### Timer conditions

**`TimerCondition`** is a sealed hierarchy of five variants:

| Class                  | DSL syntax         | Description                      |
| ---------------------- | ------------------ | -------------------------------- |
| `AtTimerCondition`     | `at HH:MM`         | Fire at a specific time of day   |
| `OnDateTimerCondition` | `on YYYY-MM-DD`    | Fire on a specific calendar date |
| `AfterPeriodCondition` | `after PTnH`       | Fire after a duration (ISO 8601) |
| `EveryTimeCondition`   | `every PTnH`       | Fire repeatedly at an interval   |
| `CronTimerCondition`   | `cron "* * * * *"` | Fire on a cron schedule          |

### Value objects

| Class             | Description                                                           |
| ----------------- | --------------------------------------------------------------------- |
| `NodeId`          | A simple unqualified name within a scope                              |
| `QualifiedNodeId` | A dotted qualified name (e.g. `de.monticore.bpmn.examples.MyProcess`) |
| `PackagePath`     | A dotted package path; supports `qualify(name)`                       |
| `ImportStatement` | A single-type or wildcard import declaration                          |
| `WfTypeRef`       | A type reference used in data object declarations                     |
| `Stereotype`      | A MontiCore stereotype annotation, e.g. `<<incarnates="X">>`          |
| `WfModifier`      | Combines visibility, stereotype, and `incarnates` data                |
| `WfVisibility`    | `public`, `protected`, `private`, `package`                           |

---

## Class diagram domain entities

The `.cd` language is MontiCore's CD4Analysis dialect. All types live under `lib/src/cd/`.

**`CdCompilationUnit`** → **`CdClassDiagram`** → classifiers + associations.

### Classifiers

`CdClassifier` is implemented by three classes:

| Class         | DSL keyword | Description                |
| ------------- | ----------- | -------------------------- |
| `CdClass`     | `class`     | Concrete or abstract class |
| `CdInterface` | `interface` | Interface                  |
| `CdEnum`      | `enum`      | Enumeration with constants |

Each `CdClass` / `CdInterface` carries:

- `attributes` — `CdAttribute` (type, name, visibility; `isDerived=true` for `/` prefix)
- `methods` — `CdMethod` with typed parameters
- `superTypes` — inherited type names
- `isAbstract`

### Associations

`CdAssociation` models directed relationships:

- `CdAssociationKind`: `association`, `composition`, `aggregation`
- `CdMultiplicity`: `one`, `optional`, `many`, `oneToMany`, `range(min, max)`
- Carries source/target type names and role names

### Derived attributes

The `/` prefix in `.cd` source marks a _derived_ attribute (computed from other data):

```
class LeaveEntry {
  /int workingDays;   // isDerived = true
}
```

---

## Failure types (CoCos)

`WorkflowFailure` is a sealed class with ~25 typed subclasses representing violations of MontiCore context conditions. All are in `lib/src/failures/workflow_failure.dart`.

Categories:

| Category             | Failures                                                                                                                                                                                               |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Activity             | `AdHocSubProcessEmpty`, `AdHocSubProcessHasStartOrEndEvent`, `CalledElementNotFound`, `CompensationActivityHasFlow`, `EventSubProcessHasFlow`, `EventSubProcessStartEventCount`, `LoopCountNotInteger` |
| Analysis (soundness) | `DeadNode`, `DisconnectedComponent`, `InfiniteLoop`, `LackOfSync`, `SyncDeadlock`, `ProcessNotSound`                                                                                                   |
| Event                | `StartEventIsThrowing`, `EndEventIsCatching`, `NoEndEventWithStartEvent`, `BoundaryEventHasIncomingFlow`                                                                                               |
| Flow                 | `MultipleDefaultBranches`, `DefaultBranchNotLast`, `EndEventHasOutgoingFlow`, `MergeGatewayTooFewIncomingFlows`, `SplitGatewayTooFewOutgoingFlows`, `UnresolvedNodeReference`                          |
| Gateway              | `EventGatewayMixedTargetTypes`, `EventGatewayIsNotSplit`                                                                                                                                               |
| Conformance          | `TaskNotIncarnated`, `ParallelBranchesClosedWithXor`                                                                                                                                                   |

Designed for use with `fpdart`:

```dart
Either<WorkflowFailure, WfProcess> result = validator.validate(process);
result.fold(
  (failure) => print('Invalid: ${failure.message}'),
  (process) => print('Process "${process.id}" is valid'),
);
```

---

## Test fixtures

Original fixture files (not copied from MontiCore) in `test/fixtures/`:

| File                     | Covers                                                                              |
| ------------------------ | ----------------------------------------------------------------------------------- |
| `LeaveRequest.wfm`       | Lanes, error notifications, user tasks, XOR gateway                                 |
| `PaymentProcessing.wfm`  | Timer boundary, compensation, AND parallel split, flow blocks                       |
| `DocumentReview.wfm`     | Ad-hoc subprocess, transaction subprocess, IOR gateway, non-interrupting escalation |
| `IncidentResponse.wfm`   | `receive first` event gateway, call activity, timer, signal start                   |
| `EmployeeOnboarding.wfm` | Reference model with `<<incarnates>>` points, standard loop, terminate end          |
| `OrderToDelivery.cd`     | Extended e-commerce domain: `Order`, `Product`, `Shipment`, associations            |
| `HRDomain.cd`            | HR domain: `LeaveEntry` with derived `/workingDays`, `MedicalCertificate`           |

Run all 124 tests:

```sh
dart test
```

---

## Dependencies

| Package       | Version     | Role                                              |
| ------------- | ----------- | ------------------------------------------------- |
| `equatable`   | `^2.0.7`    | Structural equality for all domain entities       |
| `fpdart`      | `^1.2.0`    | `Either`/`Option` for the validator/parser layers |
| `petitparser` | _(pending)_ | Combinator-based parser (next layer)              |

---

## Roadmap

### 1. `.wfm` parser (next)

Parse a raw `.wfm` string into a `WorkflowCompilationUnit` using `petitparser`.

Key grammar constructs to handle in order of complexity:

1. Package declaration and imports
2. Process header and modifier / stereotype
3. Data objects (`data`, `store`), notifications, operations
4. Lanes
5. Tasks (all 8 types) with boundary events and I/O
6. Events (start, end, intermediate, boundary) with all trigger types
7. Named gateways (all 6 kinds, both directions)
8. Sequence flows: linear chains, conditional blocks `{ [cond] A -> B; }`, inline gateways
9. Subprocesses (embedded, transaction, adhoc, event)
10. Call activities
11. Loop characteristics (`count [n] parallel`, standard loop)
12. Timer conditions (5 variants)

Entry point: `WorkflowParser.parse(String source)` → `Either<ParseFailure, WorkflowCompilationUnit>`.

### 2. `.cd` parser

Parse a raw `.cd` string into a `CdCompilationUnit`.

Constructs: package, classdiagram header, class/interface/enum declarations, attributes (with `/` derived prefix), methods, associations with multiplicity and role names.

Entry point: `ClassDiagramParser.parse(String source)` → `Either<ParseFailure, CdCompilationUnit>`.

### 3. Symbol resolution

Walk a `WorkflowCompilationUnit` and resolve all `WfTypeRef` names (in data objects, operation parameters, notification declarations) against the `CdClassifier`s imported from class diagram symbol tables.

Produces: enriched compilation unit or a list of `UnresolvedTypeReference` failures.

### 4. CoCo validator

Check a `WfProcess` against all the `WorkflowFailure` types. Returns `Either<List<WorkflowFailure>, WfProcess>`.

Each failure class corresponds to one or more MontiCore context conditions. The validator should be structured as individual CoCo checkers that can run independently.

### 5. Conformance checker

Given a concrete `WfProcess` and a reference `WfProcess`, check that:

- Every activity in the concrete model carries an `<<incarnates="X">>` stereotype.
- The incarnated name `X` exists in the reference model.
- The gateway structure does not violate conformance rules (e.g. `ParallelBranchesClosedWithXor`).

Returns `Either<List<WorkflowFailure>, ConformanceReport>`.
