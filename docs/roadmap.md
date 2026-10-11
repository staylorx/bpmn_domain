# Roadmap

Planned layering for `bpmn_domain`. None of these layers is implemented yet: they are target
shapes that the parser, validator, and conformance-checker layers will take, and the
`Either<WorkflowFailure, T>` call signatures below describe the intended (unimplemented)
public surface.

## Proposed layers

1. **`.wfm` parser (next)** — parse a raw `.wfm` string into a `WorkflowCompilationUnit` using `petitparser`. Key grammar constructs, in order of complexity:

   1. Package declaration and imports
   2. Process header and modifier / stereotype
   3. Data objects (`data`, `store`), notifications, operations
   4. Lanes
   5. Tasks (all 8 types) with boundary events and I/O
   6. Events (start, end, intermediate, boundary) with all trigger types
   7. Named gateways (all 6 kinds, both directions)
   8. Sequence flows: linear chains, conditional blocks `{ [cond] A -> B; }`, inline gateways
   9. Subprocesses (embedded, transaction, adhoc, event)
   10. Call activities
   11. Loop characteristics (`count [n] parallel`, standard loop)
   12. Timer conditions (5 variants)

   Entry point (planned): `WorkflowParser.parse(String source)` → `Either<ParseFailure, WorkflowCompilationUnit>`.

2. **`.cd` parser** — parse a raw `.cd` string into a `CdCompilationUnit`. Constructs: package, classdiagram header, class/interface/enum declarations, attributes (with `/` derived prefix), methods, associations with multiplicity and role names.

   Entry point (planned): `ClassDiagramParser.parse(String source)` → `Either<ParseFailure, CdCompilationUnit>`.

3. **Symbol resolution** — walk a `WorkflowCompilationUnit` and resolve all `WfTypeRef` names (in data objects, operation parameters, notification declarations) against the `CdClassifier`s imported from class diagram symbol tables. Produces an enriched compilation unit or a list of `UnresolvedTypeReference` failures.

4. **CoCo validator** — check a `WfProcess` against all the `WorkflowFailure` types. Returns `Either<List<WorkflowFailure>, WfProcess>`. Each failure class corresponds to one or more MontiCore context conditions; structure the validator as individual CoCo checkers that can run independently.

5. **Conformance checker** — given a concrete `WfProcess` and a reference `WfProcess`, check that every activity carries an `<<incarnates="X">>` stereotype, that the incarnated name exists in the reference model, and that the gateway structure violates no conformance rules. Returns `Either<List<WorkflowFailure>, ConformanceReport>`.
