#requires -Version 7.2
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Maven deliberately returns 1 for the failure scenarios.
$PSNativeCommandUseErrorActionPreference = $false

function Test-ScenarioResult {
    param(
        [Parameter(Mandatory)] $Scenario,
        [Parameter(Mandatory)] [int] $ExitCode,
        [AllowEmptyString()] [string] $Output,
        [Parameter(Mandatory)] [string] $ReportsDirectory
    )

    $problems = [System.Collections.Generic.List[string]]::new()
    if ($ExitCode -ne $Scenario.ExitCode) {
        $problems.Add("Exit code: expected $($Scenario.ExitCode), got $ExitCode")
    }
    $events = @([regex]::Matches($Output, '(?m)^\[EVENTS?\][^\r\n]*') |
        ForEach-Object { $_.Value.Trim() })
    if (($events -join "`n") -cne ($Scenario.Events -join "`n")) {
        $problems.Add("Events: expected [$($Scenario.Events -join '; ')], got [$($events -join '; ')]")
    }

    $reports = @(Get-ChildItem -LiteralPath $ReportsDirectory -Filter 'TEST-*.xml' -File -ErrorAction SilentlyContinue)
    if ($reports.Count -eq 0) {
        $problems.Add('No Surefire XML reports: a build or dependency error is not an expected test failure.')
    }
    $failures = [System.Collections.Generic.List[object]]::new()
    $caseCount = 0
    foreach ($report in $reports) {
        try {
            [xml] $xml = Get-Content -LiteralPath $report.FullName -Raw
            $caseCount += $xml.SelectNodes('/testsuite/testcase').Count
            foreach ($failure in $xml.SelectNodes('/testsuite/testcase/error | /testsuite/testcase/failure')) {
                $failures.Add($failure)
            }
        } catch {
            $problems.Add("Invalid report $($report.Name): $($_.Exception.Message)")
        }
    }
    if ($caseCount -eq 0) { $problems.Add('No testcase entries in the reports.') }
    $expectedFailureCount = if ($Scenario.ExitCode -eq 0) { 0 } else { 1 }
    if ($failures.Count -ne $expectedFailureCount) {
        $problems.Add("Expected $expectedFailureCount reported failure(s), got $($failures.Count).")
    }
    foreach ($failure in $failures) {
        if ($failure.GetAttribute('message') -cne $Scenario.FailureMessage -or
            $failure.GetAttribute('type') -cne $Scenario.FailureType) {
            $problems.Add("Unexpected failure: $($failure.GetAttribute('type')): $($failure.GetAttribute('message'))")
        }
    }
    return [pscustomobject]@{ Passed = $problems.Count -eq 0; Problems = $problems.ToArray() }
}

# Allow the verifier's own tests to load the validation function without running Maven.
if ($MyInvocation.InvocationName -eq '.') { return }

