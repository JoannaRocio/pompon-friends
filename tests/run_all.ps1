# Ejecuta todas las pruebas automaticas del juego (sin abrir ventana) y compara lo que imprimen con lo esperado.
# Uso (desde la carpeta del proyecto):
#   powershell -ExecutionPolicy Bypass -File tests/run_all.ps1                       todas las pruebas
#   powershell -ExecutionPolicy Bypass -File tests/run_all.ps1 -Only test_friends,test_save
#   powershell -ExecutionPolicy Bypass -File tests/run_all.ps1 -Update [-Runs 3] [-Only ...]
#
# Cada prueba (tests/test_*.gd) imprime lo que comprueba. Una prueba FALLA si:
#   - aparece un error del motor o del codigo (SCRIPT ERROR, Parse Error, Invalid call...),
#   - imprime una linea con "FALLA" (convencion para pruebas nuevas: print("FALLA: lo que salio mal")),
#   - o falta alguna de las lineas esperadas de tests/expected/<prueba>.txt (en el mismo orden; un "*"
#     en la linea esperada vale por cualquier texto: se usa para lo que cambia solo, como codigos al azar).
# Lineas de mas no hacen fallar (se pueden agregar prints sin tocar lo esperado).
# Al terminar, el codigo de salida es 0 si todo paso y 1 si algo fallo. La salida completa de cada prueba
# queda en %TEMP%\pompon_tests\<prueba>.txt.
#
# -Update vuelve a escribir tests/expected/ con lo que imprimen hoy las pruebas: corre cada una -Runs veces
# y lo que cambia entre corridas se reemplaza por "*". Usarlo solo despues de revisar a mano que la salida
# es la correcta (y revisar el diff de tests/expected/ antes de hacer commit).
#
# Las pruebas usan la carpeta de datos del juego, asi que este script respalda tu partida guardada
# antes de empezar y la restaura al terminar.

param(
    [switch]$Update,
    [int]$Runs = 3,
    [string[]]$Only = @()
)

