# Contributing

Thanks for helping improve You Cannot Sleep. Keep changes focused, native to macOS, and free of third-party runtime dependencies.

## Development

- Open `YouCannotSleep.xcodeproj` in Xcode 15 or newer.
- Regenerate the project after editing `project.yml` with `xcodegen generate`.
- Build and run the `YouCannotSleep` scheme on macOS 13 or newer.
- Add unit coverage for core behavior using the injected clock and fake power assertion service.
- Update `docs/QA.md` when user-visible behavior changes.

Before opening a pull request, run `xcodebuild test -project YouCannotSleep.xcodeproj -scheme YouCannotSleep -destination 'platform=macOS'` and describe any manual checks you performed.

## Pull requests

Explain the user impact, implementation, and validation. Avoid bundling unrelated refactors. Do not include credentials, private logs, or unrelated user data.

## Reporting issues

Use the GitHub issue tracker for reproducible bugs and feature requests. Include the macOS version and relevant steps; remove personal information from diagnostic output.
