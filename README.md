# Failure semantics for `@BeforeSuite` and `@AfterSuite`

This reproducible experiment checks what happens on failures in
`@BeforeSuite`, in the test itself, and in `@AfterSuite`, as well as on a
`@BeforeClass` failure in JUnit 4. It is kept separate from the Workshop
projects so that the intentionally failing scenarios don't affect their
normal runs.

> **Important:** 10 of 11 scenarios intentionally make Maven exit with an
> error. This is an expected part of the examples. The overall
> `verify.ps1` script succeeds only when all 11 scenarios match
> expectations, including the expected failures.

> A Russian version of this document is available in
> [`README_RU.md`](README_RU.md).

<a id="contents"></a>

## Contents

- [Experiment context](#experiment-context)
- [Requirements and overall verification](#verification)
- [JUnit 6.1.3](#junit-6)
- [JUnit 5.14.4](#junit-5)
- [JUnit 4.13.2](#junit-4)
- [TestNG 7.12.0](#testng)
- [Scope of the findings](#scope)
- [Re-verification on October 26, 2026](#verification-2026-10-26)
- [License](#license)

<a id="experiment-context"></a>

## Experiment context

The experiment was prepared for an article, "BeforeSuite and AfterSuite in
JUnit 5/6: has JUnit caught up with TestNG?". The article is being
prepared for publication; a public link will be added once it is out.
While comparing the lifecycles, a practical question came up: if
environment setup throws an exception, do tests start running, and is the
teardown hook responsible for releasing resources still called?

To answer this, separate Maven projects are used for JUnit 6, JUnit 5,
JUnit 4, and TestNG. JUnit 6 and 5 are verified separately; for TestNG, a
plain `@AfterSuite` is compared against `@AfterSuite(alwaysRun = true)`;
for JUnit 4, `@BeforeClass` / `@AfterClass` of a regular class is compared
against that of a suite class. Additional JUnit 6 and TestNG scenarios
show failures in the test itself and in the teardown hook.

The examples are intentionally minimal: instead of an external server or a
database, they print `[EVENT]` events. This lets you separate the fact
that a hook was called from the correctness of cleaning up a real,
possibly partially created, resource. Calling the teardown hook by itself
does not prove that all resources were released.

This README holds the purpose of the experiment, the commands to
reproduce it, and the expected results. The observations apply to the
stated versions and the way the examples are run; when dependencies are
updated, the corresponding scenarios should be re-verified. The experiment
does not modify the Workshop projects.

The [`junit-4.13.2/`](#junit-4) project also keeps a check of
`@ClassRule(order = ...)`. It is run with a separate command and is
expected to succeed. The sources for the order check and for the failure
handling share a single `pom.xml`.

The repository contains four independent Maven projects, with no common
aggregating `pom.xml`:

| Project                                    | What it contains                                                                               |
|---------------------------------------------|-------------------------------------------------------------------------------------------------|
| [`junit-6.1.3/`](junit-6.1.3/pom.xml)       | Three scenarios: suite setup failure, test failure, and teardown hook failure                  |
| [`junit-5.14.4/`](junit-5.14.4/pom.xml)     | One scenario: suite setup failure                                                              |
| [`junit-4.13.2/`](junit-4.13.2/pom.xml)     | Two setup-failure scenarios and one Rules ordering check                                       |
| [`testng-7.12.0/`](testng-7.12.0/pom.xml)   | Four scenarios: setup failure with and without `alwaysRun`, test failure, and teardown failure  |

<a id="verification"></a>

## Requirements and overall verification

The examples require JDK 17 or newer (`pom.xml` sets `release=17`) and
Maven 3.9.x. The overall script requires PowerShell 7.2 or newer (`pwsh`);
individual Maven commands can be run without it. `java` and `mvn` must be
available on `PATH`, and Maven must use the correct JDK. The first run
needs access to Maven Central or a configured mirror to download
dependencies and plugins.

Verified environment and dependency versions:

- JDK 21.0.10;
- Maven 3.9.12;
- Maven Surefire 3.6.0;
- JUnit 6.1.3;
- JUnit 5.14.4 / JUnit Platform 1.14.4;
- JUnit 4.13.2;
- TestNG 7.12.0.

Check the local environment and run all scenarios from the root of this
project:

```powershell
java -version
mvn -version
pwsh -NoProfile -File ./verify.ps1
```

[`verify.ps1`](verify.ps1) runs 11 scenarios sequentially and checks:

- the exact Maven exit code: 1 for an intentional failure, 0 for
  `ClassRuleOrderTest`;
- the exact sequence of `[EVENT]` / `[EVENTS]` lines, including the
  absence of an extraneous test run;
- the presence of Surefire XML reports and test case entries;
- exactly one expected failure with the given type and message for a
  failing scenario, or no failures for a successful one.

A compilation error, a dependency download error, missing reports, an
unexpected failure, or a mismatch in events all result in a failed
verification. The script's final exit code is `0` when all expectations
are met, and `1` when there is a mismatch or the run itself failed.

Every run of the script gets a new directory
`target/verification/<run-id>/`. It stores `summary.json`, and for every
project and scenario a `maven.log` plus the XML reports under `reports/`.
Previous reports are not used, and files from earlier runs are not
deleted. The script computes paths relative to its own location.

Self-test of the script's logic (without running Maven):

```powershell
pwsh -NoProfile -File ./tests/verify-script.tests.ps1
```

These checks use synthetic reports to verify that the script distinguishes
an expected failure from an unexpected success, a wrong event sequence, a
different exception, an extra failure, and a missing or corrupted report.

For each command block, first go back to the
`failure-semantics-experiment/` directory: the `cd` at the start of each
block is relative to it. Run the scenarios individually, passing the class
name via `-Dscenario=...`; a plain `mvn test` without selecting a scenario
is not a command for running all examples.

Failure scenarios are expected to exit with a non-zero code: the failure
is part of the scenario. The event sequence is visible in lines prefixed
with `[EVENT]`. The exception is the successful `ClassRuleOrderTest`
check, which prints `[EVENTS]`.

<a id="junit-6"></a>

## JUnit 6.1.3

The project uses Jupiter and the Suite API/Engine version 6.1.3. Each
suite class selects its own nested `SelectedCase` via `@SelectClasses`:

- [`BeforeFailsSuite`](junit-6.1.3/src/test/java/com/example/junit6/BeforeFailsSuite.java) –
  `@BeforeSuite` throws; the test does not run, `@AfterSuite` is called.
- [`TestFailsSuite`](junit-6.1.3/src/test/java/com/example/junit6/TestFailsSuite.java) –
  setup succeeds, the test calls `fail(...)`, `@AfterSuite` runs afterward.
- [`AfterFailsSuite`](junit-6.1.3/src/test/java/com/example/junit6/AfterFailsSuite.java) –
  setup and the test succeed, `@AfterSuite` throws.

```powershell
cd junit-6.1.3
mvn -Dscenario=BeforeFailsSuite test
mvn -Dscenario=TestFailsSuite test
mvn -Dscenario=AfterFailsSuite test
```

Expected event sequences:

| Scenario                | Events                                              |
|--------------------------|------------------------------------------------------|
| `@BeforeSuite` failure   | `beforeSuite`, `afterSuite`; the test does not run   |
| Test failure             | `beforeSuite`, `test`, `afterSuite`                  |
| `@AfterSuite` failure    | `beforeSuite`, `test`, `afterSuite`                  |

In all three cases, the run ends with an error.

<a id="junit-5"></a>

## JUnit 5.14.4

The project uses Jupiter 5.14.4 and the Suite API/Engine from Platform
1.14.4.
[`BeforeFailsSuite`](junit-5.14.4/src/test/java/com/example/junit5/BeforeFailsSuite.java)
selects a nested `SelectedCase`, but throws in `@BeforeSuite` before it
runs. This example lets you compare the setup failure separately against
JUnit 6. This project has no scenarios for a failure in the test itself or
in `@AfterSuite`.

```powershell
cd junit-5.14.4
mvn -Dscenario=BeforeFailsSuite test
```

Expected events:

```text
[EVENT] beforeSuite
[EVENT] afterSuite
```

The test does not run, `@AfterSuite` is called, and the run still ends
with an error.

<a id="junit-4"></a>

## JUnit 4.13.2

The single [`junit-4.13.2/`](junit-4.13.2/pom.xml) project contains three
runnable scenarios. Two of them check a setup failure:

- [`BeforeClassFailsScenario`](junit-4.13.2/src/test/java/com/example/junit4/BeforeClassFailsScenario.java) –
  an exception from `@BeforeClass` of a regular test class;
- [`BeforeClassFailsSuite`](junit-4.13.2/src/test/java/com/example/junit4/BeforeClassFailsSuite.java) –
  an exception from `@BeforeClass` of a suite with `@RunWith(Suite.class)`.

```powershell
cd junit-4.13.2
mvn -Dscenario=BeforeClassFailsScenario test
mvn -Dscenario=BeforeClassFailsSuite test
```

| Scenario       | Events                                   | Outcome                                                          |
|----------------|--------------------------------------------|--------------------------------------------------------------------|
| Regular class  | `beforeClass`, `afterClass`                | The test does not run, `@AfterClass` is called                     |
| Suite class    | `suite.beforeClass`, `suite.afterClass`    | The selected class does not run, the suite's `@AfterClass` is called |

In the second scenario, the `selected.beforeClass` and
`selected.afterClass` events are also absent: the selected class's
lifecycle never starts. Both commands exit with the `@BeforeClass`
failure.

This behavior matches
[AfterClass (JUnit 4.13.2 API)](https://junit.org/junit4/javadoc/4.13.2/org/junit/AfterClass.html):
the documentation explicitly guarantees that `@AfterClass` is called even
when `@BeforeClass` throws.

The third scenario is
[`ClassRuleOrderTest`](junit-4.13.2/src/test/java/com/example/junit4/ClassRuleOrderTest.java).
It programmatically runs the helper suite
[`OrderedClassRulesSuite`](junit-4.13.2/src/test/java/com/example/junit4/OrderedClassRulesSuite.java)
via `JUnitCore` and asserts both that the run succeeded and the exact
order of events of two `@ClassRule`s: an outer one with `order = 0` and an
inner one with `order = 1`. So the project has four Java files: three
runnable scenarios and one helper suite.

From the `junit-4.13.2/` folder:

```powershell
mvn -q -Dscenario=ClassRuleOrderTest test
```

Expected output:

```text
[EVENTS] [outer.before, inner.before, test, inner.after, outer.after]
```

This command succeeds (exit code 0). JUnit 4.13.2 applies separately
annotated class rules according to their declared nesting: a larger
`order` value corresponds to the more inner rule. The ordering check is
kept as an additional technical example; this detail is not included in
the article being published.

[Back to contents](#contents)

<a id="testng"></a>

## TestNG 7.12.0

The project contains four independent classes, each run separately:

- [`BeforeFailsWithoutAlwaysRunScenario`](testng-7.12.0/src/test/java/com/example/testng/BeforeFailsWithoutAlwaysRunScenario.java) –
  an exception in `@BeforeSuite`; the test and the plain `@AfterSuite` are
  skipped.
- [`BeforeFailsWithAlwaysRunScenario`](testng-7.12.0/src/test/java/com/example/testng/BeforeFailsWithAlwaysRunScenario.java) –
  the same exception, but `@AfterSuite(alwaysRun = true)` runs.
- [`TestFailsScenario`](testng-7.12.0/src/test/java/com/example/testng/TestFailsScenario.java) –
  setup succeeds, the test calls `fail(...)`, the plain `@AfterSuite` runs.
- [`AfterFailsScenario`](testng-7.12.0/src/test/java/com/example/testng/AfterFailsScenario.java) –
  setup and the test succeed, the plain `@AfterSuite` throws.

```powershell
cd testng-7.12.0
mvn -Dscenario=BeforeFailsWithoutAlwaysRunScenario test
mvn -Dscenario=BeforeFailsWithAlwaysRunScenario test
mvn -Dscenario=TestFailsScenario test
mvn -Dscenario=AfterFailsScenario test
```

Expected event sequences:

| Scenario                                                 | Events                                                       |
|-----------------------------------------------------------|----------------------------------------------------------------|
| `@BeforeSuite` failure, plain `@AfterSuite`               | only `beforeSuite`; the test and `@AfterSuite` do not run      |
| `@BeforeSuite` failure, `@AfterSuite(alwaysRun = true)`   | `beforeSuite`, `afterSuite`; the test does not run             |
| Test failure                                               | `beforeSuite`, `test`, `afterSuite`                            |
| `@AfterSuite` failure                                      | `beforeSuite`, `test`, `afterSuite`                            |

In all four cases, the run ends with an error.

<a id="scope"></a>

## Scope of the findings

The JUnit 5/6 results capture the observed behavior of the stated
versions. The `@BeforeSuite` and `@AfterSuite` Javadocs do not spell out a
separate guarantee for an exception from `@BeforeSuite`, so the experiment
should not be treated as a permanent contract for all future versions. For
TestNG, the behavior of `alwaysRun` is additionally described in the
official documentation.

<a id="verification-2026-10-26"></a>

## Re-verification on October 26, 2026

On JDK 21.0.10, Maven 3.9.12, and Surefire 3.6.0, six setup-failure
scenarios were run individually: two for JUnit 4.13.2, one each for JUnit
5.14.4 and 6.1.3, and two for TestNG 7.12.0 (with and without
`alwaysRun = true`). The `[EVENT]` sequences matched those listed above;
the `test` event was absent in all six. Each command returned exit code 1
due to the intentional exception in setup.

After merging the JUnit 4 projects, both the `@BeforeClass` failure checks
and `ClassRuleOrderTest` were re-run separately. The first two kept the
expected events and exit code 1; the Rules ordering check finished with
exit code 0 and the expected nesting.

Surefire may report `Tests run: 1` for a synthetic `initializationError`
in JUnit. This does not mean the body of the selected test ran: in these
scenarios it prints `[EVENT] test`, which is absent from the output. In
TestNG, the test is marked as skipped. XML reports are located under
`target/surefire-reports/` of the corresponding project; on repeated runs
the reports may be overwritten or left over from earlier scenarios.

<a id="license"></a>

## License

The code and accompanying documentation are distributed under the
[MIT License](LICENSE). The original copyright notice from the source
repository is preserved: Copyright (c) 2021 Andrii Olieinik. JUnit,
TestNG, and other dependencies are distributed under their own licenses.
