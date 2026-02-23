import 'package:equatable/equatable.dart';

/// A reference to an external or built-in type used in data declarations,
/// message payloads, and operation signatures within a workflow.
///
/// Type references in the Workflow DSL resolve against imported symbol tables
/// (e.g. class diagrams).  Examples:
///
/// - `Order`                   → a simple type name from an import
/// - `String`                  → a built-in primitive
/// - `List<Product>`           → a generic collection type (MCCollectionTypes)
/// - `de.monticore.bpmn.cds.OrderToDelivery.DestinationAddress`
///                             → a fully-qualified external type
///
/// The domain model does not attempt to *resolve* the type; it merely stores
/// the reference as written in the source so that a later resolution phase can
/// bind it to a concrete type descriptor.
///
/// Usage:
/// ```dart
/// final t = WfTypeRef.named('Order');
/// final t2 = WfTypeRef.named('List<Product>');
/// ```
class WfTypeRef with EquatableMixin {
  /// The raw type expression as it appears in the source.
  final String expression;

  const WfTypeRef(this.expression) : assert(expression != '');

  /// Creates a [WfTypeRef] for a plain named type.
  factory WfTypeRef.named(String name) => WfTypeRef(name);

  /// The well-known `String` built-in type.
  static const WfTypeRef string = WfTypeRef('String');

  /// The well-known `int` built-in type.
  static const WfTypeRef integer = WfTypeRef('int');

  /// The well-known `bool` built-in type.
  static const WfTypeRef boolean = WfTypeRef('bool');

  @override
  List<Object?> get props => [expression];

  @override
  String toString() => expression;
}
