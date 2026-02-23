import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// Loop characteristic hierarchy
// ---------------------------------------------------------------------------

/// The abstract base for all loop specifications on a [WfTask] or
/// [WfSubProcess].
///
/// BPMN 2.0 defines two kinds of looping:
///
/// 1. **Standard loop** ([WfStandardLoop]) — repeatedly executes a single
///    activity instance while/until a condition holds.
/// 2. **Multi-instance loop** ([WfMILoop]) — creates multiple concurrent or
///    sequential instances of the activity, one per item in a collection or
///    count.
sealed class LoopCharacteristic {
  const LoopCharacteristic();
}

// ---------------------------------------------------------------------------
// WfStandardLoop
// ---------------------------------------------------------------------------

/// A standard (condition-based) loop that repeatedly executes one activity.
///
/// There are two forms:
///
/// - **while** — condition is tested *before* executing the body; the body
///   may never execute if the condition starts false.
/// - **until** — condition is tested *after* executing the body; the body
///   executes at least once.
///
/// An optional [maxIterations] limits how many times the loop can run,
/// regardless of the condition.
///
/// Example DSL syntax:
/// ```
/// task Retry while [retries < 3] max 5;
/// task AttemptDelivery until [delivered == true];
/// ```
final class WfStandardLoop extends LoopCharacteristic with EquatableMixin {
  /// Whether this is a `while` loop (`true`) or an `until` loop (`false`).
  final bool isWhile;

  /// The raw condition expression.
  final String loopCondition;

  /// Optional upper bound on iterations.
  final int? maxIterations;

  const WfStandardLoop({
    required this.isWhile,
    required this.loopCondition,
    this.maxIterations,
  });

  /// Creates a `while [condition]` loop.
  factory WfStandardLoop.whileLoop(
    String condition, {
    int? max,
  }) =>
      WfStandardLoop(
          isWhile: true, loopCondition: condition, maxIterations: max);

  /// Creates an `until [condition]` loop.
  factory WfStandardLoop.untilLoop(
    String condition, {
    int? max,
  }) =>
      WfStandardLoop(
          isWhile: false, loopCondition: condition, maxIterations: max);

  @override
  List<Object?> get props => [isWhile, loopCondition, maxIterations];

  @override
  String toString() {
    final form = isWhile ? 'while' : 'until';
    final maxPart = maxIterations != null ? ' max $maxIterations' : '';
    return '$form [$loopCondition]$maxPart';
  }
}

// ---------------------------------------------------------------------------
// WfLoopCardinality
// ---------------------------------------------------------------------------

/// Describes how many instances a multi-instance loop creates.
///
/// The cardinality may be expressed in three ways:
///
/// 1. **Literal count** — a fixed natural number: `count 3`
/// 2. **Expression** — an expression evaluated at runtime: `count [order.size]`
/// 3. **Collection** — a data object whose collection size determines the
///    count: `count items`
///
/// Exactly one of [literalCount], [expression], or [collectionName] is
/// non-null.
class WfLoopCardinality with EquatableMixin {
  final int? literalCount;
  final String? expression;
  final String? collectionName;

  const WfLoopCardinality._({
    this.literalCount,
    this.expression,
    this.collectionName,
  }) : assert(
          (literalCount != null ? 1 : 0) +
                  (expression != null ? 1 : 0) +
                  (collectionName != null ? 1 : 0) ==
              1,
          'Exactly one of literalCount, expression, or collectionName must be set',
        );

  /// Cardinality from a fixed integer.
  factory WfLoopCardinality.count(int n) =>
      WfLoopCardinality._(literalCount: n);

  /// Cardinality from a runtime expression.
  factory WfLoopCardinality.expression(String expr) =>
      WfLoopCardinality._(expression: expr);

  /// Cardinality from a named collection data object.
  factory WfLoopCardinality.collection(String name) =>
      WfLoopCardinality._(collectionName: name);

  @override
  List<Object?> get props => [literalCount, expression, collectionName];

  @override
  String toString() {
    if (literalCount != null) return 'count $literalCount';
    if (expression != null) return 'count [$expression]';
    return 'count $collectionName';
  }
}

