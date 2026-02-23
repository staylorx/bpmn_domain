import 'package:equatable/equatable.dart';
import 'cd_visibility.dart';

/// A single field/attribute declared inside a CD class or interface.
///
/// Attributes in MontiCore CD4Analysis correspond to Java fields.
/// Each attribute has:
///
/// - A [name] that is unique within its declaring classifier.
/// - A [type] string as written in the source (e.g. `String`, `int`,
///   `List<Product>`, `java.time.ZonedDateTime`).
/// - A [visibility] modifier (default [CdVisibility.packageLocal]).
/// - An optional [isDerived] flag (written `/` prefix in the source) which
///   marks computed/derived attributes whose values are not stored but
///   computed from other attributes.
///
/// ## Examples from the `.cd` files
///
/// ```cd
/// // OrderToDelivery.cd
/// public String orderID;          // simple built-in
/// public int numberOfOrderedProducts;
/// public List<Product> orderList; // generic collection
/// public double totalCost;
/// public InventoryAvailabilityChecker checker; // cross-class reference
///
/// // Domain.cd
/// java.time.ZonedDateTime hiringDate;   // fully-qualified type
/// public int version;
/// /int workingDays;                     // derived attribute
/// /int remainingLeaveDays;
/// boolean valid;
/// boolean approved;
/// ```
///
/// ## Derived attributes
///
/// The `/` prefix (e.g. `/int workingDays`) marks a derived attribute.
/// Its value is computed from other attributes rather than stored.  In the
/// domain model we represent this with [isDerived] = `true`.
class CdAttribute with EquatableMixin {
  /// The attribute name, e.g. `orderID`, `workingDays`.
  final String name;

  /// The raw type expression as written, e.g. `String`, `List<Product>`,
  /// `java.time.ZonedDateTime`.
  final String type;

  /// Visibility modifier.
  final CdVisibility visibility;

  /// `true` when the attribute is derived (written with a `/` prefix).
  final bool isDerived;

  const CdAttribute({
    required this.name,
    required this.type,
    this.visibility = CdVisibility.packageLocal,
    this.isDerived = false,
  });

  // Convenience constructors -----------------------------------------------

  /// Creates a `public` attribute.
  factory CdAttribute.public(String name, String type) =>
      CdAttribute(name: name, type: type, visibility: CdVisibility.public);

  /// Creates a derived `public` attribute.
  factory CdAttribute.derived(String name, String type,
          {CdVisibility visibility = CdVisibility.packageLocal}) =>
      CdAttribute(
          name: name, type: type, visibility: visibility, isDerived: true);

  @override
  List<Object?> get props => [name, type, visibility, isDerived];

  @override
  String toString() {
    final vis =
        visibility == CdVisibility.packageLocal ? '' : '${visibility.name} ';
    final derived = isDerived ? '/' : '';
    return '$vis$derived$type $name;';
  }
}
