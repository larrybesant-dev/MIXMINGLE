$ErrorActionPreference = 'Stop'

$files = @(
  'build/web/flutter.js',
  'build/web/flutter_bootstrap.js',
  'build/web/main.dart.js'
)

foreach ($relativePath in $files) {
  if (-not (Test-Path $relativePath)) {
    continue
  }

  $content = Get-Content -Path $relativePath -Raw
  $updated = $content

  $updated = $updated.Replace('typeof Intl.v8BreakIterator<"u"&&typeof Intl.Segmenter<"u"', 'typeof Intl.Segmenter<"u"')
  $updated = $updated -replace 'return s\.Intl\.v8BreakIterator!=null&&s\.Intl\.Segmenter!=null\},', 'return s.Intl.Segmenter!=null},'
  $updated = $updated -replace 's\(\$,"bTu","bt2",\(\)=>\{var q="v8BreakIterator"\s*if\(A\.Z\(A\.Z\(A\.rP\(\),"Intl"\),q\)==null\)A\.a8\(A\.e5\("v8BreakIterator is not supported\."\)\)\s*return A\.bGC\(A\.V3\(A\.V3\(A\.rP\(\),"Intl"\),q\),A\.byq\(\[\]\),A\.bjj\(B\.a5F\)\)\}\)', 's($,"bTu","bt2",()=>A.boA("word"))'
  $updated = $updated -replace 's\(\$,"ce5","bMz",\(\)=>\{var q="v8BreakIterator"\s*if\(A\.a5\(A\.a5\(A\.uj\(\),"Intl"\),q\)==null\)A\.ab\(A\.dx\("v8BreakIterator is not supported\."\)\)\s*return A\.c0n\(A\.Yu\(A\.Yu\(A\.uj\(\),"Intl"\),q\),A\.bSF\(\[\]\),A\.bCl\(B\.ara\)\)\}\)', 's($,"ce5","bMz",()=>A.bHU("word"))'

  if ($updated -ne $content) {
    Set-Content -Path $relativePath -Value $updated -NoNewline
    Write-Host "Patched $relativePath"
  }
}