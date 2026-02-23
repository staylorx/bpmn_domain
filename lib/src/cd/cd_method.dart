import 'package:equatable/equatable.dart';
import 'cd_visibility.dart';

/// A parameter in a [CdMethod] signature.
class CdMethodParameter with EquatableMixin {
  final String name;
  final String type;

  const CdMethodParameter({required this.name, required this.type});

  @override
  List<Object?> get props => [name, type];

  @override
  String toString() => '$type $name';
}

/// A method declaration inside a CD class or interface.
///
/// Methods in MontiCore CD4Analysis represent Java-style method signatures.
/// They are present on classes and interfaces, carrying a return type,
/// parameter list, and visibility.
///
/// CD methods are used:
/// - To model service interface methods callable by workflow [WfOperation]s
/// - To define computed behaviour on domain objects
///
/// ## Example
///
/// ```cd
/// public class InventoryAvailabilityChecker {
///   public boolean checkAvailability(String productID, int quantity);
/// }
/// ```
class CdMethod with EquatableMixin {
  /// The method name.
  final String name;

  /// The return type, e.g. `boolean`, `void`, `List<Product>`.
  final String returnType;

  /// The ordered parameter list.
  final List<CdMethodParameter> parameters;

  /// Visibility modifier.
  final CdVisibility visibility;

  /// `true` if the method is `abstract` (no body, must be implemented by subclasses).
  final bool isAbstract;

  /// `true` if the method is `static`.
  final bool isStatic;

  const CdMethod({
    required this.name,
    required this.returnType,
    this.parameters = const [],
    this.visibility = CdVisibility.packageLocal,
    this.isAbstract = false,
    this.isStatic = false,
  });

  @override
  List<Object?> get props =>
      [name, returnType, parameters, visibility, isAbstract, isStatic];

  @override
  String toString() {
    final vis =
        visibility == CdVisibility.packageLocal ? '' : '${visibility.name} ';
    final abs = isAbstract ? 'abstract ' : '';
    final stat = isStatic ? 'static ' : '';
    final params = parameters.join(', ');
    return '$vis$abs$stat$returnType $name($params);';
  }
}
