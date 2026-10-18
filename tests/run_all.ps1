# Ejecuta todas las pruebas automaticas del juego (sin abrir ventana).
# Uso (desde la carpeta del proyecto):  powershell -ExecutionPolicy Bypass -File tests/run_all.ps1
#
# Las pruebas usan la carpeta de datos del juego, asi que este script respalda tu partida guardada
# antes de empezar y la restaura al terminar.

$ErrorActionPreference = "Continue"
$project = Split-Path -Parent $PSScriptRoot
$godot = (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "Godot*console.exe" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
if (-not $godot) { $godot = (Get-Command godot_console -ErrorAction SilentlyContinue).Source }
if (-not $godot) { Write-Host "No encuentro Godot (consola). Instalalo con: winget install GodotEngine.GodotEngine"; exit 1 }

$userData = Join-Path $env:APPDATA "Godot\app_userdata\Pompon Friends"
$backup = Join-Path $env:TEMP "pompon_save_backup"
if (Test-Path $backup) { Remove-Item $backup -Recurse -Force }
New-Item -ItemType Directory -Force $backup | Out-Null
if (Test-Path $userData) { Get-ChildItem $userData -Filter "save.json*" | Copy-Item -Destination $backup }

Push-Location $project
& $godot --headless --path . --import --quit 2>&1 | Out-Null
$failed = 0
foreach ($test in Get-ChildItem "tests" -Filter "test_*.gd" | Sort-Object Name) {
    if (Test-Path $userData) { Remove-Item (Join-Path $userData "save.json*") -ErrorAction SilentlyContinue }
    $out = & $godot --headless --path . --script $test.FullName --quit-after 6000 2>&1 | ForEach-Object { "$_" }
    # solo cuenta errores reales del motor o del codigo (no el texto de las pruebas)
    $errors = $out | Where-Object { $_ -match "SCRIPT ERROR|Parse Error|Compile Error|Nonexistent function|Invalid (call|access)" }
    $status = if ($errors) { "FALLO" } else { "ok" }
    if ($errors) { $failed++ }
    "{0,-18} {1}" -f $test.BaseName, $status
    $errors | Select-Object -First 3 | ForEach-Object { "    $_" }
}
Pop-Location

if (Test-Path $userData) { Remove-Item (Join-Path $userData "save.json*") -ErrorAction SilentlyContinue }
Get-ChildItem $backup | Copy-Item -Destination $userData -ErrorAction SilentlyContinue
if ($failed -eq 0) { "`nTodas las pruebas pasaron." } else { "`n$failed prueba(s) con errores." }
