import 'package:equatable/equatable.dart';
import '../value_objects/node_id.dart';
import '../value_objects/stereotype.dart';
import 'flow_element.dart';

// ---------------------------------------------------------------------------
// Gateway direction
// ---------------------------------------------------------------------------

/// Whether a gateway *splits* the flow into multiple outgoing paths or
/// *merges* multiple incoming paths into one.
///
/// In the Workflow DSL the direction is written explicitly:
///
/// ```
/// split xor OrderFulfillable;   // diverging — one path is chosen
/// merge and MergeWork;           // converging — all paths must arrive
/// ```
///
/// BPMN allows gateways to be either split *or* merge, but not both.
/// A gateway that combines both roles must be represented as two separate
/// gateway nodes connected by a sequence flow.
enum GatewayDirection {
  /// The gateway has exactly one incoming flow and two-or-more outgoing
  /// flows.  Tokens enter from one side and are routed to one or more
  /// outgoing paths depending on the [GatewayKind].
  split,

  /// The gateway has two-or-more incoming flows and exactly one outgoing
  /// flow.  Tokens arriving from the incoming paths are synchronised or
  /// selected before being forwarded.
  merge,
}

// ---------------------------------------------------------------------------
// Gateway kind (type)
// ---------------------------------------------------------------------------

/// The routing semantics of a gateway.
///
/// Each kind controls how many of the outgoing (split) or incoming (merge)
/// paths carry active tokens at runtime.
///
/// | Kind         | Symbol  | Split behaviour                         | Merge behaviour                           |
/// |--------------|---------|------------------------------------------|-------------------------------------------|
/// | exclusive    | `xor`   | Exactly one path is taken (data-based)  | First token through continues             |
/// | inclusive    | `ior`   | One or more paths (data-based)           | Waits for all *active* incoming paths     |
/// | parallel     | `and`   | All paths are taken simultaneously       | Waits for *all* incoming tokens           |
/// | exclusiveEvent | `receive first` | First event received wins     | (not applicable as merge)                 |
/// | parallelEvent  | `receive all`   | Waits for all listed events   | (not applicable as merge)                 |
/// | complex      | expression | Guard expression controls routing     | Guard expression controls synchronisation |
sealed class GatewayKind {
  const GatewayKind();
}

/// `xor` — Data-based exclusive gateway (XOR, diamond with X).
///
/// **Split**: exactly one outgoing branch is activated.  The branch whose
/// condition evaluates to `true` is taken; if multiple conditions are true
/// the first one wins.  A default branch (`[_]`) is taken when no other
/// condition matches.
///
/// **Merge**: acts as a simple pass-through — the first token to arrive
/// continues without waiting for others.
///
/// Usage:
/// ```
/// split xor OrderFulfillable;
/// merge xor StartIteration;
/// ```
final class ExclusiveGateway extends GatewayKind {
  const ExclusiveGateway();

  @override
  String toString() => 'xor';
}

/// `ior` — Inclusive gateway (OR, diamond with O).
///
/// **Split**: one or more outgoing branches whose conditions are `true` are
/// activated in parallel.
///
/// **Merge**: waits for tokens from *all currently active* incoming paths
/// (i.e. those that were activated by the corresponding split).
///
/// Usage:
/// ```
/// split ior ShipOrNotifyOrBoth;
/// merge ior WaitForActive;
/// ```
final class InclusiveGateway extends GatewayKind {
  const InclusiveGateway();

  @override
  String toString() => 'ior';
}

/// `and` — Parallel gateway (AND, diamond with +).
///
/// **Split**: *all* outgoing branches are activated simultaneously.
///
/// **Merge**: waits for tokens from *every* incoming path before forwarding.
///
/// Usage:
/// ```
/// split and SplitWork;
/// merge and MergeWork;
/// ```
final class ParallelGateway extends GatewayKind {
  const ParallelGateway();

  @override
  String toString() => 'and';
}

/// `receive first` — Exclusive event-based gateway.
///
/// The gateway waits for one of several competing events.  As soon as the
/// *first* event occurs the corresponding outgoing path is taken and all
/// other paths are cancelled (exclusive).
///
/// Only valid as a **split** gateway.  Outgoing flows must target
/// intermediate catch events or receive tasks.
///
/// Usage:
/// ```
/// split receive first WaitForPaymentOrTimeout;
/// ```
final class ExclusiveEventGateway extends GatewayKind {
  const ExclusiveEventGateway();

  @override
  String toString() => 'receive first';
}

/// `receive all` — Parallel event-based gateway.
///
/// All listed events must occur before any outgoing path is taken.
/// Only valid as a **split** gateway.
///
/// Usage:
/// ```
/// split receive all AwaitAllConfirmations;
/// ```
final class ParallelEventGateway extends GatewayKind {
  const ParallelEventGateway();

  @override
  String toString() => 'receive all';
}

/// `complex` — Complex gateway with a guard expression.
///
/// Both split and merge behaviour is determined by an arbitrary guard
/// expression evaluated at runtime.  The [guard] string holds the raw
/// expression source.  Optionally, an [activationCount] may be specified to
/// indicate how many incoming tokens must arrive before the merge triggers.
///
/// Usage:
/// ```
/// split complex [majority(votes) > 0.5] TakeVoteDecision;
/// ```
final class ComplexGateway extends GatewayKind {
  /// The raw guard expression, e.g. `majority(votes) > 0.5`.
  final String guard;