// ---------------------------------------------------------------------------
// WfMIImplicitEventBehavior
// ---------------------------------------------------------------------------

/// Describes when an event trigger is implicitly thrown after each instance
/// of a multi-instance loop completes.
///
/// Possible timing options:
///
/// | [timing]   | Semantics                                          |
/// |------------|----------------------------------------------------|
/// | `none`     | Thrown after every instance (default)              |
/// | `first`    | Thrown only after the first instance completes     |
/// | `all`      | Thrown once after all instances complete           |
/// | (custom)   | [complexCondition] holds the custom expression     |
enum MIEventTiming { none, first, all }

class WfMIImplicitEventBehavior with EquatableMixin {
  /// The event trigger to throw.  References an [EventTrigger] description.
  final String eventTriggerSource;

  /// When to throw the event — use [MIEventTiming] for standard options.
  /// `null` when a [complexCondition] is used instead.
  final MIEventTiming? timing;

  /// A custom condition expression determining when to throw the event.
  /// Mutually exclusive with [timing].
  final String? complexCondition;

  const WfMIImplicitEventBehavior({
    required this.eventTriggerSource,
    this.timing,
    this.complexCondition,
  });

  @override
  List<Object?> get props => [eventTriggerSource, timing, complexCondition];
}

// ---------------------------------------------------------------------------
// WfMILoop
// ---------------------------------------------------------------------------

/// A multi-instance loop that creates several parallel or sequential instances
/// of the enclosing activity.
///
/// ## Parallelization
///
/// - **parallel** — all instances execute simultaneously; the activity
///   completes when the [completionCondition] is met or all instances finish.
/// - **sequential** — instances execute one after another; proceeds when the
///   [completionCondition] is met or all instances finish.
///
/// ## Cardinality
///
/// The number of instances is controlled by [cardinality] (a literal count,
/// expression, or collection name).
///
/// ## Loop data
///
/// In a collection-cardinality loop each instance may receive one item from
/// the input collection ([loopDataInputs]) and write one item to the output
/// collection ([loopDataOutputs]).
///
/// ## Completion condition
///
/// When [completionCondition] is set, the loop can short-circuit: as soon
/// as the condition evaluates to `true` after any instance completes, the
/// remaining instances are cancelled and the loop exits.
///
/// ## Example DSL syntax
///
/// ```
/// service task CheckProductAvailability
///   count [order.numberOfOrderedProducts] parallel
///   {
///     webservice = ##webservice;
///     in order:Order;
///   }
/// ```
///
/// Another example with a completion condition:
/// ```
/// task ReviewApplication
///   count 5 parallel
///   until [approvalCount >= 3];
/// ```
final class WfMILoop extends LoopCharacteristic with EquatableMixin {
  final WfLoopCardinality cardinality;
  final bool isParallel;

  /// Optional early-exit condition evaluated after each instance completes.
  final String? completionCondition;

  /// Names of input data objects used to feed each instance.
  final List<String> loopDataInputs;

  /// Names of output data objects collected from each instance.
  final List<String> loopDataOutputs;

  /// Optional implicit event behavior thrown after instance completion.
  final WfMIImplicitEventBehavior? implicitEventBehavior;

  const WfMILoop({
    required this.cardinality,
    this.isParallel = true,
    this.completionCondition,
    this.loopDataInputs = const [],
    this.loopDataOutputs = const [],
    this.implicitEventBehavior,
  });

  /// Creates a parallel multi-instance loop over a named collection.
  factory WfMILoop.parallelOver(String collectionName) => WfMILoop(
        cardinality: WfLoopCardinality.collection(collectionName),
        isParallel: true,
      );

  /// Creates a sequential multi-instance loop with a literal count.
  factory WfMILoop.sequential(int count) => WfMILoop(
        cardinality: WfLoopCardinality.count(count),
        isParallel: false,
      );

  @override
  List<Object?> get props => [
        cardinality,
        isParallel,
        completionCondition,
        loopDataInputs,
        loopDataOutputs,
        implicitEventBehavior,
      ];
}
