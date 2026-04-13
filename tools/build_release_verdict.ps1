param(
  [string]$ReportsDir = 'tools/reports',
  [string]$OutputPath = 'tools/reports/release_candidate_verdict.json',
  [string]$MarkdownOutputPath = 'tools/reports/release_candidate_verdict.md'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $ReportsDir)) {
  Write-Error "Reports directory not found: $ReportsDir"
  exit 1
}

function Get-LatestReport {
  param(
    [string]$Pattern
  )

  $file = Get-ChildItem -Path $ReportsDir -Filter $Pattern -File |
    Sort-Object LastWriteTimeUtc -Descending |
    Select-Object -First 1

  if ($null -eq $file) {
    return $null
  }

  $json = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
  return [PSCustomObject]@{
    Path = $file.FullName
    Name = $file.Name
    Data = $json
  }
}

$tier0 = Get-LatestReport -Pattern 'tier0_burn_in_*.json'
$tier1 = Get-LatestReport -Pattern 'tier1_burn_in_*.json'

if ($null -eq $tier0 -or $null -eq $tier1) {
  Write-Error 'Missing tier0 or tier1 burn-in report. Cannot build release verdict.'
  exit 1
}

function Build-GateSummary {
  param(
    [string]$Gate,
    [object]$Report
  )

  $reportData = $Report.Data
  $pass = ($reportData.failedRuns -eq 0)

  return [PSCustomObject]@{
    gate = $Gate
    pass = $pass
    totalRuns = [int]$reportData.totalRuns
    passedRuns = [int]$reportData.passedRuns
    failedRuns = [int]$reportData.failedRuns
    cycles = [int]$reportData.cycles
    sourceReport = $Report.Name
    caseSummary = $reportData.caseSummary
  }
}

function Get-Numeric {
  param(
    [object]$Value,
    [double]$Default = 0
  )

  if ($null -eq $Value) {
    return $Default
  }

  $parsed = 0.0
  if ([double]::TryParse($Value.ToString(), [ref]$parsed)) {
    return $parsed
  }

  return $Default
}

function Build-DriftSummary {
  param(
    [object]$GateSummary
  )

  $cases = @($GateSummary.caseSummary)
  if ($cases.Count -eq 0) {
    return [PSCustomObject]@{
      averageVariabilityRatio = 1.0
      maxVariabilityRatio = 1.0
      driftScore = 0
      topCases = @()
    }
  }

  $ratios = @()
  $topCases = @()

  foreach ($case in $cases) {
    $avg = Get-Numeric -Value $case.AvgDurationMs
    $min = Get-Numeric -Value $case.MinDurationMs
    $max = Get-Numeric -Value $case.MaxDurationMs

    # Backward compatibility for older burn-in reports that only recorded max duration.
    if ($avg -le 0 -and $max -gt 0) {
      $avg = $max
    }
    if ($min -le 0 -and $max -gt 0) {
      $min = $max
    }

    if ($avg -le 0) {
      $ratio = 1.0
    } else {
      $ratio = [math]::Max(0, ($max - $min) / $avg)
    }

    $ratios += $ratio
    $topCases += [PSCustomObject]@{
      caseId = $case.CaseId
      minDurationMs = $min
      avgDurationMs = $avg
      maxDurationMs = $max
      variabilityRatio = [math]::Round($ratio, 4)
    }
  }

  $avgRatio = ($ratios | Measure-Object -Average).Average
  $maxRatio = ($ratios | Measure-Object -Maximum).Maximum
  $driftScore = [math]::Max(0, 100 - [math]::Min(100, [math]::Round($avgRatio * 100, 2)))

  return [PSCustomObject]@{
    averageVariabilityRatio = [math]::Round($avgRatio, 4)
    maxVariabilityRatio = [math]::Round($maxRatio, 4)
    driftScore = [math]::Round($driftScore, 2)
    topCases = @($topCases | Sort-Object variabilityRatio -Descending | Select-Object -First 3)
  }
}

function Build-GateScore {
  param(
    [object]$GateSummary,
    [object]$Drift
  )

  $passRate = if ($GateSummary.totalRuns -eq 0) { 0 } else { [math]::Round(($GateSummary.passedRuns / $GateSummary.totalRuns) * 100, 2) }
  $failurePenalty = if ($GateSummary.failedRuns -gt 0) { 40 } else { 0 }

  $score = (0.75 * $passRate) + (0.25 * $Drift.driftScore) - $failurePenalty
  return [math]::Max(0, [math]::Min(100, [math]::Round($score, 2)))
}

$tier0Summary = Build-GateSummary -Gate 'tier0' -Report $tier0
$tier1Summary = Build-GateSummary -Gate 'tier1' -Report $tier1

$tier0Drift = Build-DriftSummary -GateSummary $tier0Summary
$tier1Drift = Build-DriftSummary -GateSummary $tier1Summary

$tier0Score = Build-GateScore -GateSummary $tier0Summary -Drift $tier0Drift
$tier1Score = Build-GateScore -GateSummary $tier1Summary -Drift $tier1Drift

$releasePass = $tier0Summary.pass -and $tier1Summary.pass

$confidenceScore = [math]::Round((0.5 * $tier0Score) + (0.5 * $tier1Score), 2)

