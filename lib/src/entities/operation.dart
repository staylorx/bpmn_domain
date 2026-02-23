import 'package:equatable/equatable.dart';
import '../value_objects/node_id.dart';
import '../value_objects/stereotype.dart';
import 'flow_element.dart';

/// A **workflow operation** is a typed function signature that can be invoked
/// by tasks (service, send, receive) and referenced by message events within
/// executable processes.
///
/// Operations define the formal interface between the process and external
/// services or systems.  They map directly to service interface methods in
/// service-oriented and microservice architectures.
///
/// ## Grammar shape
///
/// ```
/// operation prepCancelMsg(
///   in cancelMsg;
///   out cancelMsg
/// );
///
/// operation getAddress(
///   in customerID;
///   out address
/// );
///
/// // With error declarations and an implementation string
/// operation validatePayment(
///   in paymentRequest;
///   out receipt
/// ) throws paymentError {
///   "validatePayment(paymentRequest)"
/// };
/// ```
///
/// ## Parameters
///
/// Operations have exactly **one input** ([inParam]) referencing a
/// [WfNotification] symbol and at most **one output** ([outParam]).
/// This matches the BPMN WS-BPMN binding model which maps operations to
/// one-way or request-response interactions.
///
/// ## Error declarations
///
/// An operation can declare zero or more named errors that it may throw.
/// These are referenced via [WfNotification] names with `kind == error`.
///
/// ## Implementation
///
/// The optional [implementation] string carries an expression, URL, or
/// inline script that describes how the operation is realised.  In
/// model-to-code generation this might become a method call expression.
class WfOperation with EquatableMixin implements FlowElement {
  /// The unique name of this operation within its enclosing scope.
  @override
  final NodeId id;

  /// The single input parameter — references a [WfNotification] by name.
  final NodeId inParam;

  /// The optional output parameter — references a [WfNotification] by name.
  final NodeId? outParam;

  /// Named errors that this operation may throw (references [WfNotification]
  /// with `kind == error`).
  final List<NodeId> thrownErrors;

  /// Optional implementation expression, URL, or inline script.
  final String? implementation;

  /// Access modifier and stereotype annotations.
  final WfModifier modifier;

  const WfOperation({
    required this.id,
    required this.inParam,
    this.outParam,
    this.thrownErrors = const [],
    this.implementation,
    this.modifier = WfModifier.none,
  });

  // Convenience constructors ---------------------------------------------------

  /// Creates a simple request-response operation.
  factory WfOperation.requestResponse({
    required String name,
    required String input,
    required String output,
  }) =>
      WfOperation(
        id: NodeId(name),
        inParam: NodeId(input),
        outParam: NodeId(output),
      );

  /// Creates a one-way (fire-and-forget) operation.
  factory WfOperation.oneWay({
    required String name,
    required String input,
  }) =>
      WfOperation(
        id: NodeId(name),
        inParam: NodeId(input),
      );

  /// `true` when this operation produces an output.
  bool get hasOutput => outParam != null;

  /// `true` when this operation can throw errors.
  bool get canThrowErrors => thrownErrors.isNotEmpty;

  @override
  List<Object?> get props =>
      [id, inParam, outParam, thrownErrors, implementation, modifier];
}
