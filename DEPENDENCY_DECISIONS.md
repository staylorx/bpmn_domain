# Dependency Update Decisions

Source: `dart pub outdated` report captured 2026-10-11 (see `pub_outdated_report.txt` / `pub_outdated_report.full.txt`), SDK 3.13.1. 22 packages reported stale.

Decision categories:
- (a) Update a direct dependency constraint to allow a compatible newer version.
- (b) Bump the (transitive) dependency to a compatible version — here via the direct dependency that pulls it in / a plain `dart pub upgrade`, because the constraint already resolves the latest.
- (c) Leave as-is, with rationale (breaking changes, maintenance status, compatibility).

## Summary

- 21 of the 22 stale packages already resolve at their latest version under the current `pubspec.yaml` constraints — a plain `dart pub upgrade` bumps them all. No constraint edits required.
- 1 package (`equatable`) is constraint-blocked (`^2.0.7` vs latest `3.0.0`) AND its 3.0.0 release is breaking for this codebase. Decision: leave on 2.x.

## Decision table

| Package | Kind | Current | Latest | Action | Rationale |
|---|---|---|---|---|---|
| equatable | direct | 2.0.8 | 3.0.0 | (c) leave as-is | 3.0.0 is **breaking**: removes `EquatableMixin`, stops testing `runtimeType` in object comparison, and drops the custom `toString` override. This codebase uses `with EquatableMixin` in **61** places (all entity / value-object / failure classes). Migrating to 3.x means replacing every `with EquatableMixin` with `extends Equatable` (or dropping mixin equality), changing `toString`/`runtimeType` semantics — a separate, deliberate migration task, not an incidental bump. Optionally loosen to `^2.1.0` later (2.1.0 only deprecates the mixin, still ships it); not required. |
| test | dev | 1.29.0 | 1.33.0 | (b) bump | Constraint `^1.25.6` already resolves 1.33.0. No change needed; bump via `dart pub upgrade`. |
| mocktail | dev | 1.0.4 | 1.0.5 | (b) bump | Constraint `^1.0.4` already resolves 1.0.5. No change needed; bump via `dart pub upgrade`. |
| meta | transitive | 1.18.1 | 1.19.0 | (b) bump | Pulled in transitively (via equatable/test). Resolves at latest already; bump via `dart pub upgrade`. |
| analyzer | transitive dev | 10.2.0 | 14.5.0 | (b) bump | Test toolchain internals; brought in by `test`/`lints`. Resolves at latest; bump via `dart pub upgrade`. |
| _fe_analyzer_shared | transitive dev | 96.0.0 | 109.0.0 | (b) bump | Test toolchain internals (analyzer dep). Bump via upgrade. |
| async | transitive dev | 2.13.0 | 2.13.1 | (b) bump | Test toolchain dependency. Patch bump, safe. |
| coverage | transitive dev | 1.15.0 | 1.15.1 | (b) bump | Test toolchain dependency. Patch bump, safe. |
| frontend_server_client | transitive dev | 4.0.0 | 4.1.0 | (b) bump | Test toolchain dependency. Minor bump, safe. |
| glob | transitive dev | 2.1.3 | 2.2.0 | (b) bump | Test toolchain dependency. Minor bump, safe. |
| io | transitive dev | 1.0.5 | 1.1.0 | (b) bump | Test toolchain dependency. Minor bump, safe. |
| matcher | transitive dev | 0.12.18 | 0.12.20 | (b) bump | Brought in by `test`. Patch bump, safe. |
| mime | transitive dev | 2.0.0 | 2.1.0 | (b) bump | Test toolchain dependency. Minor bump, safe. |
| package_config | transitive dev | 2.2.0 | 3.0.0 | (b) bump | Test toolchain dependency. Major per its own versioning but fully compatible within the test toolchain resolution; resolves at latest. |
| pool | transitive dev | 1.5.2 | 1.5.3 | (b) bump | Test toolchain dependency. Patch bump, safe. |
| pub_semver | transitive dev | 2.2.0 | 2.2.1 | (b) bump | Test toolchain dependency. Patch bump, safe. |
| source_maps | transitive dev | 0.10.13 | 0.10.14 | (b) bump | Test toolchain dependency. Patch bump, safe. |
| stack_trace | transitive dev | 1.12.1 | 1.12.2 | (b) bump | Test toolchain dependency. Patch bump, safe. |
| test_api | transitive dev | 0.7.9 | 0.7.15 | (b) bump | Brought in by `test`. Bump alongside `test` via upgrade. |
| test_core | transitive dev | 0.6.15 | 0.6.21 | (b) bump | Brought in by `test`. Bump alongside `test` via upgrade. |
| vm_service | transitive dev | 15.0.2 | 15.3.0 | (b) bump | Test toolchain dependency. Minor bump, safe. |
| yaml | transitive dev | 3.1.3 | 3.1.4 | (b) bump | Test toolchain dependency. Patch bump, safe. |

## Focus packages not in the stale list

| Package | Locked version | Constraint | Note |
|---|---|---|---|
| fpdart | 1.2.0 | ^1.2.0 | Current == latest; not stale. |
| lints | 6.1.0 | ^6.0.0 | Current == latest; not stale. |
| shouldly | 0.5.0+1 | ^0.5.0+1 | Current == latest; not stale. |

## Recommended execution

- `dart pub upgrade` bumps all 21 non-equtable packages to their latest (no constraint edits).
- Leave `equatable` pinned at `^2.0.7` (resolves 2.0.8). Plan a separate, explicit migration to `equatable` 3.x when convenient.
