# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Yukishiro

# -Ask: Install.cmd から自分で実行したとき。前に Galtype IME の登録を断っていても、もう一度聞く (自動更新では聞かない)
param([switch]$Ask)

$ErrorActionPreference = 'Stop'

# Galtype のインストール。ビルド済みの app フォルダーを %LOCALAPPDATA%\Programs\Galtype にコピーし、
# スタートアップとスタートメニューに登録して起動する。管理者権限は不要 (Galtype IME を登録するときだけ UAC で求める)。.NET は app の dotnet フォルダーに同梱しているので、インストール不要。

$source = Join-Path $PSScriptRoot 'app'
$target = Join-Path $env:LOCALAPPDATA 'Programs\Galtype'
$exe = Join-Path $target 'Galtype.exe'

# zip の中身がそろっているか (展開の途中で止まった・app フォルダーを差し替えた などで Galtype.exe が無いと、起動のところで分かりにくいエラーになる)
if (-not (Test-Path -LiteralPath (Join-Path $source 'Galtype.exe'))) {
    Write-Host "インストールするファイルが見つかりません: $(Join-Path $source 'Galtype.exe')"
    Write-Host 'zip をすべて展開し直してから、展開したフォルダーの Install.cmd を実行してください。'
    exit 1
}

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
            Write-Host 'Galtype を終了できませんでした (管理者として動いているのかもしれません)。'
            Write-Host 'タスクトレイの Galtype のアイコンを右クリックして「終了」を選んでから、もう一度実行してください。'
            exit 1
        }
    }
    Start-Sleep -Milliseconds 300
}

Stop-Galtype

New-Item -ItemType Directory -Force -Path $target | Out-Null
Copy-Item -Path (Join-Path $source '*') -Destination $target -Recurse -Force

# コピーした直後にウイルス対策ソフトが Galtype.exe を隔離することがある。誤検知かどうかはここでは判断できない。
if (-not (Test-Path -LiteralPath $exe)) {
    Write-Host "コピーした Galtype.exe が見つかりません: $exe"
    Write-Host 'ウイルス対策ソフトが Galtype を止めた可能性があります。'
    Write-Host 'Windows セキュリティ →「ウイルスと脅威の防止」→「保護の更新」で定義を更新し、公式の ZIP を再ダウンロードして再検査してください。'
    Write-Host 'Windows セキュリティ →「ウイルスと脅威の防止」→「保護の履歴」で検出名を確認してください。誤検知かどうかは、この状態だけでは判断できません。'
    Write-Host '保護を無効にしたり「許可」に変更したりせず、版と検出名を https://github.com/oto-lab/Galtype/issues に報告してください (個人名やパスは隠してください)。'
    exit 1
}

# インターネットから落とした印 (Zone.Identifier) はコピーにも付いてくるので外す (起動時の SmartScreen の確認を減らす)
Get-ChildItem -LiteralPath $target -Recurse -File | Unblock-File -ErrorAction SilentlyContinue

# Windows の「設定 → アプリ → インストールされているアプリ」からアンインストールできるようにする。
# 前は zip を展開したフォルダーの Uninstall.cmd しか無く、zip を消していると探し直す手間がかかった。
$uninstaller = Join-Path $target 'uninstall.ps1'
$uninstallSource = Join-Path $PSScriptRoot 'uninstall.ps1'
# インストーラー (Galtype-<版>-setup.exe) で入れていたら、その「設定 → アプリ」の項目の版だけ新しくする
# (自動更新もこのスクリプトを使うので、項目が二重にならないように)。
$innoKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Galtype_is1'
if ((Test-Path -LiteralPath $innoKey) -and (Test-Path -LiteralPath (Join-Path $target 'unins000.exe'))) {
    $version = (Get-Item -LiteralPath $exe).VersionInfo.ProductVersion
    Set-ItemProperty -Path $innoKey -Name DisplayVersion -Value $version
    Set-ItemProperty -Path $innoKey -Name DisplayName -Value 'Galtype'
}
elseif (Test-Path -LiteralPath $uninstallSource) {
    Copy-Item -LiteralPath $uninstallSource -Destination $uninstaller -Force
    Unblock-File -LiteralPath $uninstaller -ErrorAction SilentlyContinue
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Galtype'
    New-Item -Path $key -Force | Out-Null
    $size = [int]((Get-ChildItem -LiteralPath $target -Recurse -File | Measure-Object Length -Sum).Sum / 1KB)
    $values = @{
        DisplayName     = 'Galtype'
        DisplayVersion  = (Get-Item -LiteralPath $exe).VersionInfo.ProductVersion
        Publisher       = 'oto-lab'
        DisplayIcon     = $exe
        InstallLocation = $target
        # PATH に PowerShell のフォルダーが無い PC もあるので、フルパスで書く
        UninstallString = "`"$(Join-Path ([Environment]::GetFolderPath('Windows')) 'System32\WindowsPowerShell\v1.0\powershell.exe')`" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$uninstaller`" -FromSettings"
        URLInfoAbout    = 'https://github.com/oto-lab/Galtype'
    }
    foreach ($name in $values.Keys) { Set-ItemProperty -Path $key -Name $name -Value $values[$name] }
    foreach ($name in 'NoModify', 'NoRepair') { Set-ItemProperty -Path $key -Name $name -Value 1 -Type DWord }
    Set-ItemProperty -Path $key -Name EstimatedSize -Value $size -Type DWord
}

# Galtype IME (入力欄に直接入力)。登録には管理者権限が要る。断られたら、今までどおり変換ボックスで入力する方式で使う
$imeScript = Join-Path $target 'galtype-ime.ps1'
if ((Test-Path -LiteralPath $imeScript) -and (Test-Path -LiteralPath (Join-Path $target 'tip'))) {
    # 失敗しても、ショートカットを作って Galtype を起動するところまでは続ける (自動更新で Galtype が止まったままにならないように)
    try {
        . $imeScript
        # 自分で実行したとき (-Ask) か、もう登録してある (DLL を入れ替える) ときだけ。頼まれていないのに管理者権限の確認を出さない
        if ($Ask -or (Test-GaltypeImeRegistered)) { Install-GaltypeIme -Source (Join-Path $target 'tip') -Ask:$Ask | Out-Null }
    }
    catch {
        Write-Host "Galtype IME を登録できませんでした (変換ボックスで入力する方式で使えます): $($_.Exception.Message)"
    }
}

# 自動起動と、スタートメニュー・Windows 検索からの起動用 (現在のユーザー)
$shell = New-Object -ComObject WScript.Shell
foreach ($folderName in 'Startup', 'Programs') {
    $folder = [Environment]::GetFolderPath($folderName)
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
    $shortcut = $shell.CreateShortcut((Join-Path $folder 'Galtype.lnk'))
    $shortcut.TargetPath = $exe
    $shortcut.WorkingDirectory = $target
    $shortcut.IconLocation = "$exe,0"
    $shortcut.Description = 'Galtype: 日本語と英語を自動で打ち分ける'
    $shortcut.Save()
}

# 管理者として実行していても、Galtype はふつうの権限で起動する (エクスプローラーから起動すると、ふつうの権限になる)。
# 管理者として動かすと、次のインストール・アンインストールでも管理者権限が必要になってしまう。
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($admin) { Start-Process -FilePath explorer.exe -ArgumentList "`"$exe`"" }
else { Start-Process -FilePath $exe -WorkingDirectory $target }
Write-Host 'Galtype をインストールして起動しました。画面右下のタスクトレイに「あ」のアイコンが出ます。'
