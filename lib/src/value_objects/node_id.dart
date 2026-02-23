import 'package:equatable/equatable.dart';

/// A strongly-typed, immutable identifier for any named node within a
/// BPMN workflow model (event, task, gateway, lane, subprocess, etc.).
///
/// Node identifiers in the Workflow DSL are unqualified names that are unique
/// within the scope of the enclosing [WfProcess] or [WfSubProcess].  When a
/// parser resolves cross-scope references (e.g. a [WfCallActivity] calling
/// another process) the qualified form — "package.ProcessName.NodeName" — is
/// represented by [QualifiedNodeId].
///
/// Usage:
/// ```dart
/// final id = NodeId('ProcessOrder');
/// final same = NodeId('ProcessOrder');
/// assert(id == same); // structural equality via Equatable
/// ```
class NodeId with EquatableMixin {
  /// The raw name string exactly as it appears in the `.wfm` source.
  final String value;

  const NodeId(this.value) : assert(value != '');

  /// Whether this identifier follows the simple (unqualified) name rule:
  /// starts with a letter or `_`, followed by letters, digits, or `_`.
  bool get isSimpleName => RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(value);

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

/// A qualified node identifier of the form `a.b.c`, where the final segment is
/// the node's own name and the preceding segments form the package / process
/// path.
///
/// Example: `de.monticore.bpmn.examples.OrderToDeliveryWorkflow.ProcessOrder`
class QualifiedNodeId with EquatableMixin {
  /// All path segments, including the final simple name.
  final List<String> segments;

  const QualifiedNodeId(this.segments) : assert(segments.length > 0);

  /// Creates a [QualifiedNodeId] from a dot-separated string.
  factory QualifiedNodeId.parse(String dotSeparated) =>
      QualifiedNodeId(dotSeparated.split('.'));

  /// The simple name — the last segment.
  String get simpleName => segments.last;

  /// Everything before the final segment, joined with `.`.
  String get qualifier => segments.take(segments.length - 1).join('.');

  @override
  List<Object?> get props => [segments];

  @override
  String toString() => segments.join('.');
}
