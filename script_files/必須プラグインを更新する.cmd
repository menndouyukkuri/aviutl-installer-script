@powershell -NoProfile -ExecutionPolicy Unrestricted "$s=[scriptblock]::create((gc \"%~f0\"|?{$_.readcount -gt 1})-join\"`n\");&$s" %*&goto:eof

#
#   MIT License
#
#   Copyright (c) 2025 menndouyukkuri
#
#   Permission is hereby granted, free of charge, to any person obtaining a copy
#   of this software and associated documentation files (the "Software"), to deal
#   in the Software without restriction, including without limitation the rights
#   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#   copies of the Software, and to permit persons to whom the Software is
#   furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included in all
#   copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#   SOFTWARE.
#

# GitHubリポジトリの最新版リリースのダウンロードURLを取得する
function GithubLatestReleaseUrl ($repo) {
    # GitHubのAPIから最新版リリースの情報を取得する
    $api = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest"

    # 最新版リリースのダウンロードURLのみを返す
    return($api.assets.browser_download_url)
}

Write-Host "必須プラグイン (patch.aul・L-SMASH Works・InputPipePlugin・x264guiEx) の更新を開始します。`r`n`r`n"

# カレントディレクトリのパスを $scriptFileRoot に保存 (起動方法のせいで $PSScriptRoot が使用できないため)
$scriptFileRoot = (Get-Location).Path

Write-Host -NoNewline "AviUtlがインストールされているフォルダを確認しています..."

# aviutl.exe が入っているディレクトリを探し、$aviutlExeDirectory にパスを保存
if (Test-Path "C:\AviUtl\aviutl.exe") {
    Write-Host "完了"
    $aviutlExeDirectory = "C:\AviUtl"
} elseif (Test-Path "C:\Applications\AviUtl\aviutl.exe") {
    Write-Host "完了"
    $aviutlExeDirectory = "C:\Applications\AviUtl"
} else { # 確認できなかった場合、ユーザーにパスを入力させる
    # ユーザーにパスを入力させ、aviutl.exe が入っていることを確認したらループを抜ける
    New-Variable checkInputAviutlExePath # ループを抜けても使用するため先に宣言
    do {
        Write-Host "完了"
        Write-Host "AviUtlがインストールされているフォルダが確認できませんでした。`r`n"

        Write-Host "aviutl.exe のパス、または aviutl.exe が入っているフォルダのパスを入力し、Enter を押してください。"
        $userInputAviutlExePath = Read-Host

        # ユーザーの入力をもとに aviutl.exe のパスを $checkInputAviutlExePath に代入
        if ($userInputAviutlExePath -match "\\aviutl\.exe") {
            $checkInputAviutlExePath = $userInputAviutlExePath
        } else {
            $checkInputAviutlExePath = $userInputAviutlExePath + "\aviutl.exe"
        }

        Write-Host -NoNewline "`r`nAviUtlがインストールされているフォルダを確認しています..."
    } while (!(Test-Path $checkInputAviutlExePath))
    Write-Host "完了"

    # パスを \aviutl.exe を消去してから $aviutlExeDirectory に保存
    $aviutlExeDirectory = $checkInputAviutlExePath -replace "\\aviutl\.exe", ""
}

Start-Sleep -Milliseconds 500

Write-Host -NoNewline "`r`n一時的にファイルを保管するフォルダを作成しています..."

# AviUtl ディレクトリ内に plugins, script, license, readme の4つのディレクトリを作成する (待機)
$aviutlPluginsDirectory = $aviutlExeDirectory + "\plugins"
$aviutlScriptDirectory = $aviutlExeDirectory + "\script"
$LicenseDirectoryRoot = $aviutlExeDirectory + "\license"
$ReadmeDirectoryRoot = $aviutlExeDirectory + "\readme"
Start-Process powershell -ArgumentList "-command New-Item $aviutlPluginsDirectory, $aviutlScriptDirectory, $LicenseDirectoryRoot, $ReadmeDirectoryRoot -ItemType Directory -Force" -WindowStyle Minimized -Wait

# tmp ディレクトリを作成する (待機)
Start-Process powershell -ArgumentList "-command New-Item tmp -ItemType Directory -Force" -WindowStyle Minimized -Wait

