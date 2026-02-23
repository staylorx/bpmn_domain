import 'package:equatable/equatable.dart';
import 'cd_attribute.dart';
import 'cd_method.dart';
import 'cd_visibility.dart';

// ---------------------------------------------------------------------------
// CdClassifier interface
// ---------------------------------------------------------------------------

/// The common interface for all type-defining elements in a class diagram:
/// [CdClass], [CdInterface], and [CdEnum].
///
/// Classifiers have a [name] unique within the [CdClassDiagram] and may
/// carry [attributes] and [methods].
abstract interface class CdClassifier {
  String get name;
  List<CdAttribute> get attributes;
  List<CdMethod> get methods;
  CdVisibility get visibility;
}

// ---------------------------------------------------------------------------
// CdClass
// ---------------------------------------------------------------------------

/// A **class** in a MontiCore CD4Analysis class diagram.
///
/// Corresponds to a Java class — it may be concrete or abstract, and may
/// extend a single superclass and implement multiple interfaces.
///
/// ## Classes in the workflow domain
///
/// Class definitions in `.cd` files are imported into `.wfm` processes via
/// `import` statements.  The Workflow DSL uses them as:
///
/// - **Data object types**: `data order:Order;` — `Order` is a class.
/// - **Message payload types**: `message cancelMsg:String;`
/// - **Operation parameter types**: `in customerID; out address` where
///   `address` has type `DestinationAddress`.
/// - **Store types**: `store products:Product;`
///
/// ## Example — OrderToDelivery.cd
///
/// ```cd
/// public class Order {
///   public String orderID;
///   public String customerID;
///   public int numberOfOrderedProducts;
///   public List<Product> orderList;
///   public InventoryAvailabilityChecker checker;
///   public double totalCost;
/// }
/// ```
///
/// This class is the payload type of the `data order:Order;` declaration
/// in `OrderToDeliveryWorkflow.wfm`.  The `order.numberOfOrderedProducts`
/// field drives the multi-instance loop count on `CheckProductAvailability`.
///
/// ## Example — Domain.cd
///
/// ```cd
/// class Contract {
///   java.time.ZonedDateTime hiringDate;
///   public int version;
/// }
/// ```
///
/// ## Abstract classes
///
/// An abstract class is one that cannot be directly instantiated.  In the
/// CD grammar abstract classes use the `abstract` keyword:
/// ```cd
/// abstract class AbstractProcessor { ... }
/// ```
///
/// ## Superclass and interface inheritance
///
/// ```cd
/// public class SpecialOrder extends Order implements Trackable { ... }
/// ```
class CdClass with EquatableMixin implements CdClassifier {
  @override
  final String name;

  @override
  final CdVisibility visibility;

  @override
  final List<CdAttribute> attributes;

  @override
  final List<CdMethod> methods;

  /// Whether this class is declared `abstract`.
  final bool isAbstract;

  /// The name of the superclass, if any.
  final String? superClass;

  /// Names of interfaces this class implements.
  final List<String> interfaces;

  const CdClass({
    required this.name,
    this.visibility = CdVisibility.packageLocal,
    this.attributes = const [],
    this.methods = const [],
    this.isAbstract = false,
    this.superClass,
    this.interfaces = const [],
  });

  // Convenience constructors -----------------------------------------------

  /// Creates a simple public concrete class with only attributes.
  factory CdClass.publicData(
    String name, {
    List<CdAttribute> attributes = const [],
  }) =>
      CdClass(
        name: name,
        visibility: CdVisibility.public,
        attributes: attributes,
      );

  @override
  List<Object?> get props => [
        name,
        visibility,
        attributes,
        methods,
        isAbstract,
        superClass,
        interfaces
      ];
}

// ---------------------------------------------------------------------------
// CdInterface
// ---------------------------------------------------------------------------

/// An **interface** in a CD class diagram.
///
/// Interfaces declare contracts (method signatures) that implementing classes
/// must fulfil.  They may also declare constants (public static final
/// attributes).
///
/// In CD4Analysis interfaces use the `interface` keyword:
/// ```cd
/// interface Trackable {
///   public String getTrackingNumber();
/// }
/// ```
///
/// Classes can list interfaces in their `implements` clause.
class CdInterface with EquatableMixin implements CdClassifier {
  @override
  final String name;

  @override
  final CdVisibility visibility;

  @override
  final List<CdAttribute> attributes;

  @override
  final List<CdMethod> methods;

  /// Names of super-interfaces this interface extends.
  final List<String> superInterfaces;

  const CdInterface({
    required this.name,
    this.visibility = CdVisibility.packageLocal,
    this.attributes = const [],
    this.methods = const [],
    this.superInterfaces = const [],
  });

  @override
  List<Object?> get props =>
      [name, visibility, attributes, methods, superInterfaces];
}

// ---------------------------------------------------------------------------
// CdEnumConstant
// ---------------------------------------------------------------------------

/// A single constant in a [CdEnum].
class CdEnumConstant with EquatableMixin {
  final String name;

  const CdEnumConstant(this.name);

  @override
  List<Object?> get props => [name];

  @override
  String toString() => name;
}

// ---------------------------------------------------------------------------
// CdEnum
// ---------------------------------------------------------------------------

/// An **enumeration** in a CD class diagram.
///
/// Enums declare a closed set of named constants.  They may also carry
/// methods and attributes (e.g. a `String label` field per constant).
///
/// CD4Analysis syntax:
/// ```cd
/// enum PaymentMethod {
///   CREDIT_CARD, DEBIT_CARD, BANK_TRANSFER, PAYPAL;
///   public String label;
/// }
/// ```
///
/// Enums appear in workflow processes as data types for fields or message
/// payloads.  For example:
/// ```
/// data paymentDetails:PaymentMethod;
/// ```
class CdEnum with EquatableMixin implements CdClassifier {
  @override
  final String name;

  @override
  final CdVisibility visibility;

  final List<CdEnumConstant> constants;

  @override
  final List<CdAttribute> attributes;

  @override
  final List<CdMethod> methods;

  const CdEnum({
    required this.name,
    required this.constants,
    this.visibility = CdVisibility.packageLocal,
    this.attributes = const [],
    this.methods = const [],
  });

  @override
  List<Object?> get props => [name, visibility, constants, attributes, methods];
}
