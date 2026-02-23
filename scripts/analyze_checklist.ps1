# scripts/analyze_checklist.ps1
#
# Runs flutter analyze, parses the output, and prints a per-file checklist
# of prefer_const_constructors / prefer_final_locals / prefer_final_fields
# hints for the files you care about.
#
# Usage (from repo root):
#   .\scripts\analyze_checklist.ps1
#   .\scripts\analyze_checklist.ps1 -Files "lib/widgets/video_grid_widget.dart","lib/theme/mix_mingle_theme.dart"
#   .\scripts\analyze_checklist.ps1 -Rules "prefer_const_constructors","prefer_final_locals" -Out "my_check.txt"
#
# Output columns:  FILE | LINE | COL | RULE | MESSAGE
# After fixing a file, re-run to confirm the checklist entry disappears.

param(
    # Files to include (forward-slash paths, relative to repo root).
    # Default: all lib/ files reported by the analyzer.
    [string[]] $Files = @(),

    # Lint rules to filter on. Empty = include all rules.
    [string[]] $Rules = @(
        'prefer_const_constructors',
        'prefer_const_literals_to_create_immutables',
        'prefer_final_locals',
        'prefer_final_fields',
        'prefer_final_parameters'
    ),

    # Output file path (relative to repo root). '' = stdout only.
    [string] $Out = 'analyze_checklist.txt',

    # Show a summary line per file at the end.
    [switch] $Summary
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Step 1 — run flutter analyze and capture output
# ---------------------------------------------------------------------------
Write-Host 'Running flutter analyze …' -ForegroundColor Cyan
$raw = flutter analyze --no-fatal-infos 2>&1 | Out-String

# ---------------------------------------------------------------------------
# Step 2 — parse lines of the form:
#   {severity} • {message} • {relpath}:{line}:{col} • {rule}
# ---------------------------------------------------------------------------

# Normalize path separators to forward-slash for comparison
function NormPath([string]$p) { $p -replace '\\', '/' }

$repoRoot = NormPath (Get-Location).Path

# Regex: leading whitespace, severity word, bullet, message, bullet, path:line:col, bullet, rule
$lineRe = [regex]'^\s*(?<sev>\w+)\s+[•·]\s+(?<msg>.+?)\s+[•·]\s+(?<file>[^•·]+?):(?<line>\d+):(?<col>\d+)\s+[•·]\s+(?<rule>\w+)\s*$'

$allHints = [System.Collections.Generic.List[hashtable]]::new()

foreach ($rawLine in $raw -split "`n") {
    $m = $lineRe.Match($rawLine)
    if (-not $m.Success) { continue }

    $filePath = NormPath $m.Groups['file'].Value.Trim()
    # Make relative if it starts with the repo root
    if ($filePath.StartsWith($repoRoot)) {
        $filePath = $filePath.Substring($repoRoot.Length).TrimStart('/')
    }

    $hint = @{
        Severity = $m.Groups['sev'].Value
        Message  = $m.Groups['msg'].Value.Trim()
        File     = $filePath
        Line     = [int]$m.Groups['line'].Value
        Col      = [int]$m.Groups['col'].Value
        Rule     = $m.Groups['rule'].Value
    }
    $allHints.Add($hint)
}

# ---------------------------------------------------------------------------
# Step 3 — apply filters
# ---------------------------------------------------------------------------

$filtered = $allHints | Where-Object {
    $h = $_
    $ruleOk = ($Rules.Count -eq 0) -or ($Rules -contains $h.Rule)
    $fileOk = ($Files.Count -eq 0) -or ($Files | ForEach-Object { NormPath $_ } | Where-Object { $_ -eq $h.File } | Select-Object -First 1)
    $ruleOk -and $fileOk
} | Sort-Object File, Line, Col

# ---------------------------------------------------------------------------
# Step 4 — format output
# ---------------------------------------------------------------------------

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("Const/Final checklist  —  $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
$lines.Add("Rules: $($Rules -join ', ')")
$lines.Add("Total hints: $($filtered.Count)")
$lines.Add('')

if ($filtered.Count -eq 0) {
    $lines.Add('  ✅  No matching hints found — all target rules are clean.')
} else {
    $currentFile = ''
    foreach ($h in $filtered) {
        if ($h.File -ne $currentFile) {
            $currentFile = $h.File
            $fileCount = ($filtered | Where-Object { $_.File -eq $currentFile }).Count
            $lines.Add("📄  $currentFile  ($fileCount hint(s))")
        }
        $lines.Add("    [ ]  L$($h.Line):$($h.Col)  $($h.Rule)  —  $($h.Message)")
    }
}

# Summary block
if ($Summary -or $files.Count -gt 0) {
    $lines.Add('')
    $lines.Add('─── Per-file summary ───────────────────────────────────────')
    $filtered | Group-Object File | Sort-Object Name | ForEach-Object {
        $lines.Add("  $($_.Count.ToString().PadLeft(3))  $($_.Name)")
    }
}

# ---------------------------------------------------------------------------
# Step 5 — emit
# ---------------------------------------------------------------------------

$output = $lines -join "`n"

Write-Host ''
Write-Host $output

if ($Out -ne '') {
    $output | Out-File $Out -Encoding utf8
    Write-Host ''
    Write-Host "Checklist written → $Out" -ForegroundColor Green
}
