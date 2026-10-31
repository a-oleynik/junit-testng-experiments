#requires -Version 7.2
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../verify.ps1')

# Synthetic reports exercise the verifier; these are not framework behavior tests.
$fixtureRoot = Join-Path $PSScriptRoot ('../target/verifier-tests/' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixtureRoot -Force | Out-Null
$failureScenario = @{
    ExitCode = 1
    Events = @('[EVENT] beforeSuite', '[EVENT] afterSuite')
    FailureType = 'java.lang.IllegalStateException'
    FailureMessage = 'Expected failure from @BeforeSuite'
}
$successScenario = @{
    ExitCode = 0
    Events = @('[EVENTS] [outer.before, inner.before, test, inner.after, outer.after]')
    FailureType = ''
    FailureMessage = ''
}
$expectedFailure = '<error type="java.lang.IllegalStateException" message="Expected failure from @BeforeSuite" />'
$unexpectedFailure = '<error type="java.lang.IllegalArgumentException" message="Unexpected error" />'
$cases = @(
    @{ Name='expected-failure'; Scenario=$failureScenario; Exit=1; Output=$failureScenario.Events -join "`n"; Xml="<testsuite><testcase>$expectedFailure</testcase></testsuite>"; Pass=$true },
    @{ Name='successful-order-check'; Scenario=$successScenario; Exit=0; Output=$successScenario.Events -join "`n"; Xml='<testsuite><testcase /></testsuite>'; Pass=$true },
    @{ Name='unexpected-success'; Scenario=$failureScenario; Exit=0; Output=$failureScenario.Events -join "`n"; Xml="<testsuite><testcase>$expectedFailure</testcase></testsuite>"; Pass=$false },
    @{ Name='wrong-event-order'; Scenario=$failureScenario; Exit=1; Output="[EVENT] afterSuite`n[EVENT] beforeSuite"; Xml="<testsuite><testcase>$expectedFailure</testcase></testsuite>"; Pass=$false },
    @{ Name='unexpected-test-execution'; Scenario=$failureScenario; Exit=1; Output="[EVENT] beforeSuite`n[EVENT] test`n[EVENT] afterSuite"; Xml="<testsuite><testcase>$expectedFailure</testcase></testsuite>"; Pass=$false },
    @{ Name='build-error-without-reports'; Scenario=$failureScenario; Exit=1; Output='Compilation failed'; Xml=$null; Pass=$false },
    @{ Name='wrong-exception'; Scenario=$failureScenario; Exit=1; Output=$failureScenario.Events -join "`n"; Xml="<testsuite><testcase>$unexpectedFailure</testcase></testsuite>"; Pass=$false },
    @{ Name='additional-failure'; Scenario=$failureScenario; Exit=1; Output=$failureScenario.Events -join "`n"; Xml="<testsuite><testcase>$expectedFailure</testcase><testcase>$unexpectedFailure</testcase></testsuite>"; Pass=$false },
    @{ Name='empty-report'; Scenario=$successScenario; Exit=0; Output=$successScenario.Events -join "`n"; Xml='<testsuite />'; Pass=$false },
    @{ Name='malformed-report'; Scenario=$failureScenario; Exit=1; Output=$failureScenario.Events -join "`n"; Xml='<testsuite>'; Pass=$false }
)
foreach ($case in $cases) {
    $reports = Join-Path $fixtureRoot $case.Name
    New-Item -ItemType Directory -Path $reports -Force | Out-Null
    if ($null -ne $case.Xml) {
        $case.Xml | Set-Content -LiteralPath (Join-Path $reports 'TEST-fixture.xml') -Encoding utf8
    }
    $result = Test-ScenarioResult -Scenario $case.Scenario -ExitCode $case.Exit -Output $case.Output -ReportsDirectory $reports
    if ($result.Passed -ne $case.Pass) {
        throw "Verifier self-test failed: $($case.Name); $($result.Problems -join '; ')"
    }
    Write-Host "PASS $($case.Name)"
}
Write-Host "$($cases.Count) verifier self-tests passed."
