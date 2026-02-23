import '../value_objects/node_id.dart';

/// The common interface for all named elements that can appear inside a
/// [WfProcess] or [WfSubProcess] body.
///
/// In the Workflow grammar `FlowElement` is an interface implemented by:
///
/// - **[WfLane]** — a swimlane partitioning the process
/// - **[WfTask]** — an atomic unit of work
/// - **[WfSubProcess]** — an embedded or transaction sub-workflow
/// - **[WfCallActivity]** — a reference to a reusable process / global task
/// - **[WfGateway]** — a flow-control element (split/merge)
/// - **[WfEvent]** — a start, end, or intermediate occurrence
/// - **[WfDataObject]** — a data or store variable declaration
/// - **[WfNotification]** — a message, signal, error, or escalation payload
/// - **[WfOperation]** — a function signature callable from tasks/events
/// - **[SequenceFlow]** — a directed connection between flow elements
///
/// Every [FlowElement] has an [id] that uniquely identifies it within its
/// enclosing scope.
abstract interface class FlowElement {
  /// The unique node identifier within the enclosing scope.
  NodeId get id;
}
