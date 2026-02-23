import 'package:equatable/equatable.dart';
import '../value_objects/node_id.dart';
import '../value_objects/stereotype.dart';
import 'event.dart';
import 'flow_element.dart';
import 'loop_characteristic.dart';

// ---------------------------------------------------------------------------
// SubProcess type
// ---------------------------------------------------------------------------

/// The structural variant of a [WfSubProcess].
///
/// | Type          | DSL keyword   | Semantics                                          |
/// |---------------|---------------|----------------------------------------------------|
/// | embedded      | `subprocess`  | Inline sub-workflow with full flow semantics        |
/// | transaction   | `transaction` | Ensures ACID-like behaviour across contained tasks  |
/// | adhoc         | `adhoc`       | Flexible execution — activities run without fixed order |
enum SubProcessType {
  /// A standard embedded subprocess.
  ///
  /// Contains a fully sequenced flow of activities, events, and gateways.
  /// When the subprocess starts, it executes its internal flow; when the
  /// subprocess' end event fires, control returns to the outer flow.
  embedded,

  /// A transactional subprocess.
  ///
  /// Groups activities that must all succeed or all be compensated.  If a
  /// [CancelTrigger] or [CompensateTrigger] fires within a transaction, the
  /// transaction subprocess initiates compensation for all completed tasks
  /// before propagating the error to the outer scope.
  transaction,

  /// An ad-hoc subprocess.
  ///
  /// Contains a collection of activities that can execute in any order or
  /// run in parallel without a prescribed sequence flow.  The subprocess
  /// completes when the [AdHocCharacteristics.completionCondition] becomes
  /// `true` or all activities have been performed.
  adhoc,
}

// ---------------------------------------------------------------------------
// AdHocCharacteristics
// ---------------------------------------------------------------------------

/// Configuration for an [SubProcessType.adhoc] subprocess.
///
/// Ad-hoc subprocesses allow flexible task execution — actors may choose
/// which activities to run, in what order, and how many times.
///
/// The [completionCondition] expression determines when the subprocess is
/// considered done.  The [isParallel] flag controls whether activities can
/// run simultaneously (`true`) or must be executed one at a time (`false`).
/// When [nonInterrupt] is `true`, executing one activity does not prevent
/// others from also starting.
///
/// DSL example:
/// ```
/// adhoc [allTasksCompleted == true] parallel noninterrupt subprocess
///   ReviewProcess { ... }
/// ```
class AdHocCharacteristics with EquatableMixin {
  /// The condition that indicates the ad-hoc subprocess is complete.
  final String completionCondition;

  /// `true` → activities may run in parallel.
  final bool isParallel;

  /// `true` → completing one activity does not cancel others (non-interrupt).
  final bool nonInterrupt;

  const AdHocCharacteristics({
    required this.completionCondition,
    this.isParallel = false,
    this.nonInterrupt = false,
  });

  @override
  List<Object?> get props => [completionCondition, isParallel, nonInterrupt];
}

// ---------------------------------------------------------------------------
// WfSubProcess entity
// ---------------------------------------------------------------------------

/// A **subprocess** is a non-atomic activity whose body is itself a
/// mini-workflow of activities, events, and gateways.
///
/// Subprocesses are the primary mechanism for **process decomposition** —
/// they allow complex behaviour to be abstracted behind a single node in the
/// parent flow.  The subprocess body is only visible by expanding it; in the
/// parent flow it appears as a single rounded rectangle with a `+` marker.
///
/// ## Subprocess types
///
/// ### Embedded (`subprocess`)
///
/// The most common variant.  The body is a fully specified sequence of
/// activities and events.  The subprocess has its own internal start and
/// end events.
///
/// ```
/// subprocess ShipOrder {
///   manual task AttachLabelToPacket { resources = order, products; }
///   service task SelectShippingCarrier { webservice = ##webservice; }
///   start event PrepareForShipment;
///   end event ShipmentDispatched;
///   PrepareForShipment -> AttachLabelToPacket -> SelectShippingCarrier
///     -> ShipmentDispatched;
/// }
/// ```
///
/// ### Transaction (`transaction`)
///
/// Ensures that all enclosed activities either complete successfully or are
/// compensated.  A cancel end event inside the transaction triggers
/// compensation for all completed activities.
///
/// ```
/// transaction PaymentBlock {
///   service task ChargeCard { webservice = ##webservice; }
///   end event PaymentDone;
///   boundary event PaymentFailed catch cancel;
///   ChargeCard -> PaymentDone;
/// }
/// ```
///
/// ### Ad-hoc (`adhoc`)
///
/// Activities can be executed in any order; the process does not enforce a
/// sequence.  Useful for human-driven review or documentation processes.
///
/// ```
/// adhoc [allReviewed] parallel subprocess PeerReview {
///   task ReviewAbstract;
///   task ReviewIntroduction;
///   task ReviewConclusion;
/// }
/// ```
///
/// ## Boundary events
///
/// Like tasks, subprocesses can carry boundary events that catch triggers
/// arising from within the subprocess and route control out of it.
///
/// ## Event subprocesses
///
/// A subprocess that has no incoming or outgoing flows and whose start event
/// is a catch event is called an **event subprocess**.  It runs concurrently
/// with the parent process when its trigger fires.  The grammar models this
/// by the absence of sequence-flow connections to the subprocess.
class WfSubProcess with EquatableMixin implements FlowElement {
  /// The unique name within the enclosing scope.
  @override
  final NodeId id;

