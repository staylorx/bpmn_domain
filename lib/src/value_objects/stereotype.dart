import 'package:equatable/equatable.dart';

/// A UML-style stereotype annotation on a workflow element, written as
/// `<<key="value">>` in `.wfm` source.
///
/// Stereotypes in the Workflow DSL serve two primary purposes:
///
/// 1. **Conformance mapping** — the `incarnates` stereotype declares that a
///    task in a concrete process model corresponds to a task in a reference
///    model.  Example: `<<incarnates="Research">> task LiteratureReview;`
///    signals that `LiteratureReview` *incarnates* (i.e. is a specific
///    realisation of) the abstract `Research` task defined in the reference
///    process.
///
/// 2. **Access modifiers** — the Workflow DSL inherits UML modifier support.
///    Stereotypes may carry visibility or other classifier properties.
///
/// Stereotypes are always attached to the [WfModifier] of a flow element.
///
/// Usage:
/// ```dart
/// final s = Stereotype(key: 'incarnates', value: 'Research');
/// print(s); // <<incarnates="Research">>
/// ```
class Stereotype with EquatableMixin {
  /// The stereotype key (e.g. `incarnates`).
  final String key;

  /// The stereotype value (e.g. `Research`).  May be null when the
  /// stereotype is a marker without a value.
  final String? value;

  const Stereotype({required this.key, this.value});

  /// Convenience constructor for the `incarnates` conformance stereotype.
  factory Stereotype.incarnates(String referenceName) =>
      Stereotype(key: 'incarnates', value: referenceName);

  @override
  List<Object?> get props => [key, value];

  @override
  String toString() => value != null ? '<<$key="$value">>' : '<<$key>>';
}

/// The visibility/access modifier of a workflow element.
///
/// Inherited from UML modifier syntax.  Most `.wfm` elements carry no
/// explicit modifier (defaulting to [WfVisibility.unspecified]), but
/// processes or tasks may be restricted in tool-specific extensions.
enum WfVisibility {
  /// No explicit modifier was written — default visibility in the DSL.
  unspecified,

  /// The element is publicly visible (`public` keyword or `+` in UML).
  public,

  /// The element is private (`private` keyword or `-` in UML).
  private,

  /// The element is protected (`protected` keyword or `#` in UML).
  protected,
}

/// The combined modifier on a workflow element, holding optional visibility
/// and any number of stereotype annotations.
///
/// In the Workflow grammar, `Modifier` wraps the `UMLModifier` from MontiCore,
/// allowing elements to carry both access visibility and stereotype tags.
///
/// Usage:
/// ```dart
/// final modifier = WfModifier(
///   visibility: WfVisibility.unspecified,
///   stereotypes: [Stereotype.incarnates('Research')],
/// );
/// ```
class WfModifier with EquatableMixin {
  final WfVisibility visibility;
  final List<Stereotype> stereotypes;

  const WfModifier({
    this.visibility = WfVisibility.unspecified,
    this.stereotypes = const [],
  });

  /// A modifier with no stereotypes and no explicit visibility.
  static const WfModifier none = WfModifier();

  /// Whether this modifier carries an `incarnates` stereotype.
  bool get isIncarnation => stereotypes.any((s) => s.key == 'incarnates');

  /// Returns the value of the first `incarnates` stereotype, or `null`.
  String? get incarnatesTarget => stereotypes
      .where((s) => s.key == 'incarnates')
      .map((s) => s.value)
      .firstOrNull;

  @override
  List<Object?> get props => [visibility, stereotypes];

  @override
  String toString() {
    final parts = <String>[
      if (visibility != WfVisibility.unspecified) visibility.name,
      ...stereotypes.map((s) => s.toString()),
    ];
    return parts.join(' ');
  }
}
