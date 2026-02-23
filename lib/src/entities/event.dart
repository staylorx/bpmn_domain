import 'package:equatable/equatable.dart';
import '../value_objects/node_id.dart';
import '../value_objects/stereotype.dart';
import 'event_trigger.dart';
import 'flow_element.dart';
import 'io_requirement.dart';

// ---------------------------------------------------------------------------
// Event role
// ---------------------------------------------------------------------------

/// The positional role of an event within a process flow.
///
/// | Role           | BPMN term             | Valid locations                        |
/// |----------------|-----------------------|---------------------------------------|
/// | [start]        | Start event           | Must have no incoming flows           |
/// | [end]          | End event             | Must have no outgoing flows           |
/// | [intermediate] | Intermediate event    | Between start and end; must have ≥1 in + out |
///
/// The DSL syntax:
/// ```
/// start event ReceiveOrder catch;
/// end event OrderCompleted;
/// event OrderDelivered;          // intermediate — no start/end keyword
/// ```
enum EventRole {
  /// A start event initiates the process.  It has no incoming flows and
  /// one or more outgoing flows.  In the top-level process only a *catch*
  /// start event is allowed; a *throw* start event is a context-condition
  /// violation.
  start,

  /// An end event concludes one path of the process.  It has one or more
  /// incoming flows and no outgoing flows.  End events cannot be catching.
  end,

  /// An intermediate event occurs *within* a flow between start and end.
  /// It must have at least one incoming and at least one outgoing flow.
  intermediate,
}

// ---------------------------------------------------------------------------
// Event direction
// ---------------------------------------------------------------------------

/// Whether an event *catches* (listens for) or *throws* (emits) its trigger.
///
/// - **catch** — the process waits for the specified trigger before
///   proceeding.  Start events and boundary events are always catching.
/// - **throw** — the process actively emits the trigger.  End events and
///   intermediate throw events send the trigger into the environment.
///
/// Intermediate events that are neither `catch` nor `throw` are represented
/// by [EventDirection.unspecified]; the grammar allows this but context
/// conditions require intermediate events to be one or the other.
enum EventDirection {
  /// The event listens for an external trigger.
  catch_,

  /// The event emits a trigger into the environment.
  throw_,

  /// No explicit direction was specified in the source.
  unspecified,
}

// ---------------------------------------------------------------------------
// CompensationHandler
// ---------------------------------------------------------------------------

/// References the compensating activity that should run to undo the effects
/// of the activity to which a boundary compensation event is attached.
///
/// Written in the DSL as `catch compensate ActivityName with HandlerActivity`:
/// ```
/// boundary event PossibleCancellation
///   catch compensate ProcessOrder with RollbackOrderProcessing;
/// ```
///
/// Here [compensatedActivity] = `ProcessOrder` and
/// [handlerActivity] = `RollbackOrderProcessing`.
class CompensationHandler with EquatableMixin {
  /// The activity whose effects should be undone.
  final NodeId compensatedActivity;

  /// The activity that performs the compensation.
  final NodeId handlerActivity;

  const CompensationHandler({
    required this.compensatedActivity,
    required this.handlerActivity,
  });

  @override
  List<Object?> get props => [compensatedActivity, handlerActivity];
}

// ---------------------------------------------------------------------------
// WfEvent entity
// ---------------------------------------------------------------------------

/// A **workflow event** represents something that *happens* during the
/// execution of a process — a trigger condition that is either received
/// (caught) or emitted (thrown).
///
/// Events are the primary mechanism for modelling:
///
/// - **Process entry/exit points** (`start event`, `end event`)
/// - **Reactive behaviour** (intermediate catch events waiting for messages,
///   timers, signals, etc.)
/// - **Exception handling** (boundary events on tasks / subprocesses that
///   interrupt or compensate on error/cancellation)
/// - **Compensation** (compensation boundary events and compensation end
///   events that undo completed activities)
///
/// ## Roles and positions
///
/// | [role]       | Must be catch? | In-flow? | Out-flow? |
/// |--------------|----------------|----------|-----------|
/// | start        | yes            | 0        | ≥1        |
/// | end          | no (throw only)| ≥1       | 0         |
/// | intermediate | either         | ≥1       | ≥1        |
///
/// ## Boundary events
///
/// When [isBoundary] is `true` the event is attached to an activity
/// (task or subprocess) rather than living in the normal flow.  Boundary
/// events *catch* their trigger and route the flow out of the activity.
/// Interrupting boundary events also cancel the activity; non-interrupting
/// ones ([nonInterrupt] = `true`) do not.
///
/// ## Example DSL snippets
///
/// ```
/// // Simple start / end
/// start event ReceiveOrder catch;
/// end event OrderCompleted;
///
/// // Intermediate throw (signal broadcast)
/// event PaymentConfirmed throw signal PaymentSignal;
///
/// // Boundary event on a task
/// boundary event PossibleCancellation
///   catch compensate ProcessOrder with RollbackOrderProcessing;
///
/// // Timer catch event in a subprocess
/// event DeadlineReached catch timer [after PT2H];
///
/// // Non-interrupting boundary escalation event
/// event SLAWarning catch noninterrupt escalation SLABreach;
/// ```
class WfEvent with EquatableMixin implements FlowElement {
  /// The unique name of this event within its enclosing scope.
  @override
  final NodeId id;

