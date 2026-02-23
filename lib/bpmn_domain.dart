library;

/// BPMN Domain — clean-architecture domain entities for BPMN 2.0 Workflow DSL.
///
/// This library provides the complete domain model for parsing and working
/// with MontiCore Workflow DSL (`.wfm`) and Class Diagram (`.cd`) files.
///
/// ## Workflow model entities
///
/// - [WorkflowCompilationUnit] — root of a parsed `.wfm` file
/// - [WfProcess] — a single BPMN process
/// - [WfLane] — a swimlane partition within a process
/// - [WfTask] — an atomic activity (service, send, receive, user, manual, etc.)
/// - [WfSubProcess] — an embedded / transaction / ad-hoc subprocess
/// - [WfCallActivity] — a call to a reusable external process
/// - [WfGateway] / [WfInlineGateway] — flow-control elements (split/merge)
/// - [WfEvent] — start, end, and intermediate events
/// - [WfDataObject] — data and store declarations
/// - [WfNotification] — message, signal, error, escalation payloads
/// - [WfOperation] — typed service operation signatures
/// - [SequenceFlow] — directed connections between flow elements
///
/// ## Class diagram entities
///
/// - [CdCompilationUnit] / [CdClassDiagram] — root of a parsed `.cd` file
/// - [CdClass] — a class with attributes, methods, inheritance
/// - [CdInterface] — an interface contract
/// - [CdEnum] — an enumeration of named constants
/// - [CdAssociation] — a directed relationship between classifiers
/// - [CdAttribute] — a field on a classifier
/// - [CdMethod] — a method signature on a classifier
///
/// ## Value objects
///
/// - [NodeId] / [QualifiedNodeId] — typed node identifiers
/// - [PackagePath] — dot-separated package declarations
/// - [WfModifier] / [Stereotype] — UML modifiers and stereotype annotations
/// - [WfTypeRef] — a reference to an external or built-in type
/// - [ImportStatement] — an import declaration
/// - Timer conditions: [AtTimerCondition], [OnDateTimerCondition],
///   [AfterPeriodCondition], [EveryTimeCondition], [CronTimerCondition]
///
/// ## Failures
///
/// - [WorkflowFailure] and subclasses — typed domain-level validation failures
///   corresponding to MontiCore CoCo violations.
// Value objects
export 'src/value_objects/node_id.dart';
export 'src/value_objects/package_path.dart';
export 'src/value_objects/stereotype.dart';
export 'src/value_objects/wf_type_ref.dart';
export 'src/value_objects/import_statement.dart';
export 'src/value_objects/timer_condition.dart';

// Flow element base
export 'src/entities/flow_element.dart';

// Gateway entities
export 'src/entities/gateway.dart';

// Event entities
export 'src/entities/event_trigger.dart';
export 'src/entities/event.dart';

// Activity entities
export 'src/entities/loop_characteristic.dart';
export 'src/entities/task.dart';
export 'src/entities/subprocess.dart';

// Data entities
export 'src/entities/io_requirement.dart';
export 'src/entities/data_object.dart';
export 'src/entities/notification.dart';
export 'src/entities/operation.dart';

// Flow entities
export 'src/entities/sequence_flow.dart';

// Process entities
export 'src/entities/process.dart';

// Class diagram entities
export 'src/cd/cd_visibility.dart';
export 'src/cd/cd_attribute.dart';
export 'src/cd/cd_method.dart';
export 'src/cd/cd_association.dart';
export 'src/cd/cd_classifier.dart';
export 'src/cd/cd_class_diagram.dart';

// Failures
export 'src/failures/workflow_failure.dart';
