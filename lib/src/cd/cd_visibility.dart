/// The UML visibility (access modifier) of a class-diagram element.
///
/// MontiCore's CD4Analysis grammar inherits Java-style access modifiers.
/// The four levels map directly to Java and UML visibility:
///
/// | [CdVisibility] | Java keyword | UML symbol | Accessible from            |
/// |----------------|-------------|------------|----------------------------|
/// | [public]       | `public`    | `+`        | Anywhere                   |
/// | [protected]    | `protected` | `#`        | Package + subclasses       |
/// | [packageLocal] | (none)      | `~`        | Same package only          |
/// | [private]      | `private`   | `-`        | Enclosing class only       |
///
/// When serialised to a `.cd` source file, `public` is written explicitly
/// (e.g. `public class Order { … }`), while `packageLocal` has no keyword.
enum CdVisibility {
  /// `public` — visible everywhere.
  public,

  /// `protected` — visible within the package and subclasses.
  protected,

  /// Package-local (default) — no keyword, visible only within the package.
  packageLocal,

  /// `private` — visible only within the declaring class.
  private,
}
