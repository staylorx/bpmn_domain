import 'package:equatable/equatable.dart';
import '../value_objects/node_id.dart';

// ---------------------------------------------------------------------------
// Event trigger hierarchy
// ---------------------------------------------------------------------------

/// The abstract root for all event triggers in the Workflow DSL.
///
/// An event trigger describes *what* causes an event to fire (catch) or *what*
/// the event emits (throw).  According to the BPMN 2.0 standard the following
/// trigger types exist (the grammar omits the *link* trigger):
///
/// | Trigger class               | DSL keyword              | Catching? | Throwing? |
/// |-----------------------------|--------------------------|-----------|-----------|
/// | [CancelTrigger]             | `cancel`                 | ✓ (in tx) | ✓ (in tx) |
/// | [CompensateTrigger]         | `compensate`             | ✓         | ✓         |
/// | [ConditionalTrigger]        | `when [expr]`            | ✓         | ✗         |
/// | [TerminateTrigger]          | `terminate`              | ✗         | ✓ (end)   |
/// | [TimerTrigger]              | `timer [condition]`      | ✓         | ✗         |
/// | [NotificationTrigger]       | `message/signal/error/escalation name` | both | both |
/// | [MultipleTrigger]           | `one {…}` / `all {…}`   | ✓         | ✓         |
///
/// The trigger is stored on a [WfEvent] via the `trigger` field.
sealed class EventTrigger {
  const EventTrigger();
}

/// `cancel` — terminates a transaction subprocess.
///
/// A **cancel end event** inside a transaction subprocess triggers
/// cancellation of all active activities.  A **cancel boundary event**
/// attached to a transaction subprocess catches the cancellation and
/// reacts to it (e.g. by executing compensation).
///
/// Context condition: cancel events may only appear *within* a
/// `transaction` subprocess.
final class CancelTrigger extends EventTrigger with EquatableMixin {
  const CancelTrigger();

  @override
  List<Object?> get props => [];

  @override
  String toString() => 'cancel';
}

/// `compensate [activityName]` — undoes the effects of a previous activity.
///
/// When a compensation boundary event fires, the referenced [activity] (or,
/// if absent, the activity the event is attached to) must execute its
/// compensation handler.  The optional `async` flag means the compensation
/// is triggered asynchronously so the flow does not wait for it.
///
/// Example:
/// ```
/// event PossibleCancellation
///   catch compensate ProcessOrder with RollbackOrderProcessing;
/// ```
final class CompensateTrigger extends EventTrigger with EquatableMixin {
  /// The name of the activity to compensate (may be `null` for implicit
  /// self-compensation on a boundary event).
  final NodeId? activity;

  /// Whether compensation is asynchronous.
  final bool async;

  const CompensateTrigger({this.activity, this.async = false});

  @override
  List<Object?> get props => [activity, async];

  @override
  String toString() =>
      'compensate${activity != null ? ' ${activity!.value}' : ''}${async ? ' async' : ''}';
}

/// `when [expression]` — fires when a boolean expression becomes true.
///
/// Only valid as a **catch** trigger.  The expression is evaluated
/// periodically and the event fires the moment it becomes `true`.
///
/// Example:
/// ```
/// event InventoryRestocked catch when [stock.available > 0];
/// ```
final class ConditionalTrigger extends EventTrigger with EquatableMixin {
  /// The raw condition expression, e.g. `stock.available > 0`.
  final String condition;

  const ConditionalTrigger({required this.condition});

  @override
  List<Object?> get props => [condition];

  @override
  String toString() => 'when [$condition]';
}

/// `terminate` — ends the entire process immediately.
///
/// A **terminate end event** cancels all active tokens in the process
/// (including parallel branches and subprocesses).  It is only valid as an
/// **end** event trigger.
final class TerminateTrigger extends EventTrigger with EquatableMixin {
  const TerminateTrigger();

  @override
  List<Object?> get props => [];

  @override
  String toString() => 'terminate';
}

/// `timer [condition]` — fires based on a time specification.
///
/// The [condition] field stores the raw timer condition expression as
/// written in the source.  The grammar supports date, duration, cycle, and
/// deadline timer conditions via the `TimerConditions` component grammar.
///
/// Examples:
/// ```
/// event DailyReminder catch timer [every 1 day];
/// event DeadlineReached catch timer [on 2025-12-31];
/// event ProcessTimeout catch timer [after PT4H];   // ISO 8601 duration
/// ```
final class TimerTrigger extends EventTrigger with EquatableMixin {
  /// The raw timer condition expression.
  final String condition;

  const TimerTrigger({required this.condition});

  @override
  List<Object?> get props => [condition];

  @override
  String toString() => 'timer [$condition]';
}

/// `message | signal | error | escalation <name>` — notification-based trigger.
///
/// This trigger covers four BPMN 2.0 event types that communicate via a named
/// payload (a [WfNotification]):
///
/// - **message** — point-to-point communication between participants
/// - **signal** — broadcast communication to all listeners
/// - **error** — catches or throws a named error condition
/// - **escalation** — non-fatal escalation to a higher-level process
///
/// The [notificationName] references a `WFNotification` symbol in scope.
final class NotificationTrigger extends EventTrigger with EquatableMixin {
  /// The type of notification.
  final NotificationKind kind;

  /// Name of the [WfNotification] symbol carrying the payload.
  final NodeId notificationName;

  const NotificationTrigger({
    required this.kind,
    required this.notificationName,
  });

  @override
  List<Object?> get props => [kind, notificationName];

  @override
  String toString() => '${kind.name} ${notificationName.value}';
}

/// The four kinds of notification in the Workflow DSL.
enum NotificationKind {
  /// Point-to-point message between participants.
  message,

  /// Broadcast signal visible to all listening events.
  signal,

  /// Named error condition used in error boundary events and end events.
  error,

  /// Non-critical escalation pushed to containing scopes.
  escalation,
}

/// `one { t1, t2, … }` / `all { t1, t2, … }` — multiple triggers.
///
/// Allows an event to be associated with multiple trigger conditions
/// simultaneously.
///
/// - `one {…}` (non-parallel): the event fires when *any one* of the listed
///   triggers occurs.
/// - `all {…}` ([parallel] = true): the event fires only when *all* of the
///   listed triggers have occurred.
///
/// Example:
/// ```
/// event PaymentOrTimeout catch one { message PaymentReceived, timer [after PT30M] };
/// ```
final class MultipleTrigger extends EventTrigger with EquatableMixin {
  /// The list of sub-triggers.
  final List<EventTrigger> triggers;

  /// `true` → `all {…}` (all must occur);  `false` → `one {…}` (first wins).
  final bool parallel;

  const MultipleTrigger({required this.triggers, this.parallel = false});

  @override
  List<Object?> get props => [triggers, parallel];

  @override
  String toString() {
    final keyword = parallel ? 'all' : 'one';
    return '$keyword { ${triggers.join(', ')} }';
  }
}
