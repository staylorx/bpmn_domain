# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `.github/workflows/ci.yml` — CI runs on every push to `main` and on each PR,
  pinned to the Dart 3.13.1 SDK (matching the raised `environment.sdk` floor and
  the resolved lockfile). Gate: `dart pub get` → `dart analyze
  --fatal-infos --fatal-warnings` → `dart format` (set-exit-if-changed) →
  `dart test`. Previously `.github/` did not exist, so nothing ran analyze/test
  on push or PR.
- `pubspec.lock` — now tracked (unchanged content) for reproducible CI, and
  `.gitignore` no longer excludes it. This package is `publish_to: none`, so
  committing the lock never leaks a publish-time constraint.
- `BACKLOG.md` — open/pending items only. Records the Windows-lane build/audit
  findings (Dart SDK 3.13.1) and every divergence between this repo and the
  Dart/Flutter Bible (`staylorx/dart-flutter-bible`, `docs/` §1–§12), each as a
  `Deviation:` item flagged for review rather than auto-fixed.

### Changed

- `pubspec.yaml` — raised `environment.sdk` floor from `>=3.0.0` to `>=3.13.1`
  (`<4.0.0` upper bound unchanged). The 3.0.0 floor was untested: every green
  gate ran on the locally exercised Dart 3.13.1, and the resolved lockfile
  already legislates `>=3.9.0`. Verified on 3.13.1 after the change: `dart pub
  get` clean, `dart analyze` no issues, `dart test` 124/124 passed. (Formerly a
  `BACKLOG.md` SDK-deviation item, now removed from there.)
- `CHANGELOG.md` reformatted to Keep a Changelog: added the file preamble, the
  `[Unreleased]` section, and `Added`/`Changed`/`Fixed`/`Notes` headings.
- `CHANGELOG.md`: the release heading was **corrected from `1.0.0` to `0.1.0`**
  to match `version:` in `pubspec.yaml`. `dart pub publish --dry-run` flagged the
  mismatch ("CHANGELOG.md doesn't mention current version (0.1.0)"); the package
  version is the source of truth, so the changelog follows it. No entry content
  other than the heading was changed.

### Fixed

- Nothing yet.

### Notes

- Gates run fresh on `main` @ `c44dbff` for this audit: `dart pub get` OK;
  `dart format . --set-exit-if-changed` 28 files, 0 changed; `dart test` 124
  passed, 0 failed; `dart pub publish --dry-run` 1 warning (fixed above);
  `dart analyze --fatal-infos` **RED — 61 × `deprecated_member_use`**
  (`EquatableMixin`), tracked in `BACKLOG.md`. No source code changed in this
  pass.

## [0.1.0] - 2026-02-23

### Added

- Initial version: clean-architecture domain model for the MontiCore BPMN
  Workflow DSL (`.wfm`) and CD4Analysis class diagrams (`.cd`) — immutable,
  equatable entities, value objects, class-diagram model, and a sealed
  `WorkflowFailure` hierarchy for the CoCo conformance constructs.
