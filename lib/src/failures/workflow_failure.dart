import 'package:equatable/equatable.dart';
import '../value_objects/node_id.dart';

/// The abstract base for all domain-level failures in the BPMN workflow
/// model.
///
/// Failures represent violations of context conditions (CoCos) that are
/// checked after parsing.  Rather than throwing exceptions, the domain
/// layer uses typed failure objects so that callers can pattern-match on
/// the exact kind of problem and report rich diagnostics.
///
/// Each concrete failure subclass maps to one or more CoCo from the
/// MontiCore BPMN grammar documentation.
///
/// ## Usage with fpdart
///
/// ```dart
/// Either<WorkflowFailure, WfProcess> result = validator.validate(process);
/// result.fold(
///   (failure) => print('Invalid: ${failure.message}'),
///   (process) => print('Process "${process.id}" is valid'),
/// );
/// ```
sealed class WorkflowFailure with EquatableMixin {
  const WorkflowFailure();

  /// A human-readable description of the failure.
  String get message;
}

// ---------------------------------------------------------------------------
// Activity failures
// ---------------------------------------------------------------------------

/// An ad-hoc subprocess must contain at least one activity.
///
/// CoCo: `AdHocSubProcessContainsAtLeastOneActivity`
final class AdHocSubProcessEmpty extends WorkflowFailure {
  final NodeId subProcessId;

  const AdHocSubProcessEmpty(this.subProcessId);

  @override
  String get message =>
      'Ad-hoc subprocess "${subProcessId.value}" must contain at least one activity.';

  @override
  List<Object?> get props => [subProcessId];
}

/// An ad-hoc subprocess must not have start or end events.
///
/// CoCo: `AdHocSubProcessHasNoStartAndEndEvent`
final class AdHocSubProcessHasStartOrEndEvent extends WorkflowFailure {
  final NodeId subProcessId;

  const AdHocSubProcessHasStartOrEndEvent(this.subProcessId);

  @override
  String get message =>
      'Ad-hoc subprocess "${subProcessId.value}" must not have start or end events.';

  @override
  List<Object?> get props => [subProcessId];
}

/// A call-activity references a process that does not exist.
///
/// CoCo: `CalledElementDoesExist`
final class CalledElementNotFound extends WorkflowFailure {
  final NodeId callActivityId;
  final NodeId calledElement;

  const CalledElementNotFound({
    required this.callActivityId,
    required this.calledElement,
  });

  @override
  String get message =>
      'Call-activity "${callActivityId.value}" references process '
      '"${calledElement.value}" which does not exist.';

  @override
  List<Object?> get props => [callActivityId, calledElement];
}

/// A compensation activity must have no incoming or outgoing sequence flows.
///
/// CoCo: `CompensationActivityHasNoIncomingOrOutgoingFlow`
final class CompensationActivityHasFlow extends WorkflowFailure {
  final NodeId activityId;

  const CompensationActivityHasFlow(this.activityId);

  @override
  String get message =>
      'Compensation activity "${activityId.value}" must not have '
      'incoming or outgoing sequence flows.';

  @override
  List<Object?> get props => [activityId];
}

/// An event subprocess must not have incoming or outgoing flows.
///
/// CoCo: `EventSubProcessHasNoIncomingOrOutgoingFlow`
final class EventSubProcessHasFlow extends WorkflowFailure {
  final NodeId subProcessId;

  const EventSubProcessHasFlow(this.subProcessId);

  @override
  String get message =>
      'Event subprocess "${subProcessId.value}" must not have '
      'incoming or outgoing sequence flows.';

  @override
  List<Object?> get props => [subProcessId];
}

/// An event subprocess must have exactly one start event.
///
/// CoCo: `EventSubProcessHasOnlyOneStartEvent`
final class EventSubProcessStartEventCount extends WorkflowFailure {
  final NodeId subProcessId;
  final int found;

  const EventSubProcessStartEventCount({
    required this.subProcessId,
    required this.found,
  });

  @override
  String get message =>
      'Event subprocess "${subProcessId.value}" has $found start events; '
      'exactly 1 is required.';

  @override
  List<Object?> get props => [subProcessId, found];
}

/// The loop count expression must evaluate to an integer.
///
/// CoCo: `LoopCountExpressionReturnsIntegerNumber`
final class LoopCountNotInteger extends WorkflowFailure {
  final NodeId activityId;
  final String expression;

  const LoopCountNotInteger({
    required this.activityId,
    required this.expression,
  });

  @override
  String get message => 'Loop count expression "$expression" on activity '
      '"${activityId.value}" must evaluate to an integer.';

  @override
  List<Object?> get props => [activityId, expression];
}

// ---------------------------------------------------------------------------
// Analysis (process soundness) failures
// ---------------------------------------------------------------------------

/// The process contains a node that is never reachable from a start event.
///
/// CoCo: `ProcessHasNoDeadNodes`
final class DeadNode extends WorkflowFailure {
  final NodeId nodeId;

