import 'package:equatable/equatable.dart';

/// Represents an import statement in a `.wfm` compilation unit.
///
/// Workflow models can import type symbols from external artifact symbol tables
/// (e.g. class diagrams compiled to `.cdsym` files) using Java-style import
/// syntax:
///
/// ```
/// import de.monticore.bpmn.cds.OrderToDelivery.*;
/// ```
///
/// Imports make external type names visible within the process body so they
/// can be used in `data`, `store`, `message` and operation signature
/// declarations.
///
/// The [wildcard] flag is `true` when the import ends with `.*`.
///
/// Usage:
/// ```dart
/// final imp = ImportStatement(
///   path: 'de.monticore.bpmn.cds.OrderToDelivery',
///   wildcard: true,
/// );
/// ```
class ImportStatement with EquatableMixin {
  /// The dot-separated path up to (but not including) the trailing `.*` or
  /// the final simple name, depending on [wildcard].
  final String path;

  /// `true` when the import is a wildcard (`.*`) import.
  final bool wildcard;

  const ImportStatement({required this.path, this.wildcard = false});

  @override
  List<Object?> get props => [path, wildcard];

  @override
  String toString() => 'import ${wildcard ? '$path.*' : path};';
}
