# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-12-22

Added some new features for interacting with the `test` operation, and for interacting with several patches in a row. These aren't compliant with spec, but are backwards compatible so it's fine.

### Added
- Added the ability to test that a key exists by omitting `value` from the `test` operation.
    - This lets you test that a key exists, regardless of what the value is.
- Added the ability to invert a test by providing `"inverse": true` in the `test` operation.
    - For example, you can test that a key does NOT exist, and then follow up with an operation that sets it.
- Added the ability to provide a batch of JSONPatches to evaluate one at a time, gracefully skipping the patches containing a failed operation.
    - As an example, you can provide a list of two patches, one that initializes a value that may not exist, and another that modifies that value if it does exist. If the first patch fails, the second patch will still be applied.

## [1.0.0] - 2024-07-19

Initial release.