Write-Host "完了"
Write-Host -NoNewline "`r`n拡張編集Pluginのインストールされているディレクトリを確認しています..."

# 拡張編集Pluginが plugins ディレクトリ内にある場合、AviUtl ディレクトリ内に移動させる (エラーの防止)
$exeditAufPluginsPath = $aviutlPluginsDirectory + "\exedit.auf"
if (Test-Path $exeditAufPluginsPath) {
    # カレントディレクトリを plugins ディレクトリに変更
    Set-Location $aviutlPluginsDirectory

    # 拡張編集Pluginのファイルを全て AviUtl ディレクトリ内に移動
    Move-Item "exedit.*" $aviutlExeDirectory -Force
    Move-Item lua51.dll $aviutlExeDirectory -Force
    $luaTxtPluginsPath = $aviutlPluginsDirectory + "\lua.txt"
    if (Test-Path $luaTxtPluginsPath) {
        Move-Item lua.txt $aviutlExeDirectory -Force
    }

    # カレントディレクトリをスクリプトファイルのあるディレクトリに変更
    Set-Location $scriptFileRoot
}

# カレントディレクトリを tmp ディレクトリに変更
Set-Location tmp

Write-Host "完了"
Write-Host -NoNewline "`r`npatch.aul (謎さうなフォーク版) の最新版情報を取得しています..."

# patch.aul (謎さうなフォーク版) の最新版のダウンロードURLを取得
$patchAulUrl = GithubLatestReleaseUrl "nazonoSAUNA/patch.aul"

Write-Host "完了"
Write-Host -NoNewline "patch.aul (謎さうなフォーク版) をダウンロードしています..."

# patch.aul (謎さうなフォーク版) のzipファイルをダウンロード (待機)
Start-Process curl.exe -ArgumentList "-OL $patchAulUrl" -WindowStyle Minimized -Wait

Write-Host "完了"
Write-Host -NoNewline "patch.aul (謎さうなフォーク版) をインストールしています..."

# patch.aulのzipファイルを展開 (待機)
Start-Process powershell -ArgumentList "-command Expand-Archive -Path patch.aul_*.zip -Force" -WindowStyle Minimized -Wait

# カレントディレクトリをpatch.aulのzipファイルを展開したディレクトリに変更
Set-Location "patch.aul_*"

# AviUtl\license 内に patch-aul ディレクトリを作成 (待機)
$patchAulLicenseDirectory = $LicenseDirectoryRoot + "\patch-aul"
Start-Process powershell -ArgumentList "-command New-Item $patchAulLicenseDirectory -ItemType Directory -Force" -WindowStyle Minimized -Wait

# patch.aul が plugins ディレクトリ内にある場合、削除して patch.aul.json を移動させる (エラーの防止)
$patchAulPluginsPath = $aviutlPluginsDirectory + "\patch.aul"
if (Test-Path $patchAulPluginsPath) {
    Remove-Item $patchAulPluginsPath
    $patchAulJsonPath = $aviutlExeDirectory + "\patch.aul.json"
    $patchAulJsonPluginsPath = $aviutlPluginsDirectory + "\patch.aul.json"
    if ((Test-Path $patchAulJsonPluginsPath) -and (!(Test-Path $patchAulJsonPath))) {
        Move-Item $patchAulJsonPluginsPath $aviutlExeDirectory -Force
    } elseif (Test-Path $patchAulJsonPluginsPath) {
        Remove-Item $patchAulJsonPluginsPath
    }
}

# AviUtl ディレクトリ内に patch.aul を (待機) 、AviUtl\license\patch-aul 内にその他のファイルをそれぞれ移動
Start-Process powershell -ArgumentList "-command Move-Item patch.aul $aviutlExeDirectory -Force" -WindowStyle Minimized -Wait
Move-Item * $patchAulLicenseDirectory -Force

# カレントディレクトリを tmp ディレクトリに変更
Set-Location ..

Write-Host "完了"
Write-Host -NoNewline "`r`nL-SMASH Works (Mr-Ojii版) の最新版情報を取得しています..."

