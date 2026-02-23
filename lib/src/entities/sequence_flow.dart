import 'package:equatable/equatable.dart';
import '../value_objects/node_id.dart';
import 'flow_element.dart';
import 'gateway.dart';

// ---------------------------------------------------------------------------
// FlowCondition
// ---------------------------------------------------------------------------

/// A guard on a sequence-flow edge that restricts when the flow is active.
///
/// Flow conditions appear in branching paths emerging from `split xor` and
/// `split ior` gateways, or directly inside [FlowBlock]s.
///
/// There are two forms:
/// - **Expression condition**: `[someExpression]` — the flow is taken when
///   the boolean expression evaluates to `true` at runtime.
/// - **Default condition**: `[_]` — the fallback branch taken when no other
///   condition matches.  Only one default branch is permitted per branching
///   point and it must be the last branch listed.
///
/// DSL examples:
/// ```
/// [checker.allProductsAvailable] PrepareAndPackProducts -> ...;
/// [!checker.allProductsAvailable] SendCancellationMessage -> ...;
/// [agreement.isOrderPickedUp] PickUpOrder;
/// [_] ShipOrder;
/// ```
sealed class FlowCondition {
  const FlowCondition();
}

/// An expression-based guard on a sequence flow edge.
final class ExpressionCondition extends FlowCondition with EquatableMixin {
  /// The raw boolean expression from the source, e.g. `checker.allProductsAvailable`.
  final String expression;

  const ExpressionCondition(this.expression);

  @override
  List<Object?> get props => [expression];

  @override
  String toString() => '[$expression]';
}

/// The default branch — taken when no [ExpressionCondition] on a sibling
/// branch evaluates to `true`.  Written as `[_]` in the DSL.
final class DefaultCondition extends FlowCondition with EquatableMixin {
  const DefaultCondition();

  @override
  List<Object?> get props => [];

  @override
  String toString() => '[_]';
}

// ---------------------------------------------------------------------------
// FlowTarget
// ---------------------------------------------------------------------------

/// A single step in a [SequenceFlow] path.
///
/// Each step targets one of:
/// - A named [FlowElement] referenced by [elementRef]
/// - An anonymous [WfInlineGateway] embedded in the flow
/// - A [FlowBlock] containing multiple sub-paths
///
/// A [condition] may guard the step.
///
/// Exactly one of [elementRef], [inlineGateway], or [block] is non-null.
class FlowTarget with EquatableMixin {
  /// Guard condition on this step. `null` = unconditional.
  final FlowCondition? condition;

  /// Reference to a named flow element by its [NodeId].
  final NodeId? elementRef;

  /// An anonymous inline gateway.
  final WfInlineGateway? inlineGateway;

  /// A nested block of branching sub-paths.
  final FlowBlock? block;

  const FlowTarget._({
    this.condition,
    this.elementRef,
    this.inlineGateway,
    this.block,
  });

  /// Targets a named element, optionally guarded by [condition].
  factory FlowTarget.element(
    NodeId ref, {
    FlowCondition? condition,
  }) =>
      FlowTarget._(elementRef: ref, condition: condition);

  /// Targets an inline gateway.
  factory FlowTarget.gateway(
    WfInlineGateway gw, {
    FlowCondition? condition,
  }) =>
      FlowTarget._(inlineGateway: gw, condition: condition);

  /// Targets a [FlowBlock] (a set of branching sub-flows).
  factory FlowTarget.block(
    FlowBlock blk, {
    FlowCondition? condition,
  }) =>
      FlowTarget._(block: blk, condition: condition);

  /// Whether this step is guarded by a condition.
  bool get hasCondition => condition != null;

  /// Whether this step targets a named element.
  bool get isElementRef => elementRef != null;

  /// Whether this step targets an inline gateway.
  bool get isGateway => inlineGateway != null;

  /// Whether this step targets a sub-flow block.
  bool get isBlock => block != null;

  @override
  List<Object?> get props => [condition, elementRef, inlineGateway, block];
}

// ---------------------------------------------------------------------------
// FlowBlock
// ---------------------------------------------------------------------------

/// A **flow block** contains multiple branching [SequenceFlow]s enclosed in
/// `{ … }`.
///
/// Flow blocks are the primary mechanism for writing conditional branches
/// *inline* within a sequence flow path without first declaring a named
/// gateway.  Each branch in the block is a [SequenceFlow].
///
/// Typically each branch starts with a [FlowCondition] on its first
/// [FlowTarget]:
///
/// ```
/// -> {
///      [checker.allProductsAvailable] PrepareAndPackProducts -> OrderDelivered;
///      [!checker.allProductsAvailable] SendCancellationMessage -> CancelOrder;
///    }
/// ```
///
/// The enclosing `-> { … }` is itself a [FlowTarget] with [FlowTarget.block].
class FlowBlock with EquatableMixin {
  /// The branches of this block, each a separate [SequenceFlow].
  final List<SequenceFlow> branches;

  const FlowBlock(this.branches);

  @override
  List<Object?> get props => [branches];
}

// ---------------------------------------------------------------------------
// SequenceFlow entity
// ---------------------------------------------------------------------------

/// A **sequence flow** is a directed path through a workflow, connecting
/// a series of [FlowTarget]s in order.
///
/// Sequence flows are the connective tissue of BPMN — they determine the
/// execution order of activities, events, and gateways.
///
/// ## Syntax
///
/// Sequence flows are written as `->` separated chains of node references,
/// inline gateways, and blocks:
///
/// ```
/// // Simple linear chain
/// Start -> Research -> Draft -> StartIteration;
///
/// // Chain with a parallel split
/// SplitWork -> Introduction -> MergeWork;
/// SplitWork -> Main -> MergeWork;
/// SplitWork -> Conclusion -> MergeWork;
///
/// // Inline conditional block
/// OrderFulfillable
///   -> {
///        [checker.allProductsAvailable] PrepareAndPackProducts -> OrderDelivered;
///        [_] SendCancellationMessage -> CancelOrder;
///      }
///   -> FinishOrderProcessing;
/// ```
///
/// ## Multiple flows per process
///
/// A process body contains many [SequenceFlow] declarations.  Together they
/// define a directed graph.  The parser assembles them into the overall
/// process graph by resolving named element references.
///
/// ## Context conditions
///
/// - Start events must have no incoming flows.
/// - End events must have no outgoing flows.
/// - Merge gateways must have ≥2 incoming and exactly 1 outgoing flow.
/// - Split gateways must have exactly 1 incoming and ≥2 outgoing flows.
/// - Boundary events must have no incoming sequence flows.
/// - A sequence flow must not cross subprocess boundaries.
class SequenceFlow with EquatableMixin implements FlowElement {
  /// A synthetic id for this flow — since sequence flows are not named
  /// elements, we generate one during parsing for symbol-table bookkeeping.
  @override
  final NodeId id;

  /// The ordered list of steps in this flow path.
  ///
  /// Each step is a [FlowTarget] pointing at a named element, an inline
  /// gateway, or a nested block.  The flow is executed step by step.
  final List<FlowTarget> path;

  const SequenceFlow({required this.id, required this.path});

  /// Convenience: build a simple linear flow from a list of element names.
  factory SequenceFlow.linear(String syntheticId, List<String> nodeNames) =>
      SequenceFlow(
        id: NodeId(syntheticId),
        path: nodeNames.map((n) => FlowTarget.element(NodeId(n))).toList(),
      );

  @override
  List<Object?> get props => [id, path];
}
