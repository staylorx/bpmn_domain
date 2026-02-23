import 'package:equatable/equatable.dart';
import '../value_objects/node_id.dart';
import '../value_objects/stereotype.dart';
import 'event.dart';
import 'flow_element.dart';
import 'io_requirement.dart';
import 'loop_characteristic.dart';

// ---------------------------------------------------------------------------
// Task type
// ---------------------------------------------------------------------------

/// The type of a [WfTask], controlling what kind of work it performs and
/// what tooling/infrastructure it requires.
///
/// | Type      | DSL keyword  | Description                                     |
/// |-----------|-------------|--------------------------------------------------|
/// | generic   | `task`      | Unspecified; analysis only (no implementation)   |
/// | service   | `service`   | Automated by software / web service              |
/// | send      | `send`      | Sends a message to an external participant        |
/// | receive   | `receive`   | Waits for an incoming message                    |
/// | user      | `user`      | Human + software interaction                     |
/// | manual    | `manual`    | Physical work, no software aid                   |
/// | rule      | `rule`      | Business rule engine interaction                 |
/// | script    | `script`    | Inline script executed within the process engine |
enum TaskType {
  /// A generic untyped task — represents abstract work without committing to
  /// an implementation technology.
  generic,

  /// An automated task backed by a web service or software component.
  /// Requires a `webservice` attribute and optionally an `operation`.
  service,

  /// A task that **sends** a message to an external participant.
  /// Requires a `webservice`, `message`, and `operation`.
  send,

  /// A task that **waits** for a message from an external participant.
  /// Requires a `webservice`, `message`, and `operation`.
  receive,

  /// A task performed by a human with software assistance.
  user,

  /// A purely physical task performed without software.
  /// Uses `resources` to specify what physical materials are needed.
  manual,

  /// A task that evaluates a business rule via a rule engine.
  rule,

  /// A task that executes an inline script.
  script,
}

// ---------------------------------------------------------------------------
// TaskTypeAttributes
// ---------------------------------------------------------------------------

/// Additional configuration attributes for typed tasks.
///
/// The set of attributes used depends on the [TaskType]:
///
/// - Service, send, receive, user, rule → [webservice], optional [operation]
/// - Send, receive → also [message]
/// - Manual → [resources]
/// - Script → [scriptFormat] and [script]
///
/// Exactly one of the attribute groups is populated for a given task type.
class TaskTypeAttributes with EquatableMixin {
  /// Web-service binding.  May be a URI string, `##unspecified`, or
  /// `##webservice` (using the abstract BPMN web-service placeholder).
  final String? webservice;

  /// Name of the [WfOperation] invoked by this task.
  final NodeId? operation;

  /// Name of the [WfNotification] (message) used in send/receive tasks.
  final NodeId? message;

  /// Physical resource names required by manual tasks.
  final List<String> resources;

  /// The script language/format identifier (e.g. `"JavaScript"`, `"Groovy"`).
  final String? scriptFormat;

  /// The inline script body.
  final String? script;

  const TaskTypeAttributes({
    this.webservice,
    this.operation,
    this.message,
    this.resources = const [],
    this.scriptFormat,
    this.script,
  });

  /// Creates attributes for a service / user / rule task.
  factory TaskTypeAttributes.webService({
    required String webservice,
    NodeId? operation,
  }) =>
      TaskTypeAttributes(webservice: webservice, operation: operation);

  /// Creates attributes for a send or receive task.
  factory TaskTypeAttributes.messaging({
    required String webservice,
    required NodeId message,
    NodeId? operation,
  }) =>
      TaskTypeAttributes(
        webservice: webservice,
        message: message,
        operation: operation,
      );

  /// Creates attributes for a manual task with resources.
  factory TaskTypeAttributes.manual(List<String> resources) =>
      TaskTypeAttributes(resources: resources);

  /// Creates attributes for a script task.
  factory TaskTypeAttributes.script({
    required String format,
    required String body,
  }) =>
      TaskTypeAttributes(scriptFormat: format, script: body);

  @override
  List<Object?> get props =>
      [webservice, operation, message, resources, scriptFormat, script];
}

// ---------------------------------------------------------------------------
// WfTask entity
// ---------------------------------------------------------------------------