# L-SMASH Works (Mr-Ojii版) の最新版のダウンロードURLを取得
$lSmashWorksAllUrl = GithubLatestReleaseUrl "Mr-Ojii/L-SMASH-Works-Auto-Builds"

# 複数ある中からAviUtl用のもののみ残す
$lSmashWorksUrl = $lSmashWorksAllUrl | Where-Object {$_ -like "*Mr-Ojii_vimeo*"}

Write-Host "完了"
Write-Host -NoNewline "L-SMASH Works (Mr-Ojii版) をダウンロードしています..."

# L-SMASH Works (Mr-Ojii版) のzipファイルをダウンロード (待機)
Start-Process curl.exe -ArgumentList "-OL $lSmashWorksUrl" -WindowStyle Minimized -Wait

Write-Host "完了"
Write-Host -NoNewline "L-SMASH Works (Mr-Ojii版) をインストールしています..."

# AviUtl\license\l-smash_works 内に Licenses ディレクトリがあれば削除する (エラーの防止)
$lSmashWorksLicenseDirectoryLicenses = $LicenseDirectoryRoot + "\l-smash_works\Licenses"
if (Test-Path $lSmashWorksLicenseDirectoryLicenses) {
    Remove-Item $lSmashWorksLicenseDirectoryLicenses -Recurse
}

# AviUtl ディレクトリや plugins ディレクトリ内に lwi ディレクトリがあれば中の .lwi ファイルを削除する (エラーの防止)
$aviutlExelwiDirectory = $aviutlExeDirectory + "\lwi"
if (Test-Path $aviutlExelwiDirectory) {
    Set-Location $aviutlExelwiDirectory
    if (Test-Path "*.lwi") {
        Remove-Item "*.lwi"
    }

    # カレントディレクトリを tmp ディレクトリに変更
    Set-Location $scriptFileRoot
    Set-Location tmp
}
$aviutlPluginslwiDirectory = $aviutlPluginsDirectory + "\lwi"
if (Test-Path $aviutlPluginslwiDirectory) {
    Set-Location $aviutlPluginslwiDirectory
    if (Test-Path "*.lwi") {
        Remove-Item "*.lwi"
    }

    # カレントディレクトリを tmp ディレクトリに変更
    Set-Location $scriptFileRoot
    Set-Location tmp
}

# L-SMASH Worksのzipファイルを展開 (待機)
Start-Process powershell -ArgumentList "-command Expand-Archive -Path L-SMASH-Works_*.zip -Force" -WindowStyle Minimized -Wait

# カレントディレクトリをL-SMASH Worksのzipファイルを展開したディレクトリに変更
Set-Location "L-SMASH-Works_*"

# AviUtl\readme, AviUtl\license 内に l-smash_works ディレクトリを作成 (待機)
$lSmashWorksReadmeDirectory = $ReadmeDirectoryRoot + "\l-smash_works"
$lSmashWorksLicenseDirectory = $LicenseDirectoryRoot + "\l-smash_works"
Start-Process powershell -ArgumentList "-command New-Item $lSmashWorksReadmeDirectory, $lSmashWorksLicenseDirectory -ItemType Directory -Force" -WindowStyle Minimized -Wait

# L-SMASH Worksの入っているディレクトリを探し、$lwinputAuiDirectory にパスを保存
# $inputPipePluginDeleteCheckDirectory は $lwinputAuiDirectory の逆、後に使用
$lwinputAuiTestPath = $aviutlExeDirectory + "\lwinput.aui"
New-Variable lwinputAuiDirectory
New-Variable inputPipePluginDeleteCheckDirectory
if (Test-Path $lwinputAuiTestPath) {
    $lwinputAuiDirectory = $aviutlExeDirectory
    $inputPipePluginDeleteCheckDirectory = $aviutlPluginsDirectory
} else {
    $lwinputAuiDirectory = $aviutlPluginsDirectory
    $inputPipePluginDeleteCheckDirectory = $aviutlExeDirectory
}

Start-Sleep -Milliseconds 500

# AviUtl\plugins ディレクトリ内に lw*.au* を、AviUtl\readme\l-smash_works 内に READM* を (待機) 、
# AviUtl\license\l-smash_works 内にその他のファイルをそれぞれ移動
Start-Process powershell -ArgumentList "-command Move-Item lw*.au* $lwinputAuiDirectory -Force; Move-Item READM* $lSmashWorksReadmeDirectory -Force" -WindowStyle Minimized -Wait
Move-Item * $lSmashWorksLicenseDirectory -Force