try {
    $maven = (Get-Command mvn -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
    $runDirectory = Join-Path $PSScriptRoot ('target/verification/' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $runDirectory -Force | Out-Null
    $scenarios = @(
        @{ Project='junit-6.1.3'; Name='BeforeFailsSuite'; ExitCode=1; Events=@('[EVENT] beforeSuite','[EVENT] afterSuite'); FailureType='java.lang.IllegalStateException'; FailureMessage='Expected failure from @BeforeSuite' },
        @{ Project='junit-6.1.3'; Name='TestFailsSuite'; ExitCode=1; Events=@('[EVENT] beforeSuite','[EVENT] test','[EVENT] afterSuite'); FailureType='org.opentest4j.AssertionFailedError'; FailureMessage='Expected test failure' },
        @{ Project='junit-6.1.3'; Name='AfterFailsSuite'; ExitCode=1; Events=@('[EVENT] beforeSuite','[EVENT] test','[EVENT] afterSuite'); FailureType='java.lang.IllegalStateException'; FailureMessage='Expected failure from @AfterSuite' },
        @{ Project='junit-5.14.4'; Name='BeforeFailsSuite'; ExitCode=1; Events=@('[EVENT] beforeSuite','[EVENT] afterSuite'); FailureType='java.lang.IllegalStateException'; FailureMessage='Expected failure from @BeforeSuite' },
        @{ Project='junit-4.13.2'; Name='BeforeClassFailsScenario'; ExitCode=1; Events=@('[EVENT] beforeClass','[EVENT] afterClass'); FailureType='java.lang.IllegalStateException'; FailureMessage='Expected failure from @BeforeClass' },
        @{ Project='junit-4.13.2'; Name='BeforeClassFailsSuite'; ExitCode=1; Events=@('[EVENT] suite.beforeClass','[EVENT] suite.afterClass'); FailureType='java.lang.IllegalStateException'; FailureMessage='Expected failure from suite @BeforeClass' },
        @{ Project='junit-4.13.2'; Name='ClassRuleOrderTest'; ExitCode=0; Events=@('[EVENTS] [outer.before, inner.before, test, inner.after, outer.after]'); FailureType=''; FailureMessage='' },
        @{ Project='testng-7.12.0'; Name='BeforeFailsWithoutAlwaysRunScenario'; ExitCode=1; Events=@('[EVENT] beforeSuite'); FailureType='java.lang.IllegalStateException'; FailureMessage='Expected failure from @BeforeSuite' },
        @{ Project='testng-7.12.0'; Name='BeforeFailsWithAlwaysRunScenario'; ExitCode=1; Events=@('[EVENT] beforeSuite','[EVENT] afterSuite'); FailureType='java.lang.IllegalStateException'; FailureMessage='Expected failure from @BeforeSuite' },
        @{ Project='testng-7.12.0'; Name='TestFailsScenario'; ExitCode=1; Events=@('[EVENT] beforeSuite','[EVENT] test','[EVENT] afterSuite'); FailureType='java.lang.AssertionError'; FailureMessage='Expected test failure' },
        @{ Project='testng-7.12.0'; Name='AfterFailsScenario'; ExitCode=1; Events=@('[EVENT] beforeSuite','[EVENT] test','[EVENT] afterSuite'); FailureType='java.lang.IllegalStateException'; FailureMessage='Expected failure from @AfterSuite' }
    )
    $results = @()
    foreach ($scenario in $scenarios) {
        $scenarioDirectory = Join-Path $runDirectory ($scenario.Project + '/' + $scenario.Name)
        $reportsDirectory = Join-Path $scenarioDirectory 'reports'
        New-Item -ItemType Directory -Path $reportsDirectory -Force | Out-Null
        $projectDirectory = Join-Path $PSScriptRoot $scenario.Project
        Write-Host "Running $($scenario.Project)/$($scenario.Name)..."
        Push-Location $projectDirectory
        try {
            $outputLines = @(& $maven '-B' '-ntp' "-Dscenario=$($scenario.Name)" '-DfailIfNoTests=true' "-Dverification.reportsDirectory=$reportsDirectory" 'test' 2>&1)
            $mavenExitCode = $LASTEXITCODE
        } finally {
            Pop-Location
        }
        $outputText = ($outputLines | ForEach-Object { $_.ToString() }) -join "`n"
        $outputText | Set-Content -LiteralPath (Join-Path $scenarioDirectory 'maven.log') -Encoding utf8
        $result = Test-ScenarioResult -Scenario $scenario -ExitCode $mavenExitCode -Output $outputText -ReportsDirectory $reportsDirectory
        $results += [pscustomobject]@{ Project=$scenario.Project; Scenario=$scenario.Name; Passed=$result.Passed; MavenExitCode=$mavenExitCode; Problems=$result.Problems }
        if ($result.Passed) {
            Write-Host "PASS $($scenario.Name) (expected Maven exit $mavenExitCode)"
        } else {
            Write-Host "FAIL $($scenario.Name): $($result.Problems -join ' | ')"
        }
    }
    $results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $runDirectory 'summary.json') -Encoding utf8
    $failed = @($results | Where-Object { -not $_.Passed }).Count
    Write-Host "$($results.Count - $failed)/$($results.Count) scenarios matched expectations. Reports: $runDirectory"
    if ($failed -gt 0) { exit 1 }
    exit 0
} catch {
    Write-Error -Message $_.Exception.Message -ErrorAction Continue
    exit 1
}
