import 'package:equatable/equatable.dart';
import '../value_objects/node_id.dart';
import '../value_objects/wf_type_ref.dart';

// ---------------------------------------------------------------------------
// WFDataIO
// ---------------------------------------------------------------------------

/// A single data input or output item within an I/O set.
///
/// In the grammar a `WFDataIO` can appear as:
/// ```
/// in order:Order             // simple typed input named 'order'
/// out result:Result?         // optional typed output
/// in items[i]:Product        // iterated input from a collection
/// in config:Settings!        // data that may be produced while executing
/// in source as alias         // rename the data item at this point
/// ```
///
/// Fields:
/// - [name] — qualified name of the data element referenced (resolved to a
///   [WfDataObject] or variable in scope).
/// - [type] — the declared type, if any.
/// - [loop] — `true` when `[i]` is present, indicating iteration over a
///   collection-valued input.
/// - [optional] — `true` when `?` suffix is present.
/// - [whileExecuting] — `true` when `!` suffix is present (can be produced
///   during execution).
/// - [alias] — a renamed binding for the data within this scope.
class WfDataIO with EquatableMixin {
  /// The referenced data element's name.
  final NodeId name;

  /// Optional declared type for this I/O item.
  final WfTypeRef? type;

  /// `true` → iterates over a collection-valued data object (written `[i]`).
  final bool loop;

  /// `true` → this I/O item is optional (written `?`).
  final bool optional;

  /// `true` → this data may be produced during execution (written `!`).
  final bool whileExecuting;

  /// A local alias name for the data within this scope.
  final String? alias;

  const WfDataIO({
    required this.name,
    this.type,
    this.loop = false,
    this.optional = false,
    this.whileExecuting = false,
    this.alias,
  });

  @override
  List<Object?> get props =>
      [name, type, loop, optional, whileExecuting, alias];
}

// ---------------------------------------------------------------------------
// WFDataSet
// ---------------------------------------------------------------------------

/// A set of one or more [WfDataIO] items used in an I/O specification.
///
/// A data set can be:
/// - A **single** item: `in order:Order;`
/// - A **multi-item** set: `in { order:Order, checker:Checker };`
class WfDataSet with EquatableMixin {
  /// The items in this data set.
  final List<WfDataIO> items;

  const WfDataSet(this.items);

  /// Creates a data set with a single item.
  factory WfDataSet.single(WfDataIO item) => WfDataSet([item]);

  @override
  List<Object?> get props => [items];
}

// ---------------------------------------------------------------------------
// WFIORequirement
// ---------------------------------------------------------------------------

/// The base interface for I/O requirements on tasks and processes.
///
/// I/O requirements describe what data a [WfTask], [WfSubProcess], or
/// [WfProcess] consumes and produces.  They come in two forms:
///
/// - **[WfIOSet]** — a directional set (`in` or `out`) of data items.
/// - **[WfIORule]** — an explicit mapping from an input set to an output set.
sealed class WfIORequirement {
  const WfIORequirement();
}

// ---------------------------------------------------------------------------
// WFIOSet
// ---------------------------------------------------------------------------

/// Specifies either an input (`in`) or output (`out`) data set.
///
/// Example:
/// ```
/// in order:Order;
/// out report:PDF;
/// in { items[i]:Product, config:Settings };
/// ```
final class WfIOSet extends WfIORequirement with EquatableMixin {
  /// `true` = input, `false` = output.
  final bool isInput;

  /// The data items in this I/O set.
  final WfDataSet dataSet;

  const WfIOSet({required this.isInput, required this.dataSet});

  /// Convenience: create an input I/O set with one named, typed item.
  factory WfIOSet.inputItem(String name, WfTypeRef type) => WfIOSet(
        isInput: true,
        dataSet: WfDataSet.single(WfDataIO(name: NodeId(name), type: type)),
      );

  /// Convenience: create an output I/O set with one named, typed item.
  factory WfIOSet.outputItem(String name, WfTypeRef type) => WfIOSet(
        isInput: false,
        dataSet: WfDataSet.single(WfDataIO(name: NodeId(name), type: type)),
      );

  @override
  List<Object?> get props => [isInput, dataSet];
}

// ---------------------------------------------------------------------------
// WFIORule
// ---------------------------------------------------------------------------

/// An explicit data-mapping rule from an input set to an output set.
///
/// Written as:
/// ```
/// in order -> out invoice;
/// in { source1, source2 } -> out { result1, result2 };
/// ```
///
/// I/O rules allow a process or task to declare precise data-flow
/// transformations rather than simply listing inputs and outputs separately.
final class WfIORule extends WfIORequirement with EquatableMixin {
  final WfDataSet inputSet;
  final WfDataSet outputSet;

  const WfIORule({required this.inputSet, required this.outputSet});

  @override
  List<Object?> get props => [inputSet, outputSet];
}
