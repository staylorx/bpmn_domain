import 'package:equatable/equatable.dart';

/// Represents the optional package declaration at the top of a `.wfm` file.
///
/// In the Workflow DSL a compilation unit may begin with a package declaration
/// such as `package de.monticore.bpmn.examples;`.  This mirrors Java-style
/// packaging and governs the fully-qualified name of the enclosed process.
///
/// Usage:
/// ```dart
/// final pkg = PackagePath.parse('de.monticore.bpmn.examples');
/// // pkg.segments == ['de', 'monticore', 'bpmn', 'examples']
/// // pkg.toString() == 'de.monticore.bpmn.examples'
/// ```
class PackagePath with EquatableMixin {
  /// The individual path components, e.g. `['de', 'monticore', 'bpmn']`.
  final List<String> segments;

  const PackagePath(this.segments);

  /// The top-level (root) package with no path segments.
  static const PackagePath root = PackagePath([]);

  /// Parses a dot-separated package string.  An empty string yields [root].
  factory PackagePath.parse(String dotSeparated) {
    if (dotSeparated.isEmpty) return root;
    return PackagePath(dotSeparated.split('.'));
  }

  /// Whether this is the unnamed root package.
  bool get isRoot => segments.isEmpty;

  /// Returns the fully qualified name of [simpleName] within this package.
  String qualify(String simpleName) =>
      isRoot ? simpleName : '${toString()}.$simpleName';

  @override
  List<Object?> get props => [segments];

  @override
  String toString() => segments.join('.');
}
