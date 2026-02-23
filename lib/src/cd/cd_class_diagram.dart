import 'package:equatable/equatable.dart';
import '../value_objects/package_path.dart';
import 'cd_association.dart';
import 'cd_classifier.dart';

/// The top-level entity representing a MontiCore CD4Analysis class diagram.
///
/// A class diagram (`.cd` file) defines the type system that a set of
/// BPMN workflow models may import and reference.  The workflow grammar's
/// `import` statement resolves type names against compiled class diagram
/// symbol tables (`.cdsym` files), but the domain model preserves the full
/// structural definition so that downstream tooling can:
///
/// - Validate that referenced types actually exist.
/// - Generate code skeletons for data objects.
/// - Perform data-flow analysis (trace which fields flow through which tasks).
///
/// ## The two `.cd` files in the BPMN repository
///
/// ### `OrderToDelivery.cd`
///
/// ```
/// package de.monticore.bpmn.cds;
/// classdiagram OrderToDelivery { ... }
/// ```
///
/// Defines the domain model for the order-to-delivery business process:
///
/// | Class                        | Purpose                                              |
/// |------------------------------|------------------------------------------------------|
/// | [InventoryAvailabilityChecker] | Holds availability check results for ordered products |
/// | [Order]                      | Represents a customer order with line items           |
/// | [Product]                    | A single orderable product                            |
/// | [CustomerDeliveryAgreement]  | Tracks pickup vs. shipment preference per customer    |
/// | [DestinationAddress]         | Physical delivery address                             |
/// | [PaymentValidityChecker]     | Holds card validation results                         |
///
/// ### `Domain.cd`
///
/// ```
/// package de.monticore.bpmn.cds;
/// classdiagram Domain { ... }
/// ```
///
/// Defines a generic HR/leave-management domain used by a leave-request
/// workflow:
///
/// | Class                 | Purpose                                             |
/// |-----------------------|-----------------------------------------------------|
/// | [Contract]            | Employment contract with version and hiring date    |
/// | [DomainUser]          | System user / employee (associated to a Contract)   |
/// | [Report]              | Outcome document of a leave-request review          |
/// | [LeaveCard]           | Aggregates leave entries for a user                 |
/// | [LeaveEntry]          | A single leave request with dates and derived days  |
/// | [MedicalCertificate]  | Supporting document for sick-leave requests         |
///
/// ## Class diagram structure
///
/// A [CdClassDiagram] contains:
/// - [classifiers] — classes, interfaces, and enums
/// - [associations] — directed relationships between classifiers
///
/// These are assembled from parsed `.cd` source using the domain layer.
/// The parser (future data layer) converts raw source text into this entity.
class CdClassDiagram with EquatableMixin {
  /// The diagram name, e.g. `OrderToDelivery`, `Domain`.
  final String name;

  /// The package that qualifies this diagram's types.
  final PackagePath package;

  /// All type-defining classifiers (classes, interfaces, enums).
  final List<CdClassifier> classifiers;

  /// All associations between classifiers.
  final List<CdAssociation> associations;

  const CdClassDiagram({
    required this.name,
    required this.classifiers,
    this.package = PackagePath.root,
    this.associations = const [],
  });

  // Derived accessors -------------------------------------------------------

  /// All [CdClass]es in this diagram.
  List<CdClass> get classes => classifiers.whereType<CdClass>().toList();

  /// All [CdInterface]s in this diagram.
  List<CdInterface> get interfaces =>
      classifiers.whereType<CdInterface>().toList();

  /// All [CdEnum]s in this diagram.
  List<CdEnum> get enums => classifiers.whereType<CdEnum>().toList();

  /// Looks up a classifier by simple name.  Returns `null` if not found.
  CdClassifier? findClassifier(String simpleName) {
    for (final c in classifiers) {
      if (c.name == simpleName) return c;
    }
    return null;
  }

  /// Returns the fully qualified name of a classifier in this diagram.
  String fullyQualifiedName(String simpleName) =>
      package.qualify('$name.$simpleName');

  @override
  List<Object?> get props => [name, package, classifiers, associations];
}

/// A compiled class diagram compilation unit — the top-level entity for a
/// `.cd` source file.
///
/// Mirrors the structure of [WorkflowCompilationUnit] for the class diagram
/// language.  A `.cd` file contains exactly one [CdClassDiagram].
class CdCompilationUnit with EquatableMixin {
  final PackagePath package;
  final CdClassDiagram diagram;

  const CdCompilationUnit({
    required this.diagram,
    this.package = PackagePath.root,
  });

  @override
  List<Object?> get props => [package, diagram];
}
