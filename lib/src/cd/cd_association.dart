import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// CdMultiplicity
// ---------------------------------------------------------------------------

/// The UML multiplicity (cardinality) on one end of a [CdAssociation].
///
/// Common multiplicities:
///
/// | Notation   | Meaning                         |
/// |------------|---------------------------------|
/// | `[1]`      | Exactly one                     |
/// | `[0..1]`   | Zero or one (optional)          |
/// | `[*]`      | Zero or more (many)             |
/// | `[1..*]`   | One or more (at least one)      |
/// | `[2..5]`   | Between 2 and 5 (bounded range) |
class CdMultiplicity with EquatableMixin {
  /// Lower bound (0 or a positive integer).
  final int lower;

  /// Upper bound.  `-1` represents unlimited (`*`).
  final int upper;

  const CdMultiplicity({required this.lower, required this.upper})
      : assert(lower >= 0),
        assert(upper == -1 || upper >= lower);

  /// `[1]` — exactly one.
  static const CdMultiplicity one = CdMultiplicity(lower: 1, upper: 1);

  /// `[0..1]` — optional.
  static const CdMultiplicity optional = CdMultiplicity(lower: 0, upper: 1);

  /// `[*]` — zero or more.
  static const CdMultiplicity many = CdMultiplicity(lower: 0, upper: -1);

  /// `[1..*]` — one or more.
  static const CdMultiplicity atLeastOne = CdMultiplicity(lower: 1, upper: -1);

  factory CdMultiplicity.range(int lower, int upper) =>
      CdMultiplicity(lower: lower, upper: upper);

  /// `true` when upper bound is unlimited.
  bool get isUnbounded => upper == -1;

  @override
  List<Object?> get props => [lower, upper];

  @override
  String toString() {
    if (lower == 1 && upper == 1) return '[1]';
    if (lower == 0 && upper == -1) return '[*]';
    if (lower == 1 && upper == -1) return '[1..*]';
    if (lower == 0 && upper == 1) return '[0..1]';
    return '[$lower..$upper]';
  }
}

// ---------------------------------------------------------------------------
// CdAssociationKind
// ---------------------------------------------------------------------------

/// The structural kind of a [CdAssociation].
///
/// | Kind          | UML notation | Meaning                                          |
/// |---------------|--------------|--------------------------------------------------|
/// | association   | `-->`        | Simple directed reference                        |
/// | aggregation   | `o-->`       | Whole-part (part can exist without whole)        |
/// | composition   | `*-->`       | Strong whole-part (part's lifecycle depends on whole) |
enum CdAssociationKind {
  /// A plain directed association (reference relationship).
  association,

  /// An aggregation (shared ownership).
  aggregation,

  /// A composition (exclusive ownership; part cannot exist without whole).
  composition,
}

// ---------------------------------------------------------------------------
// CdAssociation entity
// ---------------------------------------------------------------------------

/// A directed relationship between two CD classifiers.
///
/// Associations in MontiCore CD4Analysis correspond to UML associations and
/// encode relationships between classes in the domain model.
///
/// ## Examples from `Domain.cd`
///
/// ```cd
/// association [1] DomainUser -> Contract [*];
/// association entries [1] LeaveCard -> LeaveEntry [*];
/// association [1] LeaveCard -> DomainUser [1];
/// ```
///
/// Each association has:
/// - An optional [roleName] for the target end (e.g. `entries`).
/// - A [sourceMultiplicity] on the left side.
/// - A [targetMultiplicity] on the right side.
/// - A [sourceType] and [targetType] referencing class names.
/// - A [kind] (association / aggregation / composition).
///
/// ## Direction
///
/// All associations in the DSL files are **directed** (navigable from
/// source to target via `->` arrow).  The source end does not have a
/// role name unless written explicitly.
///
/// ## Role names
///
/// The optional role name appears between the source multiplicity and the
/// target class name:
/// ```
/// association entries [1] LeaveCard -> LeaveEntry [*];
/// //           ^^^^^^ role name
/// ```
/// This means a `LeaveCard` has a collection of `LeaveEntry` objects
/// accessible via the `entries` role.
class CdAssociation with EquatableMixin {
  /// Optional name of the association itself (rarely used).
  final String? associationName;

  /// Optional role name for the target navigation end.
  final String? roleName;

  /// Multiplicity on the source (left) side.
  final CdMultiplicity sourceMultiplicity;

  /// Multiplicity on the target (right) side.
  final CdMultiplicity targetMultiplicity;

  /// The simple name of the source classifier.
  final String sourceType;

  /// The simple name of the target classifier.
  final String targetType;

  /// The structural kind of the relationship.
  final CdAssociationKind kind;

  const CdAssociation({
    required this.sourceType,
    required this.targetType,
    required this.sourceMultiplicity,
    required this.targetMultiplicity,
    this.associationName,
    this.roleName,
    this.kind = CdAssociationKind.association,
  });

  // Convenience constructors -----------------------------------------------

  /// `association [1] A -> B [*]` — one A has many B.
  factory CdAssociation.oneToMany({
    required String source,
    required String target,
    String? roleName,
  }) =>
      CdAssociation(
        sourceType: source,
        targetType: target,
        sourceMultiplicity: CdMultiplicity.one,
        targetMultiplicity: CdMultiplicity.many,
        roleName: roleName,
      );

  /// `association [1] A -> B [1]` — one-to-one relationship.
  factory CdAssociation.oneToOne({
    required String source,
    required String target,
  }) =>
      CdAssociation(
        sourceType: source,
        targetType: target,
        sourceMultiplicity: CdMultiplicity.one,
        targetMultiplicity: CdMultiplicity.one,
      );

  @override
  List<Object?> get props => [
        associationName,
        roleName,
        sourceMultiplicity,
        targetMultiplicity,
        sourceType,
        targetType,
        kind,
      ];

  @override
  String toString() {
    final kindStr = kind.name;
    final roleStr = roleName != null ? '$roleName ' : '';
    return '$kindStr $sourceMultiplicity $sourceType -> $roleStr$targetType $targetMultiplicity;';
  }
}
