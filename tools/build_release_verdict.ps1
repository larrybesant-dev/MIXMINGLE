param(
  [string]$ReportsDir = 'tools/reports',
  [string]$OutputPath = 'tools/reports/release_candidate_verdict.json',
  [string]$MarkdownOutputPath = 'tools/reports/release_candidate_verdict.md',
  [string]$HistoryDir = 'tools/reports/history',
  [string]$HistoryIndexPath = 'tools/reports/history/verdict_index.json'
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
$roomGate = Get-LatestReport -Pattern 'room_release_stress_gate_*.json'

if ($null -eq $tier0 -or $null -eq $tier1 -or $null -eq $roomGate) {
  Write-Error 'Missing tier0, tier1, or room release gate report. Cannot build release verdict.'
  exit 1
}

function Build-GateSummary {
  param(
    [string]$Gate,
    [object]$Report
  )

  $reportData = $Report.Data
  $pass = if ($null -ne $reportData.failedRuns) {
    ($reportData.failedRuns -eq 0)
  } elseif ($null -ne $reportData.verdict) {
    ($reportData.verdict -eq 'PASS')
  } else {
    $false
  }

  $cycles = if ($null -ne $reportData.cycles) {
    [int]$reportData.cycles
  } else {
    1
  }

  $caseSummary = if ($null -ne $reportData.caseSummary) {
    $reportData.caseSummary
  } elseif ($null -ne $reportData.cases) {
    $reportData.cases
  } else {
    @()
  }

  return [PSCustomObject]@{
    gate = $Gate
    pass = $pass
    totalRuns = [int]$reportData.totalRuns
    passedRuns = [int]$reportData.passedRuns
    failedRuns = [int]$reportData.failedRuns
    cycles = $cycles
    sourceReport = $Report.Name
    caseSummary = $caseSummary
  }
}

function Get-FirstPropertyValue {
  param(
    [object]$Object,
    [string[]]$Names,
    [object]$Default = $null
  )

  if ($null -eq $Object) {
    return $Default
  }

  foreach ($name in $Names) {
    $property = $Object.PSObject.Properties[$name]
    if ($null -ne $property) {
      return $property.Value
    }
  }

  return $Default
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
    $caseId = Get-FirstPropertyValue -Object $case -Names @('CaseId', 'caseId') -Default 'unknown'
    $avg = Get-Numeric -Value (Get-FirstPropertyValue -Object $case -Names @('AvgDurationMs', 'avgDurationMs', 'durationMs') -Default 0)
    $min = Get-Numeric -Value (Get-FirstPropertyValue -Object $case -Names @('MinDurationMs', 'minDurationMs', 'durationMs') -Default 0)
    $max = Get-Numeric -Value (Get-FirstPropertyValue -Object $case -Names @('MaxDurationMs', 'maxDurationMs', 'durationMs') -Default 0)

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
      caseId = $caseId
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
$roomSummary = Build-GateSummary -Gate 'room' -Report $roomGate

$tier0Drift = Build-DriftSummary -GateSummary $tier0Summary
$tier1Drift = Build-DriftSummary -GateSummary $tier1Summary
$roomDrift = Build-DriftSummary -GateSummary $roomSummary

$tier0Score = Build-GateScore -GateSummary $tier0Summary -Drift $tier0Drift
$tier1Score = Build-GateScore -GateSummary $tier1Summary -Drift $tier1Drift
$roomScore = Build-GateScore -GateSummary $roomSummary -Drift $roomDrift

$releasePass = $tier0Summary.pass -and $tier1Summary.pass -and $roomSummary.pass

$confidenceScore = [math]::Round((0.4 * $tier0Score) + (0.4 * $tier1Score) + (0.2 * $roomScore), 2)

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
    modelVersion = 'rc_confidence_v2'
    tierWeight = [ordered]@{
      tier0 = 0.4
      tier1 = 0.4
      room = 0.2
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
    },
    [ordered]@{
      gate = 'room'
      score = $roomScore
      passRate = if ($roomSummary.totalRuns -eq 0) { 0 } else { [math]::Round(($roomSummary.passedRuns / $roomSummary.totalRuns) * 100, 2) }
      drift = $roomDrift
    }
  )
  gates = @(
    $tier0Summary,
    $tier1Summary,
    $roomSummary
  )
}