/// A **task** is the most fundamental unit of work in a BPMN workflow.
///
/// Tasks are **atomic** activities — they do not decompose into sub-flows
/// within the model (though at the implementation level a task may represent
/// complex logic).  Unlike [WfSubProcess], a task has no child flow elements.
///
/// ## Task types and use cases
///
/// | [type]     | Typical use case                                        |
/// |------------|---------------------------------------------------------|
/// | generic    | Placeholder / analysis models, no tech commitment      |
/// | service    | REST call, SOAP call, micro-service invocation          |
/// | send       | Publishing message events to external systems           |
/// | receive    | Waiting for replies from external systems               |
/// | user       | Human approval flows (e.g. in BPM suites like Camunda) |
/// | manual     | Physical work: packing, signing, inspection             |
/// | rule       | Credit scoring, fraud detection via rule engines        |
/// | script     | Data transformation, computed routing expressions       |
///
/// ## Boundary events
///
/// Tasks may carry **boundary events** — events attached to the task's
/// border that catch triggers and route the flow *out of* the task:
///
/// ```
/// service task ProcessOrder {
///   webservice = ##webservice;
///   boundary event PossibleCancellation
///     catch compensate ProcessOrder with RollbackOrderProcessing;
/// }
/// ```
///
/// When a boundary event fires while the task is executing, the task is
/// interrupted (unless the boundary event is non-interrupting) and control
/// passes to the outgoing flow of the boundary event.
///
/// ## I/O and resources
///
/// Tasks declare data consumption and production through [ioRequirements].
/// Manual tasks additionally specify [taskTypeAttributes].resources.
///
/// ## Loop characteristics
///
/// A loop specification on a task triggers either repeated execution
/// ([WfStandardLoop]) or multi-instance instantiation ([WfMILoop]).
///
/// ## Incarnation (conformance)
///
/// The `<<incarnates="X">>` stereotype on a task asserts that this task in
/// a concrete model realises task `X` in a reference process model.  The
/// conformance checker uses this mapping.
///
/// Example:
/// ```
/// <<incarnates="Research">> task LiteratureReview;
/// ```
class WfTask with EquatableMixin implements FlowElement {
  /// The unique name of this task within its enclosing scope.
  @override
  final NodeId id;

  /// The kind of work performed.
  final TaskType type;

  /// Type-specific configuration (webservice, message, resources, script).
  final TaskTypeAttributes? taskTypeAttributes;

  /// Loop specification, if any.
  final LoopCharacteristic? loop;

  /// I/O requirements for this task.
  final List<WfIORequirement> ioRequirements;

  /// Boundary events attached to this task.
  final List<WfEvent> boundaryEvents;

  /// Access modifier and stereotype annotations.
  final WfModifier modifier;

  const WfTask({
    required this.id,
    this.type = TaskType.generic,
    this.taskTypeAttributes,
    this.loop,
    this.ioRequirements = const [],
    this.boundaryEvents = const [],
    this.modifier = WfModifier.none,
  });

  // Convenience constructors ---------------------------------------------------

  /// Creates a generic (untyped) task.
  factory WfTask.generic(String name) =>
      WfTask(id: NodeId(name), type: TaskType.generic);

  /// Creates a service task with a web-service binding.
  factory WfTask.service({
    required String name,
    required String webservice,
    String? operationName,
    LoopCharacteristic? loop,
  }) =>
      WfTask(
        id: NodeId(name),
        type: TaskType.service,
        taskTypeAttributes: TaskTypeAttributes.webService(
          webservice: webservice,
          operation: operationName != null ? NodeId(operationName) : null,
        ),
        loop: loop,
      );

  /// Creates a send task.
  factory WfTask.send({
    required String name,
    required String webservice,
    required String messageName,
    String? operationName,
  }) =>
      WfTask(
        id: NodeId(name),
        type: TaskType.send,
        taskTypeAttributes: TaskTypeAttributes.messaging(
          webservice: webservice,
          message: NodeId(messageName),
          operation: operationName != null ? NodeId(operationName) : null,
        ),
      );

  /// Creates a manual task with explicit resource names.
  factory WfTask.manual(String name, List<String> resources) => WfTask(
        id: NodeId(name),
        type: TaskType.manual,
        taskTypeAttributes: TaskTypeAttributes.manual(resources),
      );

  /// Creates a receive task.
  factory WfTask.receive({
    required String name,
    required String webservice,
    required String messageName,
  }) =>
      WfTask(
        id: NodeId(name),
        type: TaskType.receive,
        taskTypeAttributes: TaskTypeAttributes.messaging(
          webservice: webservice,
          message: NodeId(messageName),
        ),
      );

  /// Creates a script task.
  factory WfTask.script({
    required String name,
    required String format,
    required String body,
  }) =>
      WfTask(
        id: NodeId(name),
        type: TaskType.script,
        taskTypeAttributes:
            TaskTypeAttributes.script(format: format, body: body),
      );

  // Derived properties ---------------------------------------------------

  /// Whether this task has the `incarnates` stereotype.
  bool get isIncarnation => modifier.isIncarnation;

  /// The reference task name from the `incarnates` stereotype, if present.
  String? get incarnatesTarget => modifier.incarnatesTarget;

  /// Whether this task has any boundary events.
  bool get hasBoundaryEvents => boundaryEvents.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        type,
        taskTypeAttributes,
        loop,
        ioRequirements,
        boundaryEvents,
        modifier,
      ];
}
