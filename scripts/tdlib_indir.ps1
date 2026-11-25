# Windows (PowerShell) version of scripts/tdlib_indir.sh: downloads TDLib built
# from Telegram's official source by this repository's "TDLib Android" workflow,
# verifies its SHA256 and places it into the Android project (jniLibs +
# org.drinkless.tdlib Java sources). Both are git-ignored; run once in a fresh
# clone before building.
#
# tdlib_indir.sh'in Windows sürümü. Resmi kaynaktan derlenen TDLib'i indirir,
# SHA256'sını doğrular ve Android projesine yerleştirir. Git Bash gerekmez.
#
#   powershell -ExecutionPolicy Bypass -File scripts\tdlib_indir.ps1

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# tdlib_indir.sh ile aynı tutulmalı.
$Tag = 'tdlib-1.8.68-c15d3f5'
$Repo = 'lemuxon/mesa'
$File = 'tdlib-android-1.8.68.zip'

$Root = Split-Path -Parent $PSScriptRoot
$Tmp = Join-Path ([IO.Path]::GetTempPath()) ("tdlib-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $Tmp | Out-Null

try {
    $Base = "https://github.com/$Repo/releases/download/$Tag"
    Invoke-WebRequest -UseBasicParsing -Uri "$Base/$File" -OutFile (Join-Path $Tmp $File)
    Invoke-WebRequest -UseBasicParsing -Uri "$Base/$File.sha256" -OutFile (Join-Path $Tmp "$File.sha256")

    # .sha256 dosyası "<özet>  <dosya adı>" biçiminde (sha256sum çıktısı).
    $expected = ((Get-Content (Join-Path $Tmp "$File.sha256") -Raw).Trim() -split '\s+')[0].ToLowerInvariant()
    $actual = (Get-FileHash (Join-Path $Tmp $File) -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($expected -notmatch '^[0-9a-f]{64}$' -or $actual -ne $expected) {
        throw "SHA256 eşleşmedi: beklenen $expected, inen $actual"
    }
    Write-Host "${File}: OK"

    $x = Join-Path $Tmp 'x'
    Expand-Archive -Path (Join-Path $Tmp $File) -DestinationPath $x

    $jni = Join-Path $Root 'android\app\src\main\jniLibs'
    $java = Join-Path $Root 'android\app\src\main\java\org\drinkless'
    foreach ($dir in @($jni, $java)) {
        if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
    }
    New-Item -ItemType Directory -Force -Path $jni, (Split-Path -Parent $java) | Out-Null
    Copy-Item -Recurse -Path (Join-Path $x 'tdlib\libs\*') -Destination $jni
    Copy-Item -Recurse -Path (Join-Path $x 'tdlib\java\org\drinkless') -Destination $java

    Write-Host "TDLib ($Tag) installed:"
    Get-ChildItem $jni -Recurse -Filter '*.so' | ForEach-Object {
        '{0,12:N0}  {1}' -f $_.Length, $_.FullName.Substring($Root.Length + 1)
    }
    Get-ChildItem (Join-Path $java 'tdlib') | ForEach-Object {
        '{0,12:N0}  {1}' -f $_.Length, $_.FullName.Substring($Root.Length + 1)
    }
}
finally {
    Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}