  /// Where this event sits in the process flow.
  final EventRole role;

  /// Whether the event catches or throws its trigger.
  final EventDirection direction;

  /// The optional trigger that causes or characterises this event.
  /// `null` means the event is a **none** event — it has no specific
  /// trigger and simply represents a point in time.
  final EventTrigger? trigger;

  /// Access modifier and stereotype annotations.
  final WfModifier modifier;

  /// Whether this event is a boundary event attached to an activity.
  final bool isBoundary;

  /// Whether this boundary event is **non-interrupting** (only meaningful
  /// when [isBoundary] is `true`).  Non-interrupting boundary events do not
  /// cancel the host activity when they fire.
  final bool nonInterrupt;

  /// The compensation handler for `compensate` boundary events.
  final CompensationHandler? compensationHandler;

  /// Optional operation reference used for message events in executable
  /// processes (links the event to a [WfOperation] that handles the message).
  final NodeId? operationRef;

  /// Optional I/O data set associated with the event.
  final WfIOSet? ioSet;

  const WfEvent({
    required this.id,
    required this.role,
    this.direction = EventDirection.unspecified,
    this.trigger,
    this.modifier = WfModifier.none,
    this.isBoundary = false,
    this.nonInterrupt = false,
    this.compensationHandler,
    this.operationRef,
    this.ioSet,
  });

  // Convenience constructors ---------------------------------------------------

  /// A simple **none start** event (no trigger).
  factory WfEvent.start(String name) => WfEvent(
        id: NodeId(name),
        role: EventRole.start,
        direction: EventDirection.catch_,
      );

  /// A simple **none end** event (no trigger).
  factory WfEvent.end(String name) => WfEvent(
        id: NodeId(name),
        role: EventRole.end,
        direction: EventDirection.throw_,
      );

  /// A **terminate end** event that cancels all active branches.
  factory WfEvent.terminate(String name) => WfEvent(
        id: NodeId(name),
        role: EventRole.end,
        direction: EventDirection.throw_,
        trigger: const TerminateTrigger(),
      );

  /// A simple **none intermediate** event (marker in the flow).
  factory WfEvent.intermediate(String name) => WfEvent(
        id: NodeId(name),
        role: EventRole.intermediate,
      );

  /// A **message catch start** event — the process starts when a message
  /// arrives.
  factory WfEvent.messageCatchStart(String name, String messageName) => WfEvent(
        id: NodeId(name),
        role: EventRole.start,
        direction: EventDirection.catch_,
        trigger: NotificationTrigger(
          kind: NotificationKind.message,
          notificationName: NodeId(messageName),
        ),
      );

  /// A **timer intermediate catch** event.
  factory WfEvent.timerCatch(String name, String timerCondition) => WfEvent(
        id: NodeId(name),
        role: EventRole.intermediate,
        direction: EventDirection.catch_,
        trigger: TimerTrigger(condition: timerCondition),
      );

  /// A **compensation boundary** event attached to an activity.
  factory WfEvent.compensationBoundary({
    required String name,
    required String compensatedActivity,
    required String handlerActivity,
    bool nonInterrupt = false,
  }) =>
      WfEvent(
        id: NodeId(name),
        role: EventRole.intermediate,
        direction: EventDirection.catch_,
        isBoundary: true,
        nonInterrupt: nonInterrupt,
        compensationHandler: CompensationHandler(
          compensatedActivity: NodeId(compensatedActivity),
          handlerActivity: NodeId(handlerActivity),
        ),
        trigger: CompensateTrigger(activity: NodeId(compensatedActivity)),
      );

  /// An **error end** event that throws a named error.
  factory WfEvent.errorEnd(String name, String errorName) => WfEvent(
        id: NodeId(name),
        role: EventRole.end,
        direction: EventDirection.throw_,
        trigger: NotificationTrigger(
          kind: NotificationKind.error,
          notificationName: NodeId(errorName),
        ),
      );

  // Derived properties ---------------------------------------------------------

  /// `true` if this is a start event.
  bool get isStart => role == EventRole.start;

  /// `true` if this is an end event.
  bool get isEnd => role == EventRole.end;

  /// `true` if this is an intermediate event.
  bool get isIntermediate => role == EventRole.intermediate;

  /// `true` if this event has no trigger (BPMN "none" event).
  bool get isNoneEvent => trigger == null;

  /// `true` if this is a timer event.
  bool get isTimer => trigger is TimerTrigger;

  /// `true` if this is a message event.
  bool get isMessage =>
      trigger is NotificationTrigger &&
      (trigger as NotificationTrigger).kind == NotificationKind.message;

  @override
  List<Object?> get props => [
        id,
        role,
        direction,
        trigger,
        modifier,
        isBoundary,
        nonInterrupt,
        compensationHandler,
        operationRef,
        ioSet,
      ];
}