if (-not $releasePass) {
  $confidenceScore = [math]::Min($confidenceScore, 49)
}

$confidenceBand = if ($confidenceScore -ge 90) {
  'very_high'
} elseif ($confidenceScore -ge 75) {
  'high'
} elseif ($confidenceScore -ge 60) {
  'moderate'
} else {
  'low'
}

$verdict = [ordered]@{
  generatedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
  gitRef = $env:GITHUB_REF
  gitSha = $env:GITHUB_SHA
  runId = $env:GITHUB_RUN_ID
  runNumber = $env:GITHUB_RUN_NUMBER
  releaseCandidateVerdict = if ($releasePass) { 'PASS' } else { 'FAIL' }
  releaseConfidenceScore = $confidenceScore
  releaseConfidenceBand = $confidenceBand
  scoringModel = [ordered]@{
    modelVersion = 'rc_confidence_v1'
    tierWeight = [ordered]@{
      tier0 = 0.5
      tier1 = 0.5
    }
    gateScoreFormula = 'gateScore = 0.75*passRate + 0.25*driftScore - failurePenalty(40 when failedRuns>0)'
    driftFormula = 'driftScore = 100 - min(100, avg((max-min)/avg)*100)'
  }
  gateScores = @(
    [ordered]@{
      gate = 'tier0'
      score = $tier0Score
      passRate = if ($tier0Summary.totalRuns -eq 0) { 0 } else { [math]::Round(($tier0Summary.passedRuns / $tier0Summary.totalRuns) * 100, 2) }
      drift = $tier0Drift
    },
    [ordered]@{
      gate = 'tier1'
      score = $tier1Score
      passRate = if ($tier1Summary.totalRuns -eq 0) { 0 } else { [math]::Round(($tier1Summary.passedRuns / $tier1Summary.totalRuns) * 100, 2) }
      drift = $tier1Drift
    }
  )
  gates = @(
    $tier0Summary,
    $tier1Summary
  )
}

$outputDir = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path $outputDir)) {
  New-Item -Path $outputDir -ItemType Directory | Out-Null
}

$verdict | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8

$mdLines = @(
  '# Release Candidate Verdict',
  '',
  "- GeneratedAtUtc: $($verdict.generatedAtUtc)",
  "- GitRef: $($verdict.gitRef)",
  "- GitSha: $($verdict.gitSha)",
  "- Verdict: $($verdict.releaseCandidateVerdict)",
  "- ConfidenceScore: $($verdict.releaseConfidenceScore)",
  "- ConfidenceBand: $($verdict.releaseConfidenceBand)",
  '',
  '## Gate Summary',
  '',
  '| Gate | Pass | TotalRuns | PassedRuns | FailedRuns | Score | DriftScore | AvgVariability | MaxVariability | SourceReport |',
  '|---|---:|---:|---:|---:|---:|---:|---:|---:|---|',
  "| tier0 | $($tier0Summary.pass) | $($tier0Summary.totalRuns) | $($tier0Summary.passedRuns) | $($tier0Summary.failedRuns) | $tier0Score | $($tier0Drift.driftScore) | $($tier0Drift.averageVariabilityRatio) | $($tier0Drift.maxVariabilityRatio) | $($tier0Summary.sourceReport) |",
  "| tier1 | $($tier1Summary.pass) | $($tier1Summary.totalRuns) | $($tier1Summary.passedRuns) | $($tier1Summary.failedRuns) | $tier1Score | $($tier1Drift.driftScore) | $($tier1Drift.averageVariabilityRatio) | $($tier1Drift.maxVariabilityRatio) | $($tier1Summary.sourceReport) |",
  '',
  '## Top Drift Cases',
  '',
  '### Tier 0',
  '| Case | MinMs | AvgMs | MaxMs | Variability |',
  '|---|---:|---:|---:|---:|'
)

foreach ($case in $tier0Drift.topCases) {
  $mdLines += "| $($case.caseId) | $($case.minDurationMs) | $($case.avgDurationMs) | $($case.maxDurationMs) | $($case.variabilityRatio) |"
}

$mdLines += @(
  '',
  '### Tier 1',
  '| Case | MinMs | AvgMs | MaxMs | Variability |',
  '|---|---:|---:|---:|---:|'
)

foreach ($case in $tier1Drift.topCases) {
  $mdLines += "| $($case.caseId) | $($case.minDurationMs) | $($case.avgDurationMs) | $($case.maxDurationMs) | $($case.variabilityRatio) |"
}

$mdLines += @(
  '',
  '## Notes',
  "- Decision policy: releaseCandidateVerdict must be PASS to release.",
  "- Confidence policy: higher score indicates lower timing variance under burn-in.",
  "- Model: rc_confidence_v1"
)

$mdDir = Split-Path -Path $MarkdownOutputPath -Parent
if (-not (Test-Path $mdDir)) {
  New-Item -Path $mdDir -ItemType Directory | Out-Null
}

$mdLines -join "`n" | Out-File -FilePath $MarkdownOutputPath -Encoding utf8

Write-Host "Release verdict written: $OutputPath"
Write-Host "Release markdown summary written: $MarkdownOutputPath"
Write-Host "Verdict: $($verdict.releaseCandidateVerdict)"

if (-not $releasePass) {
  exit 1
}

exit 0