# カレントディレクトリを tmp ディレクトリに変更
Set-Location ..

Write-Host "完了"
Write-Host -NoNewline "`r`nInputPipePluginの最新版情報を取得しています..."

# InputPipePluginの最新版のダウンロードURLを取得
$InputPipePluginUrl = GithubLatestReleaseUrl "amate/InputPipePlugin"

Write-Host "完了"
Write-Host -NoNewline "InputPipePluginをダウンロードしています..."

# InputPipePluginのzipファイルをダウンロード (待機)
Start-Process curl.exe -ArgumentList "-OL $InputPipePluginUrl" -WindowStyle Minimized -Wait

Write-Host "完了"
Write-Host -NoNewline "InputPipePluginをインストールしています..."

# InputPipePluginのzipファイルを展開 (待機)
Start-Process powershell -ArgumentList "-command Expand-Archive -Path InputPipePlugin_*.zip -Force" -WindowStyle Minimized -Wait

# カレントディレクトリをInputPipePluginのzipファイルを展開したディレクトリに変更
Set-Location "InputPipePlugin_*\InputPipePlugin"

# AviUtl\readme, AviUtl\license 内に inputPipePlugin ディレクトリを作成 (待機)
$inputPipePluginReadmeDirectory = $ReadmeDirectoryRoot + "\inputPipePlugin"
$inputPipePluginLicenseDirectory = $LicenseDirectoryRoot + "\inputPipePlugin"
Start-Process powershell -ArgumentList "-command New-Item $inputPipePluginReadmeDirectory, $inputPipePluginLicenseDirectory -ItemType Directory -Force" -WindowStyle Minimized -Wait

# AviUtl\license\inputPipePlugin 内に LICENSE を、AviUtl\readme\inputPipePlugin 内に Readme.md を (待機) 、
# AviUtl\plugins ディレクトリ内にその他のファイルをそれぞれ移動
Start-Process powershell -ArgumentList "-command Move-Item LICENSE $inputPipePluginLicenseDirectory -Force; Move-Item Readme.md $inputPipePluginReadmeDirectory -Force" -WindowStyle Minimized -Wait
Move-Item * $lwinputAuiDirectory -Force

# トラブルの原因になるファイルの除去
Set-Location $inputPipePluginDeleteCheckDirectory
if (Test-Path "InputPipe*") {
    Remove-Item "InputPipe*"
}
Set-Location $scriptFileRoot

# カレントディレクトリを tmp ディレクトリに変更
Set-Location tmp

Write-Host "完了"
Write-Host -NoNewline "`r`nx264guiExの最新版情報を取得しています..."

# x264guiExの最新版のダウンロードURLを取得
$x264guiExUrl = GithubLatestReleaseUrl "rigaya/x264guiEx"

Write-Host "完了"
Write-Host -NoNewline "x264guiExをダウンロードしています..."

# x264guiExのzipファイルをダウンロード (待機)
Start-Process curl.exe -ArgumentList "-OL $x264guiExUrl" -WindowStyle Minimized -Wait

Write-Host "完了"
Write-Host -NoNewline "x264guiExをインストールしています。`r`n"

# x264guiExのzipファイルを展開 (待機)
Start-Process powershell -ArgumentList "-command Expand-Archive -Path x264guiEx_*.zip -Force" -WindowStyle Minimized -Wait

# カレントディレクトリをx264guiExのzipファイルを展開したディレクトリに変更
Set-Location "x264guiEx_*\x264guiEx_*"

# カレントディレクトリをx264guiExのzipファイルを展開したディレクトリ内の plugins ディレクトリに変更
Set-Location plugins

# AviUtl\plugins 内に現在のディレクトリのファイルをプロファイル以外全て移動
Move-Item "x264guiEx.*" $aviutlPluginsDirectory -Force
Move-Item auo_setup.auf -Force

# プロファイルを上書きするかどうかユーザーに確認する (既定は 上書きしない)
# 選択ここから