  const ComplexGateway({required this.guard});

  @override
  String toString() => 'complex [$guard]';
}

// ---------------------------------------------------------------------------
// WfGateway entity
// ---------------------------------------------------------------------------

/// A **gateway** is a flow-control element that diverges or converges
/// sequence flows within a workflow.
///
/// The Workflow DSL distinguishes **named** gateways (declared as standalone
/// [FlowElement] symbols) from **inline** gateways (embedded directly in a
/// sequence-flow path without a name).  This entity models the *named* form:
///
/// ```
/// split xor  OrderFulfillable;    // diverging exclusive
/// merge and  MergeWork;           // converging parallel
/// merge xor  StartIteration;      // converging exclusive (pass-through)
/// split receive first PayOrCancel; // event-based
/// ```
///
/// Named gateways become symbols in the symbol table and can therefore be
/// referenced by name in sequence flows.  [WfInlineGateway] is used when a
/// gateway has no name and is embedded inside a flow path.
///
/// ## Context conditions satisfied by correct usage
///
/// - A `split` gateway must have **at most one incoming flow** and
///   **two or more outgoing flows**.
/// - A `merge` gateway must have **two or more incoming flows** and
///   **at most one outgoing flow**.
/// - An event gateway (`receive first` / `receive all`) must be a `split`
///   with at least two outgoing flows targeting catch events or receive tasks.
/// - The default branch `[_]` must be the **last** branch of a `split xor`
///   or `split ior` and only one default branch is permitted.
///
/// ## Relationship to [WfInlineGateway]
///
/// Both share the same [GatewayDirection] and [GatewayKind] value space.
/// [WfGateway] is a symbol with a name; [WfInlineGateway] is anonymous and
/// embedded in the flow syntax.
class WfGateway with EquatableMixin implements FlowElement {
  /// The unique name of this gateway within its enclosing scope.
  @override
  final NodeId id;

  /// Whether this gateway splits or merges flows.
  final GatewayDirection direction;

  /// The routing logic of this gateway.
  final GatewayKind kind;

  /// Optional access-modifier and stereotype annotations.
  final WfModifier modifier;

  /// For [ComplexGateway] merges: the optional number of incoming tokens that
  /// must arrive to trigger the merge, before the guard is evaluated.
  final int? activationCount;

  const WfGateway({
    required this.id,
    required this.direction,
    required this.kind,
    this.modifier = WfModifier.none,
    this.activationCount,
  });

  // Convenience constructors ---------------------------------------------------

  /// Creates an exclusive-XOR split gateway.
  factory WfGateway.splitXor(String name) => WfGateway(
        id: NodeId(name),
        direction: GatewayDirection.split,
        kind: const ExclusiveGateway(),
      );

  /// Creates an exclusive-XOR merge gateway.
  factory WfGateway.mergeXor(String name) => WfGateway(
        id: NodeId(name),
        direction: GatewayDirection.merge,
        kind: const ExclusiveGateway(),
      );

  /// Creates a parallel-AND split gateway.
  factory WfGateway.splitAnd(String name) => WfGateway(
        id: NodeId(name),
        direction: GatewayDirection.split,
        kind: const ParallelGateway(),
      );

  /// Creates a parallel-AND merge gateway.
  factory WfGateway.mergeAnd(String name) => WfGateway(
        id: NodeId(name),
        direction: GatewayDirection.merge,
        kind: const ParallelGateway(),
      );

  /// Creates an inclusive-IOR split gateway.
  factory WfGateway.splitIor(String name) => WfGateway(
        id: NodeId(name),
        direction: GatewayDirection.split,
        kind: const InclusiveGateway(),
      );

  /// Creates a parallel event-based split gateway.
  factory WfGateway.splitReceiveAll(String name) => WfGateway(
        id: NodeId(name),
        direction: GatewayDirection.split,
        kind: const ParallelEventGateway(),
      );

  /// Creates an exclusive event-based split gateway.
  factory WfGateway.splitReceiveFirst(String name) => WfGateway(
        id: NodeId(name),
        direction: GatewayDirection.split,
        kind: const ExclusiveEventGateway(),
      );

  @override
  List<Object?> get props => [id, direction, kind, modifier, activationCount];
}

// ---------------------------------------------------------------------------
// WfInlineGateway entity
// ---------------------------------------------------------------------------

/// An **inline gateway** is a nameless, anonymous gateway embedded directly
/// inside a sequence-flow path.
///
/// Inline gateways are syntactic sugar: they allow the author to write a
/// branching structure without declaring a named gateway symbol first.  The
/// parser will synthesise a unique scope for such an inline gateway but it
/// will not appear in the symbol table as a named element.
///
/// Inline gateways carry the same [direction] and [kind] semantics as
/// [WfGateway] but have no [NodeId].
///
/// Example in source:
/// ```
/// A -> split xor -> { [condX] B; [_] C; };
/// ```
class WfInlineGateway with EquatableMixin {
  final GatewayDirection direction;
  final GatewayKind kind;

  const WfInlineGateway({required this.direction, required this.kind});

  @override
  List<Object?> get props => [direction, kind];
}
