import 'package:equatable/equatable.dart';
import '../value_objects/node_id.dart';
import '../value_objects/wf_type_ref.dart';
import 'flow_element.dart';

// ---------------------------------------------------------------------------
// WfDataKind
// ---------------------------------------------------------------------------

/// Distinguishes between transient data objects and persistent data stores.
///
/// | Kind          | DSL keyword | Semantics                                    |
/// |---------------|-------------|----------------------------------------------|
/// | [dataObject]  | `data`      | Transient data scoped to the process instance|
/// | [dataStore]   | `store`     | Persistent data shared across instances      |
enum DataKind {
  /// `data` — a data object scoped to the current process instance.
  ///
  /// Transient data objects carry information between activities within a
  /// single process execution.  They are created when the process starts
  /// and destroyed when it ends.
  ///
  /// Example:
  /// ```
  /// data order:Order;
  /// data checker:InventoryAvailabilityChecker;
  /// ```
  dataObject,

  /// `store` — a data store that persists beyond the process instance.
  ///
  /// Data stores represent external persistence (databases, file systems,
  /// etc.) and can be read and written by tasks across multiple process
  /// instances.
  ///
  /// Example:
  /// ```
  /// store products:Product;
  /// ```
  dataStore,
}

// ---------------------------------------------------------------------------
// WfDataObject entity
// ---------------------------------------------------------------------------

/// A **data object** or **data store** declared in a process or subprocess.
///
/// Data objects make explicit the data that a process consumes and produces.
/// They are declared at the process level and referenced by tasks through
/// their I/O specifications or directly by name in `resources` lists.
///
/// ## Data objects (`data`)
///
/// ```
/// data order:Order;
/// data checker:InventoryAvailabilityChecker;
/// data agreement:CustomerDeliveryAgreement;
/// ```
///
/// These are transient: they exist only for the lifetime of the process
/// instance.  Multiple tasks may read the same data object; the BPMN model
/// specifies which tasks write to it through I/O associations.
///
/// ## Data stores (`store`)
///
/// ```
/// store products:Product;
/// ```
///
/// A data store is backed by an external persistent medium.  It is
/// accessible to all process instances simultaneously, so concurrent
/// access requires care.  The Workflow DSL does not model transactions or
/// isolation levels for data stores.
///
/// ## Relationship to task resources
///
/// Manual tasks may reference data objects directly via the `resources` list:
/// ```
/// manual task PrepareAndPackProducts {
///   resources = order, products;
/// }
/// ```
/// This indicates the manual worker needs access to both `order` (a data
/// object) and `products` (a data store) to perform the task.
class WfDataObject with EquatableMixin implements FlowElement {
  /// The unique name of this data object within its enclosing scope.
  @override
  final NodeId id;

  /// Whether this is a transient data object or a persistent data store.
  final DataKind kind;

  /// The declared type of the data.  Must resolve to a type visible in scope
  /// (either a built-in or an imported class-diagram type).
  final WfTypeRef type;

  const WfDataObject({
    required this.id,
    required this.kind,
    required this.type,
  });

  /// Creates a transient data object declaration.
  factory WfDataObject.data(String name, String typeName) => WfDataObject(
        id: NodeId(name),
        kind: DataKind.dataObject,
        type: WfTypeRef.named(typeName),
      );

  /// Creates a data store declaration.
  factory WfDataObject.store(String name, String typeName) => WfDataObject(
        id: NodeId(name),
        kind: DataKind.dataStore,
        type: WfTypeRef.named(typeName),
      );

  /// `true` when this is a transient data object.
  bool get isDataObject => kind == DataKind.dataObject;

  /// `true` when this is a persistent data store.
  bool get isDataStore => kind == DataKind.dataStore;

  @override
  List<Object?> get props => [id, kind, type];
}
