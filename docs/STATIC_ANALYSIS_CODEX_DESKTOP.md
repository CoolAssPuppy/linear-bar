# Static Analysis Runbook (Codex Desktop Handoff)

This document is a deterministic checklist for running deeper static analysis on a **macOS desktop with Xcode installed**. It is optimized for Codex/Desktop takeover and assumes the repo root is the current working directory.

## Goals

1. Catch Swift/macOS correctness issues that Linux CI cannot compile.
2. Catch security anti-patterns (unsafe URL handling, token leaks, weak auth flows, shell injection).
3. Catch dead code and dependency risk.
4. Produce a triaged issue list with severity and concrete fixes.

---

## 0) Environment prerequisites

```bash
xcodebuild -version
swift --version
brew --version
```

Install baseline tools:

```bash
brew install xcodegen swiftlint periphery semgrep gitleaks osv-scanner
```

---

## 1) Generate project and run baseline build/tests

```bash
xcodegen generate
xcodebuild -scheme LinearBar -configuration Debug -destination 'platform=macOS' build
xcodebuild -scheme LinearBar -configuration Debug -destination 'platform=macOS' test
```

If signing blocks local builds, disable signing for local analysis-only runs:

```bash
xcodebuild -scheme LinearBar -configuration Debug -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

---

## 2) Xcode static analyzer (Clang + Swift diagnostics)

```bash
xcodebuild -scheme LinearBar -configuration Debug -destination 'platform=macOS' analyze
```

Focus findings on:
- Retain cycles and capture semantics in closures/Tasks.
- Potential nil unwraps and force-casts.
- Threading violations around `@MainActor` boundaries.

---

## 3) Style + correctness linting

```bash
swiftlint lint --strict
```

Recommended `.swiftlint.yml` additions (if absent):
- `force_unwrapping`
- `todo`
- `empty_count`
- `weak_delegate`
- `cyclomatic_complexity`
- `function_body_length`

---

## 4) Dead code and unused symbol scan

```bash
periphery scan --project LinearBar.xcodeproj --scheme LinearBar --targets LinearBar --format xcode
```

Triage rule: only remove symbols after confirming they are not used by reflection, SwiftUI previews, runtime selectors, or test-only entry points.

---

## 5) Security-focused SAST

### Semgrep (Swift + secrets + dangerous patterns)
```bash
semgrep scan --config auto --error
```

### Secret scanning
```bash
gitleaks detect --source . --verbose
```

### Vulnerable dependency scan
```bash
osv-scanner --lockfile=Package.resolved
```

---

## 6) Manual targeted checks for macOS menu bar apps

Run these quick grep-based audits:

```bash
rg "NSWorkspace\\.shared\\.open\\(" Source -n
rg "URL\\(string:" Source -n
rg "SecRandomCopyBytes|state|oauth" Source -n
rg "print\\(|debugPrint\\(|os_log|AppLogger\\." Source -n
rg "Task\\s*\\{" Source -n
```

Checklist:
- All externally sourced URLs pass centralized validation.
- OAuth/token paths never log raw access/refresh tokens.
- Background `Task` usage checks cancellation where appropriate.
- Any `Retry-After` / 429 handling has capped waits and bounded retries.

---

## 7) Reporting format for Codex handoff

Create `docs/STATIC_ANALYSIS_REPORT.md` with:

1. **Tooling matrix** (tool, version, command, pass/fail).
2. **Findings table**:
   - ID
   - Severity (`critical/high/medium/low`)
   - File + line
   - Repro command
   - Recommended fix
3. **Fix plan** grouped by:
   - Security
   - Correctness
   - Performance
   - Maintainability
4. **Regression-risk notes** for each proposed change.

---

## 8) Exit criteria

A run is considered complete when:

- `build`, `test`, and `analyze` all run on macOS.
- `swiftlint` and `semgrep` are clean or findings are documented and triaged.
- Secret scan has no unapproved findings.
- Dependency scanner findings (if any) have mitigation plan + owner.
