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
  $updated = $updated.Replace('return s.Intl.v8BreakIterator!=null&&s.Intl.Segmenter!=null}', 'return s.Intl.Segmenter!=null}')
  $updated = $updated.Replace(
    "s($,\"bTu\",\"bt2\",()=>{var q=\"v8BreakIterator\"`nif(A.Z(A.Z(A.rP(),\"Intl\"),q)==null)A.a8(A.e5(\"v8BreakIterator is not supported.\"))`nreturn A.bGC(A.V3(A.V3(A.rP(),\"Intl\"),q),A.byq([]),A.bjj(B.a5F))})",
    's($,"bTu","bt2",()=>A.boA("word"))'
  )

  if ($updated -ne $content) {
    Set-Content -Path $relativePath -Value $updated -NoNewline
    Write-Host "Patched $relativePath"
  }
}