$x264guiExChoiceTitle = "x264guiExのプロファイルを上書きしますか？"
$x264guiExChoiceMessage = "プロファイルは更新で新しくなっている可能性がありますが、上書きを実行すると追加したプロファイルやプロファイルへの変更が削除されます。"

$x264guiExTChoiceDescription = "System.Management.Automation.Host.ChoiceDescription"
$x264guiExChoiceOptions = @(
    New-Object $x264guiExTChoiceDescription ("はい(&Y)",       "上書きを実行します。")
    New-Object $x264guiExTChoiceDescription ("いいえ(&N)",     "上書きをせず、スキップして次の処理に進みます。")
)

$x264guiExChoiceResult = $host.ui.PromptForChoice($x264guiExChoiceTitle, $x264guiExChoiceMessage, $x264guiExChoiceOptions, 1)
switch ($x264guiExChoiceResult) {
    0 {
        Write-Host -NoNewline "`r`nx264guiExのプロファイルを上書きします..."

        # AviUtl\plugins 内に x264guiEx_stg ディレクトリがあれば削除する
        $x264guiExStgDirectory = $aviutlPluginsDirectory + "\x264guiEx_stg"
        if (Test-Path $x264guiExStgDirectory) {
            Remove-Item $x264guiExStgDirectory -Recurse
        }

        # AviUtl\plugins 内に現在のディレクトリのファイルを全て移動
        Move-Item * $aviutlPluginsDirectory -Force

        Write-Host "完了"
        break
    }
    1 {
        Write-Host "`r`nx264guiExのプロファイルの上書きをスキップしました。"
        break
    }
}

# 選択ここまで

# カレントディレクトリをx264guiExのzipファイルを展開したディレクトリ内の exe_files ディレクトリに変更
Set-Location ..\exe_files

# AviUtl ディレクトリ内に exe_files ディレクトリを作成 (待機)
$exeFilesDirectory = $aviutlExeDirectory + "\exe_files"
Start-Process powershell -ArgumentList "-command New-Item $exeFilesDirectory -ItemType Directory -Force" -WindowStyle Minimized -Wait

# AviUtl\exe_files 内に x264_*.exe があれば削除 (待機)
Set-Location $exeFilesDirectory
Start-Process powershell -ArgumentList "-command if (Test-Path x264_*.exe) { Remove-Item x264_*.exe }" -WindowStyle Minimized -Wait
Set-Location $scriptFileRoot
Set-Location "tmp\x264guiEx_*\x264guiEx_*\exe_files"

# AviUtl\exe_files 内に現在のディレクトリのファイルを全て移動
Move-Item * $exeFilesDirectory -Force

# カレントディレクトリをx264guiExのzipファイルを展開したディレクトリに変更
Set-Location ..

# AviUtl\readme 内に x264guiEx ディレクトリを作成 (待機)
$x264guiExReadmeDirectory = $ReadmeDirectoryRoot + "\x264guiEx"
Start-Process powershell -ArgumentList "-command New-Item $x264guiExReadmeDirectory -ItemType Directory -Force" -WindowStyle Minimized -Wait

# AviUtl\readme\x264guiEx 内に x264guiEx_readme.txt を移動
Move-Item x264guiEx_readme.txt $x264guiExReadmeDirectory -Force

# カレントディレクトリを tmp ディレクトリに変更
Set-Location ..\..

Write-Host -NoNewline "`r`nVisual C++ 再頒布可能パッケージを確認しています..."

# レジストリからデスクトップアプリの一覧を取得する
$installedApps = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                                  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                                  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
Where-Object { $_.DisplayName -and $_.UninstallString -and -not $_.SystemComponent -and ($_.ReleaseType -notin 'Update','Hotfix') -and -not $_.ParentKeyName } |
Select-Object DisplayName

# Microsoft Visual C++ 2015-20xx Redistributable (x86) がインストールされているか確認する
# ・Visual C++ 再頒布可能パッケージに2020や2021はないので、20[2-9][0-9] としておけば2022以降を指定できる
$Vc2015App = $installedApps.DisplayName -match "Microsoft Visual C\+\+ 2015-20[2-9][0-9] Redistributable \(x86\)"

