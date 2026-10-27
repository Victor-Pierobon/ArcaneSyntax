# Build da Alpha para Windows (spec BLD-alpha): exporta o jogo, põe o executor e o Python embutido
# enxuto ao lado do .exe, roda o teste de fumaça no jogo exportado e gera o .zip.
# Uso (PowerShell, na raiz do repositório):
#   $env:GODOT_BIN = "C:\...\Godot_v4.7.2-stable_win64_console.exe"
#   .\scripts\build_windows.ps1
# Precisa dos templates de exportação do Godot 4.7.2 e do runtime/python (scripts/fetch_python.sh).
param([string]$Godot = $env:GODOT_BIN)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root "build\ArcaneSyntax"
$zip = Join-Path $root "build\ArcaneSyntax-alpha.zip"

if (-not $Godot -or -not (Test-Path $Godot)) { throw "Defina GODOT_BIN com o Godot 4.7.2 (_console.exe)." }
if (-not (Test-Path (Join-Path $root "runtime\python\python.exe"))) { throw "Falta runtime\python: rode scripts/fetch_python.sh." }

Write-Host "== Pasta limpa: $out"
if (Test-Path $out) { Remove-Item -Recurse -Force $out }
if (Test-Path $zip) { Remove-Item -Force $zip }
New-Item -ItemType Directory -Force $out | Out-Null

Write-Host "== Exportando"
$ErrorActionPreference = "Continue"
& $Godot --headless --path (Join-Path $root "game") --import 2>&1 | Out-Null
& $Godot --headless --path (Join-Path $root "game") --export-release "Windows Desktop" (Join-Path $out "ArcaneSyntax.exe") 2>&1 |
    ForEach-Object { "$_" } | Where-Object { $_ -match "ERROR" }
$ErrorActionPreference = "Stop"
if (-not (Test-Path (Join-Path $out "ArcaneSyntax.pck"))) { throw "A exportação não gerou o ArcaneSyntax.pck." }

Write-Host "== Executor"
$executor = Join-Path $out "executor"
New-Item -ItemType Directory -Force $executor | Out-Null
Copy-Item (Join-Path $root "executor\run_worker.py") $executor
Copy-Item -Recurse (Join-Path $root "executor\arcane_executor") $executor
Get-ChildItem -Recurse -Directory -Filter "__pycache__" $executor | Remove-Item -Recurse -Force

Write-Host "== Python embutido (enxuto)"
$python = Join-Path $out "runtime\python"
New-Item -ItemType Directory -Force (Split-Path $python) | Out-Null
Copy-Item -Recurse (Join-Path $root "runtime\python") $python
$cut = @("include", "libs", "Scripts", "tcl", "Lib\site-packages", "Lib\ensurepip", "Lib\idlelib", "Lib\tkinter",
         "Lib\turtledemo", "Lib\venv", "Lib\test")
foreach ($dir in $cut) {
    $path = Join-Path $python $dir
    if (Test-Path $path) { Remove-Item -Recurse -Force $path }
}
Get-ChildItem (Join-Path $python "DLLs") -File | Where-Object { $_.Name -match "^(_tkinter|tcl|tk)" } | Remove-Item -Force

Copy-Item (Join-Path $root "docs\build\LEIA-ME.txt") $out

Write-Host "== Teste de fumaça no jogo exportado"
# Avisos do Godot no stderr não são falha: quem decide é o código de saída.
$ErrorActionPreference = "Continue"
& (Join-Path $out "ArcaneSyntax.console.exe") --headless -- --fumaca 2>&1 | ForEach-Object { "$_" }
$code = $LASTEXITCODE
$ErrorActionPreference = "Stop"
if ($code -ne 0) { throw "A fumaça falhou (código $code); o .zip não foi gerado." }

Write-Host "== Zip"
Compress-Archive -Path $out -DestinationPath $zip
$size = (Get-Item $zip).Length / 1MB
Write-Host ("Pronto: {0} ({1:N1} MB)" -f $zip, $size)