  const DeadNode(this.nodeId);

  @override
  String get message =>
      'Node "${nodeId.value}" is unreachable (dead node) — no path from a '
      'start event leads to it.';

  @override
  List<Object?> get props => [nodeId];
}

/// The process contains a disconnected component not connected to the main
/// flow.
///
/// CoCo: `ProcessHasNoDisconnectedComponents`
final class DisconnectedComponent extends WorkflowFailure {
  final List<NodeId> componentNodes;

  const DisconnectedComponent(this.componentNodes);

  @override
  String get message =>
      'The process contains a disconnected component with nodes: '
      '${componentNodes.map((n) => n.value).join(', ')}.';

  @override
  List<Object?> get props => [componentNodes];
}

/// The process contains a loop with no exit path.
///
/// CoCo: `ProcessHasNoInfiniteLoop`
final class InfiniteLoop extends WorkflowFailure {
  final List<NodeId> loopNodes;

  const InfiniteLoop(this.loopNodes);

  @override
  String get message => 'The process contains an infinite loop through nodes: '
      '${loopNodes.map((n) => n.value).join(' → ')}.';

  @override
  List<Object?> get props => [loopNodes];
}

/// Multiple parallel branches converge at a `merge xor` gateway (lack of
/// synchronisation).
///
/// CoCo: `ProcessHasNoLackOfSync`
final class LackOfSync extends WorkflowFailure {
  final NodeId mergeGatewayId;

  const LackOfSync(this.mergeGatewayId);

  @override
  String get message =>
      'Gateway "${mergeGatewayId.value}": parallel branches merge at an XOR '
      'gateway (lack of synchronisation anti-pattern).';

  @override
  List<Object?> get props => [mergeGatewayId];
}

/// A parallel merge gateway blocks because the expected parallel tokens
/// can never all arrive.
///
/// CoCo: `ProcessHasNoSyncDeadlock`
final class SyncDeadlock extends WorkflowFailure {
  final NodeId mergeGatewayId;

  const SyncDeadlock(this.mergeGatewayId);

  @override
  String get message =>
      'Gateway "${mergeGatewayId.value}" will never receive all expected '
      'parallel tokens (sync deadlock).';

  @override
  List<Object?> get props => [mergeGatewayId];
}

/// The overall process is not sound (does not satisfy the workflow soundness
/// criterion: every execution from start must eventually reach an end event).
///
/// CoCo: `ProcessNetIsSound`
final class ProcessNotSound extends WorkflowFailure {
  final String reason;

  const ProcessNotSound(this.reason);

  @override
  String get message => 'The process is not sound: $reason';

  @override
  List<Object?> get props => [reason];
}

// ---------------------------------------------------------------------------
// Event failures
// ---------------------------------------------------------------------------

/// A start event must not be a throwing event.
///
/// CoCo: `StartEventIsNotThrowing`
final class StartEventIsThrowing extends WorkflowFailure {
  final NodeId eventId;

  const StartEventIsThrowing(this.eventId);

  @override
  String get message =>
      'Start event "${eventId.value}" must be catching, not throwing.';

  @override
  List<Object?> get props => [eventId];
}

/// An end event must not be a catching event.
///
/// CoCo: `EndEventIsNotCatching`
final class EndEventIsCatching extends WorkflowFailure {
  final NodeId eventId;

  const EndEventIsCatching(this.eventId);

  @override
  String get message =>
      'End event "${eventId.value}" must be throwing, not catching.';

  @override
  List<Object?> get props => [eventId];
}

/// If a start event is used, at least one end event must be declared.
///
/// CoCo: `AtLeastOneEndEventIfStartEventIsUsed`
final class NoEndEventWithStartEvent extends WorkflowFailure {
  const NoEndEventWithStartEvent();

  @override
  String get message => 'The process declares a start event but no end event.';

  @override
  List<Object?> get props => [];
}

/// A boundary event must have no incoming sequence flows.
///
/// CoCo: `BoundaryEventHasNoIncomingFlow`
final class BoundaryEventHasIncomingFlow extends WorkflowFailure {
  final NodeId eventId;

  const BoundaryEventHasIncomingFlow(this.eventId);

  @override
  String get message =>
      'Boundary event "${eventId.value}" must not have incoming flows.';

  @override
  List<Object?> get props => [eventId];
}

// ---------------------------------------------------------------------------
// Flow failures
// ---------------------------------------------------------------------------

/// More than one default branch `[_]` found at a branching point.
///
/// CoCo: `AtMostOneDefaultBranch`
final class MultipleDefaultBranches extends WorkflowFailure {
  final NodeId splitGatewayId;

  const MultipleDefaultBranches(this.splitGatewayId);

  @override
  String get message =>
      'Split gateway "${splitGatewayId.value}" has more than one default '
      'branch `[_]`.';

  @override
  List<Object?> get props => [splitGatewayId];
}

