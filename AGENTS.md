# AGENTS.md

## Project Overview
This repository is for the Dart package **`wizlight`**.
It provides a comprehensive interface for controlling WiZ smart light bulbs over UDP using the WiZ protocol. This is a Dart port of the wizlightcpp C++ implementation, supporting device discovery, color control, brightness adjustment, scenes, and device management.

Key points:
- Programming language: Dart 
- Package structure:
  - `lib/` — main public API  
  - `example/` — usage examples  
  - `test/` — unit & integration tests  
  - `tool/` — helper scripts (if any)  
- This file (`AGENTS.md`) is meant to guide AI-based coding agents and humans alike.  
  It complements `README.md` (which is aimed primarily at human users/contributors).

---

## Setup Commands
```bash
# Activate Dart SDK
dart --version

# Fetch dependencies
dart pub get

# Run the example (if applicable)
dart run example/main.dart

# Run tests
dart test

# (Optional) Format code
dart format .

# (Optional) Analyze code for issues
dart analyze
```

---

## Build & Publish
```bash
# Build the package (if relevant, e.g., for Flutter or platform-specific)
dart compile <executable> --output=...

# Publish to pub.dev
dart pub publish --dry-run
dart pub publish
```

> **Note**: Ensure version updates in `pubspec.yaml`, update `CHANGELOG.md`, and tag the release in Git.

---

## Code Style & Conventions
- Follow the official Dart style guide: https://dart.dev/guides/language/effective-dart/style  
- Use **two spaces** for indentation (Dart default)  
- Prefer `final` and `const` where possible  
- Public API should be documented with Dartdoc comments: `///`  
- Private members start with an underscore `_`  
- Avoid using `dynamic` unless absolutely necessary  
- Use null-safety (`--null-safety` enforced)  
- Organize imports:
  1. Dart SDK imports  
  2. Third-party package imports  
  3. Local package imports  
  Each group separated by a blank line.  
- Line length: aim for ≤ 80-100 characters for readability, but up to 120 acceptable for long doc comments or URLs.

---

## Testing Instructions
- All new features must include one or more tests in `test/`  
- Use descriptive test names and clearly arrange `arrange` / `act` / `assert` pattern  
- For widget or UI tests (if this is a Flutter package), ensure you use `flutter_test` and mock external dependencies  
- Before merging a pull request (PR), ensure:
  ```bash
  dart format --set-exit-if-changed .
  dart analyze
  dart test
  ```
- If you add new dependencies, update `pubspec.yaml` and run `dart pub get` in CI.

---

## Pull Request (PR) Guidelines
- Title format: `<component>: <short description>` or `bugfix(<component>): <short description>`  
- PR description should contain:
  - Summary of change  
  - Motivation / context  
  - How to test the change  
- Link to any relevant issue(s) or discussion(s)  
- When ready, mark the PR as ready for review and assign relevant reviewers  
- After approval, merge via “Squash & merge” (unless otherwise directed)  
- Post-merge: create a new release tag (`vX.Y.Z`) and update `CHANGELOG.md`

---

## Versioning & CHANGELOG
- Use [Semantic Versioning](https://semver.org): `MAJOR.MINOR.PATCH`  
- Update `CHANGELOG.md` for each version change under appropriate sections: Added, Changed, Fixed, Removed  
- Tag the release in Git:  
  ```bash
  git tag -a vX.Y.Z -m "Release version X.Y.Z"
  git push origin vX.Y.Z
  ```

---

## Security & Compliance
- Avoid committing secrets (API keys, credentials) in the repository  
- Use `gitignore` for local settings, build artefacts, and analysis caches  
- Renew any keys/certificates when they expire  
- For dependencies: review license compliance and check for vulnerabilities (e.g., `dart pub outdated --severity=high`)  
- If your package interacts with platform channels (Flutter) or native code, validate memory safety and concurrency issues

---

## Agent & Automation Tips
- Place this `AGENTS.md` at the root—agents will pick it up automatically.  
- Agents should avoid modifying files outside of the package directories without explicit instruction.  
- Ensure agents run the setup commands first, and then apply changes (formatting, tests, code) so they respect project conventions.  
- If the package becomes part of a mono-repo, consider adding nested `AGENTS.md` in sub-packages for more granular guidance.

---

## FAQ
**Q: Are there required fields in `AGENTS.md`?**  
A: No. It’s just Markdown. Use any headings and content that help agents and contributors.  [oai_citation:0‡agents.md](https://agents.md/)  

**Q: What if instructions conflict?**  
A: The closest `AGENTS.md` (in the directory tree) takes precedence. Also human instruction overrides automated instructions.  [oai_citation:1‡agents.md](https://agents.md/)  

**Q: Can we update `AGENTS.md` later?**  
A: Yes — treat it as living documentation.  [oai_citation:2‡agents.md](https://agents.md/)  

---

## Change History of this File
- **v0.1.0** — Initial draft based on generic Dart package template  
- … (future updates to be listed here)  