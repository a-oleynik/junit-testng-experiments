# AGENTS.md

Guidance for AI coding agents working in this repository.

## What this repository is

A reproducible experiment comparing failure semantics of `@BeforeSuite` /
`@AfterSuite` (and `@BeforeClass` in JUnit 4) across four independent Maven
projects: `junit-6.1.3/`, `junit-5.14.4/`, `junit-4.13.2/`, `testng-7.12.0/`.
There is **no aggregator `pom.xml`** — each project is self-contained and
built/run separately.

10 of 11 scenarios are **intentionally designed to fail** (Maven exits 1).
This is expected behavior, not a bug. Do not "fix" a failing scenario unless
asked — verify it against `verify.ps1`'s expectations instead.

## Key files

- `verify.ps1` — runs all 11 scenarios via `mvn test -Dscenario=<Name>`,
  captures `[EVENT]` log lines and Surefire XML reports, and asserts exit
  code, event order, and failure type/message match expectations hardcoded
  in its `$scenarios` array.
- `tests/verify-script.tests.ps1` — unit-tests `Test-ScenarioResult` from
  `verify.ps1` using synthetic fixtures (dot-sources the script; does not
  invoke Maven).
- `README.md` — written in Russian; holds experiment context, per-project
  scenario tables, and expected results. Keep it in sync with any scenario
  changes.

## Making changes

- If you add/rename/change the expected outcome of a scenario, update the
  matching entry in `$scenarios` in `verify.ps1` **and** the corresponding
  table/text in `README.md`.
- Scenario identity is `Project` + `Name` (the JUnit/TestNG class name),
  passed to Maven as `-Dscenario=<Name>`.
- Each scenario asserts: Maven exit code, exact `[EVENT]`/`[EVENTS]` log
  line sequence (case-sensitive), presence of Surefire XML reports, and
  (for failing scenarios) exactly one `<error>`/`<failure>` with the
  expected `type` and `message`.
- Don't add a shared parent `pom.xml`; the separation between projects is
  intentional so failing scenarios don't affect the others' builds.

## Validating changes

Requires PowerShell 7.2+ and Maven (`mvn`) on PATH.

```powershell
pwsh ./verify.ps1
```

Exits 0 only if all 11 scenarios match expectations (including expected
failures). Per-run logs and a `summary.json` are written under
`target/verification/<guid>/`.

To test `verify.ps1` itself (no Maven invocation, fast):

```powershell
pwsh ./tests/verify-script.tests.ps1
```

Run both after any change to `verify.ps1`, a scenario's test source, or a
`pom.xml`.