/// The default branch is not the last branch.
///
/// CoCo: `DefaultBranchIsLastBranch`
final class DefaultBranchNotLast extends WorkflowFailure {
  final NodeId gatewayId;

  const DefaultBranchNotLast(this.gatewayId);

  @override
  String get message =>
      'The default branch `[_]` at gateway "${gatewayId.value}" must be '
      'the last branch.';

  @override
  List<Object?> get props => [gatewayId];
}

/// An end event has an outgoing flow.
///
/// CoCo: `EndEventHasNoOutgoingFlow`
final class EndEventHasOutgoingFlow extends WorkflowFailure {
  final NodeId eventId;

  const EndEventHasOutgoingFlow(this.eventId);

  @override
  String get message =>
      'End event "${eventId.value}" must not have outgoing flows.';

  @override
  List<Object?> get props => [eventId];
}

/// A merge gateway does not have multiple incoming flows.
///
/// CoCo: `MergeGatewayHasMultipleIncomingFlow`
final class MergeGatewayTooFewIncomingFlows extends WorkflowFailure {
  final NodeId gatewayId;
  final int found;

  const MergeGatewayTooFewIncomingFlows({
    required this.gatewayId,
    required this.found,
  });

  @override
  String get message =>
      'Merge gateway "${gatewayId.value}" has $found incoming flow(s); '
      'at least 2 are required.';

  @override
  List<Object?> get props => [gatewayId, found];
}

/// A split gateway does not have multiple outgoing flows.
///
/// CoCo: `SplitGatewayHasMultipleOutgoingFlow`
final class SplitGatewayTooFewOutgoingFlows extends WorkflowFailure {
  final NodeId gatewayId;
  final int found;

  const SplitGatewayTooFewOutgoingFlows({
    required this.gatewayId,
    required this.found,
  });

  @override
  String get message =>
      'Split gateway "${gatewayId.value}" has $found outgoing flow(s); '
      'at least 2 are required.';

  @override
  List<Object?> get props => [gatewayId, found];
}

/// A sequence flow references a node name that does not exist in scope.
///
/// CoCo: `SequenceFlowNodeReferencesExist`
final class UnresolvedNodeReference extends WorkflowFailure {
  final NodeId referencedNode;
  final NodeId fromFlow;

  const UnresolvedNodeReference({
    required this.referencedNode,
    required this.fromFlow,
  });

  @override
  String get message => 'Flow "${fromFlow.value}" references undefined node '
      '"${referencedNode.value}".';

  @override
  List<Object?> get props => [referencedNode, fromFlow];
}

// ---------------------------------------------------------------------------
// Gateway failures
// ---------------------------------------------------------------------------

/// An event gateway mixes message events and receive tasks.
///
/// CoCo: `EventGatewayDoesNotMixMessageEventsAndReceiveTasks`
final class EventGatewayMixedTargetTypes extends WorkflowFailure {
  final NodeId gatewayId;

  const EventGatewayMixedTargetTypes(this.gatewayId);

  @override
  String get message =>
      'Event gateway "${gatewayId.value}" must not mix message events '
      'and receive tasks on its outgoing flows.';

  @override
  List<Object?> get props => [gatewayId];
}

/// An event gateway must be a split (not a merge).
///
/// CoCo: `EventGatewayIsSplit`
final class EventGatewayIsNotSplit extends WorkflowFailure {
  final NodeId gatewayId;

  const EventGatewayIsNotSplit(this.gatewayId);

  @override
  String get message =>
      'Event gateway "${gatewayId.value}" must be a split gateway.';

  @override
  List<Object?> get props => [gatewayId];
}

// ---------------------------------------------------------------------------
// Conformance failures
// ---------------------------------------------------------------------------

/// A task in the concrete model does not incarnate any task in the reference
/// model (when incarnation checking is required).
///
/// CoCo: conformance checking
final class TaskNotIncarnated extends WorkflowFailure {
  final NodeId taskId;

  const TaskNotIncarnated(this.taskId);

  @override
  String get message =>
      'Task "${taskId.value}" does not incarnate any task in the reference '
      'model.';

  @override
  List<Object?> get props => [taskId];
}

/// The concrete process uses a `merge xor` where the reference model uses
/// `merge and` (anti-pattern: closing parallel branches with XOR).
///
/// CoCo: conformance checking (AntiPatternMerge)
final class ParallelBranchesClosedWithXor extends WorkflowFailure {
  final NodeId mergeGatewayId;
  final List<NodeId> parallelBranch;

  const ParallelBranchesClosedWithXor({
    required this.mergeGatewayId,
    required this.parallelBranch,
  });

  @override
  String get message =>
      'Merge gateway "${mergeGatewayId.value}" closes parallel branches '
      'with XOR (anti-pattern). '
      'Parallel path: ${parallelBranch.map((n) => n.value).join(' → ')}.';

  @override
  List<Object?> get props => [mergeGatewayId, parallelBranch];
}
