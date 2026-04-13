param(
  [string]$HistoryDir = 'tools/reports/history',
  [string]$SnapshotIndexPath = 'tools/reports/history/policy_analysis_snapshot_index.json',
  [string]$OutputPath = 'tools/reports/policy_analysis_delta.json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function To-IsoOrNow {
  param([object]$Value)
  if ($null -eq $Value) { return (Get-Date).ToUniversalTime() }
  try { return ([datetime]$Value).ToUniversalTime() } catch { return (Get-Date).ToUniversalTime() }
}

function Read-RequiredJson {
  param([string]$Path, [string]$Label)

  if (-not (Test-Path $Path)) {
    throw "Required artifact not found: $Label @ $Path"
  }

  $raw = Get-Content -Path $Path -Raw
  if ([string]::IsNullOrWhiteSpace($raw)) {
    throw "Required artifact is empty: $Label @ $Path"
  }

  return $raw | ConvertFrom-Json
}

$index = @((Read-RequiredJson -Path $SnapshotIndexPath -Label 'PolicyAnalysisSnapshotIndex'))
if ($index.Count -eq 0) {
  throw "Snapshot index has no entries: $SnapshotIndexPath"
}

$ordered = @(
  $index | Sort-Object `
    @{ Expression = { To-IsoOrNow -Value $_.generatedAtUtc } ; Ascending = $true }, `
    @{ Expression = { [string]$_.runId } ; Ascending = $true }, `
    @{ Expression = { [string]$_.file } ; Ascending = $true }
)

$currentEntry = $ordered[-1]
$currentPath = Join-Path $HistoryDir ([string]$currentEntry.file)
$current = Read-RequiredJson -Path $currentPath -Label 'CurrentPolicyAnalysisSnapshot'

$mode = 'baseline'
$previousEntry = $null
$previousPath = ''
$previous = $null

if ($ordered.Count -ge 2) {
  $mode = 'delta'
  $previousEntry = $ordered[-2]
  $previousPath = Join-Path $HistoryDir ([string]$previousEntry.file)
  $previous = Read-RequiredJson -Path $previousPath -Label 'PreviousPolicyAnalysisSnapshot'
}

$driftDelta = $null
$jaccardDelta = $null
$thresholdDelta = $null
$entryCountDelta = $null
$boundaryChanged = $null
$tierChanged = $null
$changeClassification = 'baseline'
$confidence = 'low'
$notes = 'Baseline run: no previous snapshot available for comparison.'

if ($mode -eq 'delta') {
  $driftDelta = [math]::Round(([double]$current.metrics.driftScore - [double]$previous.metrics.driftScore), 4)
  $jaccardDelta = [math]::Round(([double]$current.metrics.jaccard - [double]$previous.metrics.jaccard), 4)
  $thresholdDelta = ([int]$current.metrics.differingThresholdCount - [int]$previous.metrics.differingThresholdCount)
  $entryCountDelta = ([int]$current.metrics.entryCount - [int]$previous.metrics.entryCount)
  $boundaryChanged = ([string]$current.metrics.boundaryBehavior -ne [string]$previous.metrics.boundaryBehavior)
  $tierChanged = ([string]$current.metrics.tier -ne [string]$previous.metrics.tier)

  if ([string]$current.metrics.boundaryBehavior -eq 'insufficient_history') {
    $confidence = 'low'
  } else {
    $confidence = 'normal'
  }

  if ($driftDelta -eq 0 -and $jaccardDelta -eq 0 -and $thresholdDelta -eq 0 -and -not $boundaryChanged -and -not $tierChanged) {
    $changeClassification = 'stable'
    $notes = 'No significant drift detected versus previous run.'
  } elseif ($driftDelta -gt 0 -or $jaccardDelta -lt 0 -or $thresholdDelta -gt 0 -or $boundaryChanged -or $tierChanged) {
    $changeClassification = 'drifting'
    $notes = 'Drift indicators increased versus previous run.'
  } elseif ($driftDelta -lt 0 -or $jaccardDelta -gt 0 -or $thresholdDelta -lt 0) {
    $changeClassification = 'improving'
    $notes = 'Drift indicators improved versus previous run.'
  } else {
    $changeClassification = 'mixed'
    $notes = 'Mixed directional changes detected versus previous run.'
  }
}

$result = [ordered]@{
  generatedAtUtc = [DateTime]::UtcNow.ToString('o')
  deltaVersion = 'policy_analysis_delta_v1'
  schemaVersion = '1.0.0'
  source = [ordered]@{
    snapshotIndexPath = $SnapshotIndexPath
    snapshotCount = $ordered.Count
    currentSnapshotPath = $currentPath
    previousSnapshotPath = $previousPath
  }
  current = [ordered]@{
    generatedAtUtc = $current.generatedAtUtc
    driftScore = $current.metrics.driftScore
    jaccard = $current.metrics.jaccard
    differingThresholdCount = $current.metrics.differingThresholdCount
    boundaryBehavior = $current.metrics.boundaryBehavior
    tier = $current.metrics.tier
    action = $current.metrics.action
  }
  previous = if ($null -ne $previous) {
    [ordered]@{
      generatedAtUtc = $previous.generatedAtUtc
      driftScore = $previous.metrics.driftScore
      jaccard = $previous.metrics.jaccard
      differingThresholdCount = $previous.metrics.differingThresholdCount
      boundaryBehavior = $previous.metrics.boundaryBehavior
      tier = $previous.metrics.tier
      action = $previous.metrics.action
    }
  } else {
    $null
  }
  summary = [ordered]@{
    mode = $mode
    driftScoreDelta = $driftDelta
    jaccardDelta = $jaccardDelta
    differingThresholdCountDelta = $thresholdDelta
    entryCountDelta = $entryCountDelta
    boundaryBehaviorChanged = $boundaryChanged
    tierChanged = $tierChanged
    changeClassification = $changeClassification
    confidence = $confidence
    notes = $notes
  }
}

$outDir = Split-Path -Path $OutputPath -Parent
if (-not [string]::IsNullOrWhiteSpace($outDir) -and -not (Test-Path $outDir)) {
  New-Item -Path $outDir -ItemType Directory | Out-Null
}

$json = $result | ConvertTo-Json -Depth 20
$json | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "Policy analysis delta written: $OutputPath"
Write-Output $json