  /// Structural variant (embedded, transaction, adhoc).
  final SubProcessType subProcessType;

  /// Ad-hoc configuration (only non-null when [subProcessType] == [adhoc]).
  final AdHocCharacteristics? adHocCharacteristics;

  /// Optional loop specification.
  final LoopCharacteristic? loop;

  /// All flow elements declared inside this subprocess.
  final List<FlowElement> elements;

  /// Boundary events attached to the subprocess border.
  final List<WfEvent> boundaryEvents;

  /// Access modifier and stereotype annotations.
  final WfModifier modifier;

  const WfSubProcess({
    required this.id,
    this.subProcessType = SubProcessType.embedded,
    this.adHocCharacteristics,
    this.loop,
    this.elements = const [],
    this.boundaryEvents = const [],
    this.modifier = WfModifier.none,
  });

  // Convenience constructors ---------------------------------------------------

  /// Creates an empty embedded subprocess.
  factory WfSubProcess.embedded(String name) => WfSubProcess(
        id: NodeId(name),
        subProcessType: SubProcessType.embedded,
      );

  /// Creates a transaction subprocess.
  factory WfSubProcess.transaction(String name) => WfSubProcess(
        id: NodeId(name),
        subProcessType: SubProcessType.transaction,
      );

  /// Creates an ad-hoc subprocess.
  factory WfSubProcess.adhoc(
    String name, {
    required String completionCondition,
    bool parallel = false,
  }) =>
      WfSubProcess(
        id: NodeId(name),
        subProcessType: SubProcessType.adhoc,
        adHocCharacteristics: AdHocCharacteristics(
          completionCondition: completionCondition,
          isParallel: parallel,
        ),
      );

  // Derived properties ---------------------------------------------------------

  bool get isTransaction => subProcessType == SubProcessType.transaction;
  bool get isAdHoc => subProcessType == SubProcessType.adhoc;

  /// `true` when this subprocess has no incoming/outgoing connections —
  /// indicating it may be an event subprocess.
  bool get hasNoSequenceFlows => elements.whereType<FlowElement>().isEmpty;

  @override
  List<Object?> get props => [
        id,
        subProcessType,
        adHocCharacteristics,
        loop,
        elements,
        boundaryEvents,
        modifier,
      ];
}

// ---------------------------------------------------------------------------
// WfCallActivity entity
// ---------------------------------------------------------------------------

/// A **call activity** invokes an external reusable process or global task.
///
/// Unlike a [WfSubProcess], the body of the called process is defined
/// *elsewhere* — it may be in the same `.wfm` file, another file in the
/// artifact path, or a symbolic reference to a global task.
///
/// The [calledElement] holds the name of the referenced [WFProcess].
///
/// ## Global tasks
///
/// In the Workflow DSL, global tasks are modelled as processes containing
/// a single task element.  A call activity that targets such a process is
/// effectively re-using a single named task.
///
/// ## Boundary events
///
/// Call activities support boundary events in the same way as [WfTask] and
/// [WfSubProcess].
///
/// ## Example
///
/// ```
/// call-activity ShipOrderOfCustomer calls ShippingProcess;
/// call-activity RunPaymentCheck calls PaymentValidationProcess
///   count [order.items] parallel;
/// ```
class WfCallActivity with EquatableMixin implements FlowElement {
  /// The unique name within the enclosing scope.
  @override
  final NodeId id;

  /// The name of the process being called.  Must resolve to a [WfProcess]
  /// in scope (same file or via the artifact path).
  final NodeId calledElement;

  /// Optional loop specification.
  final LoopCharacteristic? loop;

  /// Boundary events attached to this call activity.
  final List<WfEvent> boundaryEvents;

  /// Access modifier and stereotype annotations.
  final WfModifier modifier;

  const WfCallActivity({
    required this.id,
    required this.calledElement,
    this.loop,
    this.boundaryEvents = const [],
    this.modifier = WfModifier.none,
  });

  factory WfCallActivity.simple({
    required String name,
    required String calledProcessName,
  }) =>
      WfCallActivity(
        id: NodeId(name),
        calledElement: NodeId(calledProcessName),
      );

  @override
  List<Object?> get props =>
      [id, calledElement, loop, boundaryEvents, modifier];
}