$outputDir = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path $outputDir)) {
  New-Item -Path $outputDir -ItemType Directory | Out-Null
}

$verdict | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8

if (-not (Test-Path $HistoryDir)) {
  New-Item -Path $HistoryDir -ItemType Directory | Out-Null
}

$refName = if ([string]::IsNullOrWhiteSpace($env:GITHUB_REF_NAME)) { 'local' } else { $env:GITHUB_REF_NAME }
$safeRefName = ($refName -replace '[^A-Za-z0-9._-]', '_')
$runIdentity = if ([string]::IsNullOrWhiteSpace($env:GITHUB_RUN_ID)) {
  (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')
} else {
  $env:GITHUB_RUN_ID
}

$historyFileName = "release_candidate_verdict_${safeRefName}_${runIdentity}.json"
$historyFilePath = Join-Path $HistoryDir $historyFileName
$duplicateCounter = 1
while (Test-Path $historyFilePath) {
  $historyFileName = "release_candidate_verdict_${safeRefName}_${runIdentity}_$duplicateCounter.json"
  $historyFilePath = Join-Path $HistoryDir $historyFileName
  $duplicateCounter += 1
}

$verdict | ConvertTo-Json -Depth 10 | Out-File -FilePath $historyFilePath -Encoding utf8

$indexDir = Split-Path -Path $HistoryIndexPath -Parent
if (-not (Test-Path $indexDir)) {
  New-Item -Path $indexDir -ItemType Directory | Out-Null
}

$index = @()
if (Test-Path $HistoryIndexPath) {
  $rawIndex = Get-Content -Path $HistoryIndexPath -Raw
  if (-not [string]::IsNullOrWhiteSpace($rawIndex)) {
    $parsedIndex = $rawIndex | ConvertFrom-Json
    $index = @($parsedIndex)
  }
}

$index += [PSCustomObject]@{
  generatedAtUtc = $verdict.generatedAtUtc
  file = $historyFileName
  gitRef = $verdict.gitRef
  gitSha = $verdict.gitSha
  runId = $verdict.runId
  runNumber = $verdict.runNumber
  releaseCandidateVerdict = $verdict.releaseCandidateVerdict
  releaseConfidenceScore = $verdict.releaseConfidenceScore
}

$index | ConvertTo-Json -Depth 10 | Out-File -FilePath $HistoryIndexPath -Encoding utf8

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
  "| room | $($roomSummary.pass) | $($roomSummary.totalRuns) | $($roomSummary.passedRuns) | $($roomSummary.failedRuns) | $roomScore | $($roomDrift.driftScore) | $($roomDrift.averageVariabilityRatio) | $($roomDrift.maxVariabilityRatio) | $($roomSummary.sourceReport) |",
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
  '### Room Gate',
  '| Case | MinMs | AvgMs | MaxMs | Variability |',
  '|---|---:|---:|---:|---:|'
)

foreach ($case in $roomDrift.topCases) {
  $mdLines += "| $($case.caseId) | $($case.minDurationMs) | $($case.avgDurationMs) | $($case.maxDurationMs) | $($case.variabilityRatio) |"
}

$mdLines += @(
  '',
  '## Notes',
  "- Decision policy: releaseCandidateVerdict must be PASS to release.",
  "- Confidence policy: tier0, tier1, and room stability all contribute to the score.",
  "- Model: rc_confidence_v2"
)

$mdDir = Split-Path -Path $MarkdownOutputPath -Parent
if (-not (Test-Path $mdDir)) {
  New-Item -Path $mdDir -ItemType Directory | Out-Null
}

$mdLines -join "`n" | Out-File -FilePath $MarkdownOutputPath -Encoding utf8

Write-Host "Release verdict written: $OutputPath"
Write-Host "Immutable verdict event written: $historyFilePath"
Write-Host "Verdict history index updated: $HistoryIndexPath"
Write-Host "Release markdown summary written: $MarkdownOutputPath"
Write-Host "Verdict: $($verdict.releaseCandidateVerdict)"

if (-not $releasePass) {
  exit 1
}

exit 0