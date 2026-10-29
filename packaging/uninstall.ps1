# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Yukishiro

# -FromSettings: Windows の「設定 → アプリ」から実行したとき (画面が無いので、結果をメッセージボックスで知らせる)
param([switch]$FromSettings)

$ErrorActionPreference = 'Stop'

# Galtype のアンインストール。設定と学習データ (%LOCALAPPDATA%\Galtype) も消す。
# zip の Uninstall.cmd からも、インストール先にコピーしたもの (設定 → アプリ から) からも動く。

function Say([string]$message) {
    if ($FromSettings) { (New-Object -ComObject WScript.Shell).Popup($message, 0, 'Galtype', 0x40) | Out-Null }
    else { Write-Host $message }
}

# インストール先 (このスクリプトがある場所かもしれない) を消せるように、別の場所に移っておく。
Set-Location -LiteralPath $env:TEMP

# 動いている Galtype を止める。管理者として動いている Galtype は Stop-Process では止められないので、
# まず Galtype.exe --exit で終了の合図を送る (新しい版の Galtype なら、権限に関係なく終了する)。
function Stop-Galtype {
    $installed = Join-Path $env:LOCALAPPDATA 'Programs\Galtype\Galtype.exe'
    if ((Get-Process Galtype -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $installed)) {
        Start-Process -FilePath $installed -ArgumentList '--exit' -Wait -ErrorAction SilentlyContinue
        for ($i = 0; $i -lt 30 -and (Get-Process Galtype -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Milliseconds 100 }
    }
    foreach ($process in Get-Process Galtype -ErrorAction SilentlyContinue) {
        try {
            $process | Stop-Process -Force -ErrorAction Stop
        }
        catch {
            Say "Galtype を終了できませんでした (管理者として動いているのかもしれません)。`nタスクトレイの Galtype のアイコンを右クリックして「終了」を選んでから、もう一度アンインストールしてください。"
            exit 1
        }
    }
    Start-Sleep -Milliseconds 300
}

Stop-Galtype

# Galtype IME の登録を外す (インストール先を消す前に。管理者権限の確認が出る)
$imeScript = Join-Path $env:LOCALAPPDATA 'Programs\Galtype\galtype-ime.ps1'
if (-not (Test-Path -LiteralPath $imeScript)) { $imeScript = Join-Path $PSScriptRoot 'app\galtype-ime.ps1' }
if (Test-Path -LiteralPath $imeScript) {
    . $imeScript
    if (-not (Uninstall-GaltypeIme)) { Say "Galtype IME の登録を外せませんでした。管理者として、次を実行してください:`n%SystemRoot%\System32\regsvr32 /u `"$GaltypeProgramFiles\Galtype\tip\x64\GaltypeTip.dll`"`n%SystemRoot%\SysWOW64\regsvr32 /u `"$GaltypeProgramFiles\Galtype\tip\x86\GaltypeTip.dll`"" }
}

# サインインしたらすぐ起動するタスク (Galtype が作る: #283)。PATH に System32 が無い PC もあるので、フルパスで起動する
$system = [Environment]::SystemDirectory
& "$system\cmd.exe" /c "`"$system\schtasks.exe`" /Delete /TN Galtype /F >nul 2>&1"

foreach ($name in 'Galtype.lnk') {
    $shortcut = Join-Path ([Environment]::GetFolderPath('Startup')) $name
    if (Test-Path -LiteralPath $shortcut) { Remove-Item -LiteralPath $shortcut -Force }
}
$shortcut = Join-Path ([Environment]::GetFolderPath('Programs')) 'Galtype.lnk'
if (Test-Path -LiteralPath $shortcut) { Remove-Item -LiteralPath $shortcut -Force }

$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Galtype'
if (Test-Path -LiteralPath $key) { Remove-Item -LiteralPath $key -Recurse -Force }

foreach ($folder in 'Programs\Galtype', 'Galtype' | ForEach-Object { Join-Path $env:LOCALAPPDATA $_ }) {
    if (Test-Path -LiteralPath $folder) { Remove-Item -LiteralPath $folder -Recurse -Force }
}
Say 'Galtype をアンインストールしました (設定と学習データも削除しました)。'
