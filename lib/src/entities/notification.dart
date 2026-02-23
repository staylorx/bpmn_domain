import 'package:equatable/equatable.dart';
import '../value_objects/node_id.dart';
import '../value_objects/stereotype.dart';
import '../value_objects/wf_type_ref.dart';
import 'event_trigger.dart';
import 'flow_element.dart';

/// A **notification** is a typed, named payload that flows between workflow
/// participants via message, signal, error, or escalation mechanisms.
///
/// Notifications are declared at the process level (or inside a subprocess)
/// and referenced by:
///
/// - **Event triggers** — `WFEventTriggerNotification` associates an event
///   with a notification to indicate what is sent or received.
/// - **Send/receive tasks** — the `message` attribute of a send or receive
///   task references a notification.
/// - **Operations** — `WFOperation` parameters (`in` / `out`) reference
///   notifications.
///
/// ## The four notification kinds
///
/// | Kind         | DSL keyword  | Communication pattern           |
/// |--------------|--------------|---------------------------------|
/// | message      | `message`    | Point-to-point (one sender, one receiver) |
/// | signal       | `signal`     | Broadcast (one sender, many listeners)    |
/// | error        | `error`      | Exception — caught by error boundary events |
/// | escalation   | `escalation` | Non-fatal issue — caught by escalation events |
///
/// ## Examples
///
/// ```
/// message cancelMsg:String;
/// message customerID:String;
/// message address:DestinationAddress;
/// error outOfStockError:OutOfStockException;
/// escalation slaBreach:SLAViolation;
/// signal orderReadySignal:OrderReady;
/// ```
///
/// ## Type system
///
/// The [type] field references a [WfTypeRef] which the parser must later
/// resolve against imported symbol tables.  Built-in types like `String` are
/// always available.
class WfNotification with EquatableMixin implements FlowElement {
  /// The unique name of this notification within its enclosing scope.
  @override
  final NodeId id;

  /// The category / routing mechanism of this notification.
  final NotificationKind kind;

  /// The payload type carried by this notification.
  final WfTypeRef type;

  /// Access modifier and stereotype annotations.
  final WfModifier modifier;

  const WfNotification({
    required this.id,
    required this.kind,
    required this.type,
    this.modifier = WfModifier.none,
  });

  // Convenience constructors ---------------------------------------------------

  /// Creates a `message` notification with the given payload type.
  factory WfNotification.message(String name, WfTypeRef type) => WfNotification(
        id: NodeId(name),
        kind: NotificationKind.message,
        type: type,
      );

  /// Creates a `signal` notification with the given payload type.
  factory WfNotification.signal(String name, WfTypeRef type) => WfNotification(
        id: NodeId(name),
        kind: NotificationKind.signal,
        type: type,
      );

  /// Creates an `error` notification (exception payload).
  factory WfNotification.error(String name, WfTypeRef type) => WfNotification(
        id: NodeId(name),
        kind: NotificationKind.error,
        type: type,
      );

  /// Creates an `escalation` notification.
  factory WfNotification.escalation(String name, WfTypeRef type) =>
      WfNotification(
        id: NodeId(name),
        kind: NotificationKind.escalation,
        type: type,
      );

  // Derived helpers -----------------------------------------------------------

  bool get isMessage => kind == NotificationKind.message;
  bool get isSignal => kind == NotificationKind.signal;
  bool get isError => kind == NotificationKind.error;
  bool get isEscalation => kind == NotificationKind.escalation;

  @override
  List<Object?> get props => [id, kind, type, modifier];
}