$ErrorActionPreference = "Continue"
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
$utf8 = New-Object Text.UTF8Encoding $false
$project = Split-Path -Parent $PSScriptRoot
$godot = (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "Godot*console.exe" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
if (-not $godot) { $godot = (Get-Command godot_console -ErrorAction SilentlyContinue).Source }
if (-not $godot) { Write-Host "No encuentro Godot (consola). Instalalo con: winget install GodotEngine.GodotEngine"; exit 1 }

$expectedDir = Join-Path $PSScriptRoot "expected"
$logDir = Join-Path $env:TEMP "pompon_tests"
New-Item -ItemType Directory -Force $logDir | Out-Null
$userData = Join-Path $env:APPDATA "Godot\app_userdata\Pompon Friends"
$backup = Join-Path $env:TEMP "pompon_save_backup"
if (Test-Path $backup) { Remove-Item $backup -Recurse -Force }
New-Item -ItemType Directory -Force $backup | Out-Null
if (Test-Path $userData) { Get-ChildItem $userData -Filter "save.json*" | Copy-Item -Destination $backup }

$engineError = "SCRIPT ERROR|Parse Error|Compile Error|Nonexistent function|Invalid (call|access)"

# Lo que imprime una prueba, sin el encabezado de Godot ni los avisos de memoria al salir (cambian solos).
function Invoke-Test($test) {
    if (Test-Path $userData) { Remove-Item (Join-Path $userData "save.json*") -ErrorAction SilentlyContinue }
    $raw = & $godot --headless --path . --script $test.FullName --quit-after 6000 2>&1 | ForEach-Object { "$_" }
    [IO.File]::WriteAllText((Join-Path $logDir ($test.BaseName + ".txt")), (($raw | ForEach-Object { $_ }) -join "`n"), $utf8)
    $out = New-Object System.Collections.Generic.List[string]
    $skipAt = $false
    foreach ($line in $raw) {
        $l = $line.TrimEnd()
        if ($skipAt -and $l -match "^\s+at: ") { $skipAt = $false; continue }
        $skipAt = $false
        if ($l -eq "" -or $l -match "^Godot Engine v") { continue }
        if ($l -match "^(WARNING|ERROR): .*(leaked|still in use)") { $skipAt = $true; continue }
        $out.Add($l)
    }
    return ,$out
}

# Una linea esperada con "*" (cualquier texto) contra una linea de verdad.
function Test-Glob([string]$pattern, [string]$line) {
    if (-not $pattern.Contains("*")) { return $pattern -ceq $line }
    $parts = $pattern.Split("*")
    if (-not $line.StartsWith($parts[0], [StringComparison]::Ordinal)) { return $false }
    $pos = $parts[0].Length
    for ($i = 1; $i -lt $parts.Length - 1; $i++) {
        $at = $line.IndexOf($parts[$i], $pos, [StringComparison]::Ordinal)
        if ($at -lt 0) { return $false }
        $pos = $at + $parts[$i].Length
    }
    $last = $parts[$parts.Length - 1]
    return ($line.Length - $pos -ge $last.Length) -and $line.EndsWith($last, [StringComparison]::Ordinal)
}

# Lo que cambia entre corridas pasa a ser "*" (por palabras; si cambia la cantidad, lo del medio).
function Merge-Lines([string[]]$variants) {
    $first = $variants[0]
    if (@($variants | Where-Object { $_ -cne $first }).Count -eq 0) { return $first }
    $split = $variants | ForEach-Object { , ($_ -split " ") }
    $n = $split[0].Length
    if (@($split | Where-Object { $_.Length -ne $n }).Count -eq 0) {
        $words = for ($i = 0; $i -lt $n; $i++) {
            $w = $split[0][$i]
            if (@($split | Where-Object { $_[$i] -cne $w }).Count -gt 0) { "*" } else { $w }
        }
        $merged = ($words -join " ")
    } else {
        $pre = $first.Length
        $suf = $first.Length
        foreach ($v in $variants) {
            $k = 0
            while ($k -lt $pre -and $k -lt $v.Length -and $v[$k] -ceq $first[$k]) { $k++ }
            $pre = $k
            $k = 0
            while ($k -lt $suf -and $k -lt $v.Length -and $v[$v.Length - 1 - $k] -ceq $first[$first.Length - 1 - $k]) { $k++ }
            $suf = $k
        }
        $suf = [Math]::Min($suf, $first.Length - $pre)
        $merged = $first.Substring(0, $pre) + "*" + $first.Substring($first.Length - $suf)
    }
    while ($merged.Contains("* *")) { $merged = $merged.Replace("* *", "*") }
    while ($merged.Contains("**")) { $merged = $merged.Replace("**", "*") }
    if (($merged -replace "[\*\s]", "").Length -lt 6) { return $null }   # casi todo cambia: no sirve de comprobacion
    return $merged
}

Push-Location $project
$env:POMPON_HOUR = "12"   # las pruebas corren al mediodia (no dependen de la hora real; test_night fija las suyas)
$env:POMPON_LANG = "es"   # y en español, sin importar el idioma de la PC (test_locale cambia el idioma a mano)
& $godot --headless --path . --import --quit 2>&1 | Out-Null
if ($Update) { New-Item -ItemType Directory -Force $expectedDir | Out-Null }
$failed = 0
$tests = Get-ChildItem "tests" -Filter "test_*.gd" | Sort-Object Name
$Only = @($Only | ForEach-Object { $_ -split "," } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })   # (con -File llega "a,b" junto)
if ($Only.Count -gt 0) { $tests = @($tests | Where-Object { $Only -contains $_.BaseName }) }
foreach ($test in $tests) {
    $outs = @()
    $count = if ($Update) { [Math]::Max(1, $Runs) } else { 1 }
    for ($r = 0; $r -lt $count; $r++) { $outs += , (Invoke-Test $test) }
    $problems = New-Object System.Collections.Generic.List[string]
    foreach ($out in $outs) {
        $out | Where-Object { $_ -match $engineError } | Select-Object -First 3 | ForEach-Object { $problems.Add("error: $_") }
        $out | Where-Object { $_ -cmatch "FALLA" } | Select-Object -First 3 | ForEach-Object { $problems.Add("$_") }
    }
    $expectedFile = Join-Path $expectedDir ($test.BaseName + ".txt")
    if ($Update) {
        $lines = New-Object System.Collections.Generic.List[string]
        $sameCount = @($outs | Where-Object { $_.Count -ne $outs[0].Count }).Count -eq 0
        for ($i = 0; $i -lt $outs[0].Count; $i++) {
            $l = $outs[0][$i]
            if ($l -match $engineError -or $l -cmatch "FALLA") { continue }
            if ($sameCount) {
                $m = Merge-Lines @($outs | ForEach-Object { $_[$i] })
            } else {   # cambio la cantidad de lineas: solo quedan las que salieron igual en todas las corridas
                $m = if (@($outs | Where-Object { -not $_.Contains($l) }).Count -eq 0) { $l } else { $null }
            }
            if ($m) { $lines.Add($m) }
        }
        [IO.File]::WriteAllText($expectedFile, (($lines | ForEach-Object { $_ }) -join "`n") + "`n", $utf8)
        $note = "{0} lineas esperadas" -f $lines.Count
    } elseif (Test-Path $expectedFile) {
        $out = $outs[0]
        $pos = 0
        $missing = 0
        foreach ($pattern in [IO.File]::ReadAllLines($expectedFile, $utf8)) {
            if ($pattern.Trim() -eq "") { continue }
            $found = -1
            for ($j = $pos; $j -lt $out.Count; $j++) { if (Test-Glob $pattern $out[$j]) { $found = $j; break } }
            if ($found -ge 0) { $pos = $found + 1; continue }
            $missing++
            if ($missing -le 3) {
                # la linea de verdad que mas se parece (la que empieza igual por mas letras)
                $best = ""; $bestLen = -1
                foreach ($a in $out) {
                    $k = 0
                    while ($k -lt $a.Length -and $k -lt $pattern.Length -and $a[$k] -ceq $pattern[$k]) { $k++ }
                    if ($k -gt $bestLen) { $bestLen = $k; $best = $a }
                }
                $problems.Add("esperado: $pattern")
                $problems.Add("   salio: $best")
            }
        }
        if ($missing -gt 3) { $problems.Add("... y $($missing - 3) linea(s) esperada(s) mas que no salieron") }
        $note = ""
    } else {
        $note = "(sin tests/expected: solo se miran los errores)"
    }
    $status = if ($problems.Count -gt 0) { "FALLO" } else { "ok" }
    if ($problems.Count -gt 0) { $failed++ }
    "{0,-22} {1} {2}" -f $test.BaseName, $status, $note
    $problems | Select-Object -First 8 | ForEach-Object { "    $_" }
}
Pop-Location

if (Test-Path $userData) { Remove-Item (Join-Path $userData "save.json*") -ErrorAction SilentlyContinue }
Get-ChildItem $backup | Copy-Item -Destination $userData -ErrorAction SilentlyContinue
"`nSalida completa de cada prueba: $logDir"
if ($failed -eq 0) { "Todas las pruebas pasaron."; exit 0 } else { "$failed prueba(s) con errores."; exit 1 }
