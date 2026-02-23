import 'package:equatable/equatable.dart';
import '../value_objects/import_statement.dart';
import '../value_objects/node_id.dart';
import '../value_objects/package_path.dart';
import '../value_objects/stereotype.dart';
import 'flow_element.dart';
import 'io_requirement.dart';

// ---------------------------------------------------------------------------
// WfLane
// ---------------------------------------------------------------------------

/// A **lane** is a named swimlane partition within a process.
///
/// Lanes do not change the control flow — every [FlowElement] inside a lane
/// participates in the same sequence-flow graph as elements in other lanes.
/// They are purely an *organisational* construct that assigns ownership or
/// responsibility to process steps.
///
/// Common uses:
/// - Separating responsibilities by department (`Sales`, `Warehouse`, `Finance`)
/// - Segregating system vs. human actors (`Automated`, `ManualReview`)
/// - Grouping related tasks visually without affecting execution semantics
///
/// Lanes may carry a [WfModifier] (e.g. for access control in tool integrations).
///
/// Context conditions:
/// - A lane must contain at least one [FlowElement].
/// - Sequence flows may cross lane boundaries freely.
///
/// DSL example:
/// ```
/// lane Sales {
///   start event ReceiveOrder catch;
///   service task ProcessOrder { webservice = ##webservice; }
///   split xor OrderFulfillable;
///   merge xor FinishOrderProcessing;
/// }
///
/// lane Warehouse {
///   manual task PrepareAndPackProducts { resources = order, products; }
///   end event OrderCompleted;
/// }
/// ```
class WfLane with EquatableMixin implements FlowElement {
  /// The unique name of this lane within its enclosing process.
  @override
  final NodeId id;

  /// All flow elements declared inside this lane.
  final List<FlowElement> elements;

  /// Access modifier and stereotype annotations.
  final WfModifier modifier;

  const WfLane({
    required this.id,
    required this.elements,
    this.modifier = WfModifier.none,
  });

  @override
  List<Object?> get props => [id, elements, modifier];
}

// ---------------------------------------------------------------------------
// WfProcess
// ---------------------------------------------------------------------------

/// A **process** is the top-level container for a workflow model.
///
/// In the Workflow DSL, a process corresponds directly to a BPMN 2.0 Process
/// element.  It has:
///
/// - A [name] that is unique within its [package].
/// - Zero or more [ioRequirements] declaring global data consumed/produced.
/// - A body of [elements] — any combination of lanes, tasks, gateways,
///   events, subprocesses, data objects, notifications, operations, and
///   sequence flows.
///
/// ## Compilation unit vs. process
///
/// A `.wfm` file is a [WorkflowCompilationUnit] that wraps exactly one
/// [WfProcess].  The compilation unit carries the package declaration and
/// import statements; the process carries everything else.
///
/// ## Reference processes
///
/// A process may serve as a **reference model** against which concrete
/// process models are conformance-checked.  The reference model defines
/// the *abstract* activities that must be incarnated in the concrete model.
///
/// ## Access modifier
///
/// The [modifier] on a process can carry stereotypes used by conformance
/// tooling or visibility constraints used by multi-process compositions.
///
/// ## Flat vs. lane-structured
///
/// A process body may be entirely flat (all elements at the top level) or
/// structured with [WfLane]s.  The two styles can be mixed — elements may
/// appear both inside and outside lanes in the same process.
///
/// ## Example
///
/// ```
/// process OrderToDeliveryWorkflow {
///   data order:Order;
///   store products:Product;
///   message cancelMsg:String;
///   operation prepCancelMsg(in cancelMsg; out cancelMsg);
///
///   lane Sales { ... }
///   lane Warehouse { ... }
///
///   ReceiveOrder -> ProcessOrder -> ... -> OrderCompleted;
/// }
/// ```
class WfProcess with EquatableMixin implements FlowElement {
  /// The process name (unique within its package).
  @override
  final NodeId id;

  /// Optional access modifier and stereotype annotations.
  final WfModifier modifier;

  /// Global I/O requirements declared at process scope.
  final List<WfIORequirement> ioRequirements;

  /// All [FlowElement]s in the process body (lanes, tasks, events, gateways,
  /// data objects, notifications, operations, sequence flows, subprocesses).
  final List<FlowElement> elements;

  const WfProcess({
    required this.id,
    this.modifier = WfModifier.none,
    this.ioRequirements = const [],
    this.elements = const [],
  });

  // Convenience element accessors -----------------------------------------

  /// All [WfLane]s declared in this process.
  List<WfLane> get lanes => elements.whereType<WfLane>().toList();

  /// Whether this process is partitioned into lanes.
  bool get hasLanes => lanes.isNotEmpty;

  @override
  List<Object?> get props => [id, modifier, ioRequirements, elements];
}

// ---------------------------------------------------------------------------
// WorkflowCompilationUnit
// ---------------------------------------------------------------------------

/// The root entity for a `.wfm` source file.
///
/// A workflow compilation unit is the top-level artefact produced by parsing
/// a single `.wfm` file.  It mirrors the `WorkflowCompilationUnit` grammar
/// rule which wraps exactly one [WfProcess] with optional package and import
/// declarations.
///
/// ## Package and imports
///
/// The optional [package] declaration qualifies the process name:
/// ```
/// package de.monticore.bpmn.examples;
/// ```
///
/// Import statements make external type symbols (from compiled class diagram
/// symbol tables) visible inside the process:
/// ```
/// import de.monticore.bpmn.cds.OrderToDelivery.*;
/// ```
///
/// The fully qualified name of the process is
/// `package.processName` (e.g. `de.monticore.bpmn.examples.OrderToDeliveryWorkflow`).
///
/// ## Symbol file
///
/// A `.wfm` compilation unit can be serialised to a `.wfsym` file containing
/// the symbol table.  The domain model does not model the symbol file itself —
/// that belongs in the data layer.
///
/// ## Usage in a parser
///
/// The parser produces a [WorkflowCompilationUnit] as its output.  A
/// subsequent symbol-resolution pass links [WfDataObject] type references and
/// [WfOperation] parameter names to the types imported from class diagram
/// symbol tables.
class WorkflowCompilationUnit with EquatableMixin {
  /// The optional package path, e.g. `de.monticore.bpmn.examples`.
  final PackagePath package;

  /// Import statements bringing external type symbols into scope.
  final List<ImportStatement> imports;

  /// The single process defined in this compilation unit.
  final WfProcess process;

  const WorkflowCompilationUnit({
    required this.process,
    this.package = PackagePath.root,
    this.imports = const [],
  });

  /// The fully qualified process name.
  String get fullyQualifiedName => package.qualify(process.id.value);

  @override
  List<Object?> get props => [package, imports, process];
}