# Microsoft Visual C++ 2008 Redistributable - x86 がインストールされているか確認する
$Vc2008App = $installedApps.DisplayName -match "Microsoft Visual C\+\+ 2008 Redistributable - x86"

Write-Host "完了"

# $Vc2015App の結果で処理を分岐する
if ($Vc2015App) {
    Write-Host "Microsoft Visual C++ 2015-20xx Redistributable (x86) はインストール済みです。"
} else {
    Write-Host "Microsoft Visual C++ 2015-20xx Redistributable (x86) はインストールされていません。"
    Write-Host "このパッケージは patch.aul など重要なプラグインの動作に必要です。インストールには管理者権限が必要です。`r`n"
    Write-Host -NoNewline "Microsoft Visual C++ 2015-20xx Redistributable (x86) のインストーラーをダウンロードしています..."

    # Visual C++ 2015-20xx Redistributable (x86) のインストーラーをダウンロード (待機)
    Start-Process curl.exe -ArgumentList "-OL https://aka.ms/vs/17/release/vc_redist.x86.exe" -WindowStyle Minimized -Wait

    Write-Host "完了"
    Write-Host "Microsoft Visual C++ 2015-20xx Redistributable (x86) のインストーラーを起動します。"
    Write-Host "インストーラーの指示に従ってインストールを行ってください。`r`n"

    # Visual C++ 2015-20xx Redistributable (x86) のインストーラーを実行 (待機)
    Start-Process -FilePath vc_redist.x86.exe -WindowStyle Minimized -Wait

    Write-Host "インストーラーが終了しました。"
}

# $Vc2008App 結果で処理を分岐する
if ($Vc2008App) {
    Write-Host "Microsoft Visual C++ 2008 Redistributable - x86 はインストール済みです。"
} else {
    Write-Host "Microsoft Visual C++ 2008 Redistributable - x86 はインストールされていません。"

    # 選択ここから

    $choiceTitle = "Microsoft Visual C++ 2008 Redistributable - x86 をインストールしますか？"
    $choiceMessage = "このパッケージは一部のスクリプトの動作に必要です。インストールには管理者権限が必要です。"

    $tChoiceDescription = "System.Management.Automation.Host.ChoiceDescription"
    $choiceOptions = @(
        New-Object $tChoiceDescription ("はい(&Y)",       "インストールを実行します。")
        New-Object $tChoiceDescription ("いいえ(&N)",     "インストールをせず、スキップして次の処理に進みます。")
    )

    $result = $host.ui.PromptForChoice($choiceTitle, $choiceMessage, $choiceOptions, 0)
    switch ($result) {
        0 {
            Write-Host -NoNewline "`r`nMicrosoft Visual C++ 2008 Redistributable - x86 のインストーラーをダウンロードしています..."

            # Visual C++ 2008 Redistributable - x86 のインストーラーをダウンロード (待機)
            Start-Process curl.exe -ArgumentList "-OL https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe" -WindowStyle Minimized -Wait

            Write-Host "完了"
            Write-Host "Microsoft Visual C++ 2008 Redistributable - x86 のインストーラーを起動します。"
            Write-Host "インストーラーの指示に従ってインストールを行ってください。"

            # Visual C++ 2008 Redistributable - x86 のインストーラーを実行 (待機)
            Start-Process -FilePath vcredist_x86.exe -WindowStyle Minimized -Wait

            Write-Host "インストーラーが終了しました。"
            break
        }
        1 {
            Write-Host "`r`nMicrosoft Visual C++ 2008 Redistributable - x86 のインストールをスキップしました。"
            break
        }
    }

    # 選択ここまで
}

Write-Host -NoNewline "`r`n更新に使用した不要なファイルを削除しています..."

# カレントディレクトリをスクリプトファイルのあるディレクトリに変更
Set-Location ..

# tmp ディレクトリを削除
Remove-Item tmp -Recurse

Write-Host "完了"

# ユーザーの操作を待って終了
Write-Host -NoNewline "`r`n`r`n`r`n更新が完了しました！`r`n`r`n`r`nreadmeフォルダを開いて"
Pause

# 終了時にreadmeフォルダを表示
Invoke-Item $ReadmeDirectoryRoot