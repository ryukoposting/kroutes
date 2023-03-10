# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog], and adheres to Nimble's versioning semantics.

The [master] branch always matches the latest release. The [devel] branch always contains the latest unreleased code.

## [Unreleased] - 2023-02-19

## [0.2.0] - 2023-02-19

### Added

- Server-side implementations of `goBack`, `goForward`, and `goTo` in `kroutes/kroutes_static`

### Changed

- Replace `goBack`, `goForward`, and `goTo` closures with simple procs

## [0.1.2] - 2023-02-18

### Added

- This changelog!
- Router paths now support wildcards using `*`.

### Changed

- `addRoute` and `addSsrRoute` now perform more strict validation of routing paths. A `ValueError` will be raised when a router path is invalid.

## [0.1.1] - 2023-02-18

- Initial stable release

<!-- Links -->
[keep a changelog]: https://keepachangelog.com/en/1.0.0/

<!-- Versions -->
[unreleased]: https://github.com/ryukoposting/kroutes/compare/master...devel
[master]: https://github.com/ryukoposting/kroutes/tree/master
[devel]: https://github.com/ryukoposting/kroutes/tree/devel
[0.1.1]: https://github.com/ryukoposting/kroutes/releases/tag/0.1.1
[0.1.2]: https://github.com/ryukoposting/kroutes/releases/tag/0.1.2
[0.2.0]: https://github.com/ryukoposting/kroutes/releases/tag/0.2.0
