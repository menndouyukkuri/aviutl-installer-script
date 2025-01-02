@powershell -NoProfile -ExecutionPolicy Unrestricted "$s=[scriptblock]::create((gc \"%~f0\"|?{$_.readcount -gt 1})-join\"`n\");&$s" %*&goto:eof

#
#   AviUtl Installer Script (Version 0.9.1_2025-01-03)
#
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

Write-Host "AviUtl Installer Script (Version 0.9.1_2025-01-03)`r`n`r`n"
Write-Host -NoNewline "AviUtlをインストールするフォルダを作成しています..."

# C:\Applications ディレクトリを作成する（待機）
Start-Process powershell -ArgumentList "-command New-Item C:\Applications -ItemType Directory -Force" -WindowStyle Minimized -Wait

# C:\Applications\AviUtl ディレクトリを作成する（待機）
Start-Process powershell -ArgumentList "-command New-Item C:\Applications\AviUtl -ItemType Directory -Force" -WindowStyle Minimized -Wait

# AviUtl ディレクトリ内に plugins, script, license, readme の4つのディレクトリを作成する（待機）
Start-Process powershell -ArgumentList "-command New-Item C:\Applications\AviUtl\plugins, C:\Applications\AviUtl\script, C:\Applications\AviUtl\license, C:\Applications\AviUtl\readme -ItemType Directory -Force" -WindowStyle Minimized -Wait

# tmp ディレクトリを作成する（待機）
Start-Process powershell -ArgumentList "-command New-Item tmp -ItemType Directory -Force" -WindowStyle Minimized -Wait

Write-Host "完了"
Write-Host -NoNewline "`r`n一時的にファイルを保管するフォルダを作成しています..."

# カレントディレクトリを tmp ディレクトリに変更
Set-Location tmp

Write-Host "完了"
Write-Host -NoNewline "`r`nAviUtl本体（version1.10）をダウンロードしています..."

# AviUtl 1.10のzipファイルをダウンロード（待機）
Start-Process curl.exe -ArgumentList "-OL http://spring-fragrance.mints.ne.jp/aviutl/aviutl110.zip" -WindowStyle Minimized -Wait

Write-Host "完了"
Write-Host -NoNewline "AviUtl本体をインストールしています..."

# AviUtlのzipファイルを展開（待機）
Start-Process powershell -ArgumentList "-command Expand-Archive -Path aviutl110.zip -Force" -WindowStyle Minimized -Wait

# カレントディレクトリを aviutl110 ディレクトリに変更
Set-Location aviutl110

# AviUtl\readme 内に aviutl ディレクトリを作成（待機）
Start-Process powershell -ArgumentList "-command New-Item C:\Applications\AviUtl\readme\aviutl -ItemType Directory -Force" -WindowStyle Minimized -Wait

# AviUtl ディレクトリ内に aviutl.exe を、AviUtl\readme\aviutl 内に aviutl.txt をそれぞれ移動
Move-Item aviutl.exe C:\Applications\AviUtl -Force
Move-Item aviutl.txt C:\Applications\AviUtl\readme\aviutl -Force

# カレントディレクトリを tmp ディレクトリに変更
Set-Location ..

Write-Host "完了"
Write-Host -NoNewline "`r`n拡張編集Plugin version0.92をダウンロードしています..."

# 拡張編集Plugin 0.92のzipファイルをダウンロード（待機）
Start-Process curl.exe -ArgumentList "-OL http://spring-fragrance.mints.ne.jp/aviutl/exedit92.zip" -WindowStyle Minimized -Wait

Write-Host "完了"
Write-Host -NoNewline "拡張編集Pluginをインストールしています..."

# 拡張編集Pluginのzipファイルを展開（待機）
Start-Process powershell -ArgumentList "-command Expand-Archive -Path exedit92.zip -Force" -WindowStyle Minimized -Wait

# カレントディレクトリを exedit92 ディレクトリに変更
Set-Location exedit92

# AviUtl\readme 内に exedit ディレクトリを作成（待機）
Start-Process powershell -ArgumentList "-command New-Item C:\Applications\AviUtl\readme\exedit -ItemType Directory -Force" -WindowStyle Minimized -Wait

# exedit.ini は使用せず、かつこの後の処理で邪魔になるので削除する（待機）
Start-Process powershell -ArgumentList "-command Remove-Item exedit.ini" -WindowStyle Minimized -Wait

# AviUtl\readme\exedit 内に exedit.txt, lua.txt を（待機）、AviUtl ディレクトリ内にその他のファイルをそれぞれ移動
Start-Process powershell -ArgumentList "-command Move-Item *.txt C:\Applications\AviUtl\readme\exedit -Force" -WindowStyle Minimized -Wait
Move-Item * C:\Applications\AviUtl -Force

# カレントディレクトリを tmp ディレクトリに変更
Set-Location ..

Write-Host "完了"
Write-Host -NoNewline "`r`npatch.aul（謎さうなフォーク版）の最新版情報を取得しています..."

# patch.aul（謎さうなフォーク版）の最新版のダウンロードURLを取得
$patchAulUrl = GithubLatestReleaseUrl "nazonoSAUNA/patch.aul"

Write-Host "完了"
Write-Host -NoNewline "patch.aul（謎さうなフォーク版）をダウンロードしています..."

# patch.aul（謎さうなフォーク版）のzipファイルをダウンロード（待機）
Start-Process curl.exe -ArgumentList "-OL $patchAulUrl" -WindowStyle Minimized -Wait

Write-Host "完了"
Write-Host -NoNewline "patch.aul（謎さうなフォーク版）をインストールしています..."

# patch.aulのzipファイルを展開（待機）
Start-Process powershell -ArgumentList "-command Expand-Archive -Path patch.aul_*.zip -Force" -WindowStyle Minimized -Wait

# カレントディレクトリをpatch.aulのzipファイルを展開したディレクトリに変更
Set-Location "patch.aul_*"

# AviUtl\license 内に patch-aul ディレクトリを作成（待機）
Start-Process powershell -ArgumentList "-command New-Item C:\Applications\AviUtl\license\patch-aul -ItemType Directory -Force" -WindowStyle Minimized -Wait

# AviUtl ディレクトリ内に patch.aul を（待機）、AviUtl\license\patch-aul 内にその他のファイルをそれぞれ移動
Start-Process powershell -ArgumentList "-command Move-Item patch.aul C:\Applications\AviUtl -Force" -WindowStyle Minimized -Wait
Move-Item * C:\Applications\AviUtl\license\patch-aul -Force

# カレントディレクトリを tmp ディレクトリに変更
Set-Location ..

Write-Host "完了"
Write-Host -NoNewline "`r`nL-SMASH Works（Mr-Ojii版）の最新版情報を取得しています..."

# L-SMASH Works（Mr-Ojii版）の最新版のダウンロードURLを取得
$lSmashWorksAllUrl = GithubLatestReleaseUrl "Mr-Ojii/L-SMASH-Works-Auto-Builds"

# 複数ある中からAviUtl用のもののみ残す
$lSmashWorksUrl = $lSmashWorksAllUrl | Where-Object {$_ -like "*Mr-Ojii_vimeo*"}

Write-Host "完了"
Write-Host -NoNewline "L-SMASH Works（Mr-Ojii版）をダウンロードしています..."

# L-SMASH Works（Mr-Ojii版）のzipファイルをダウンロード（待機）
Start-Process curl.exe -ArgumentList "-OL $lSmashWorksUrl" -WindowStyle Minimized -Wait

Write-Host "完了"
Write-Host -NoNewline "L-SMASH Works（Mr-Ojii版）をインストールしています..."

# L-SMASH Worksのzipファイルを展開（待機）
Start-Process powershell -ArgumentList "-command Expand-Archive -Path L-SMASH-Works_*.zip -Force" -WindowStyle Minimized -Wait

# カレントディレクトリをL-SMASH Worksのzipファイルを展開したディレクトリに変更
Set-Location "L-SMASH-Works_*"

# AviUtl\readme, AviUtl\license 内に l-smash_works ディレクトリを作成（待機）
Start-Process powershell -ArgumentList "-command New-Item C:\Applications\AviUtl\readme\l-smash_works, C:\Applications\AviUtl\license\l-smash_works -ItemType Directory -Force" -WindowStyle Minimized -Wait

# AviUtl\plugins ディレクトリ内に lw*.au* を、AviUtl\readme\l-smash_works 内に READM* を（待機）、
# AviUtl\license\l-smash_works 内にその他のファイルをそれぞれ移動
Start-Process powershell -ArgumentList "-command Move-Item lw*.au* C:\Applications\AviUtl\plugins -Force; Move-Item READM* C:\Applications\AviUtl\readme\l-smash_works -Force" -WindowStyle Minimized -Wait
Move-Item * C:\Applications\AviUtl\license\l-smash_works -Force

# カレントディレクトリを tmp ディレクトリに変更
Set-Location ..

Write-Host "完了"
Write-Host -NoNewline "`r`nInputPipePluginの最新版情報を取得しています..."

# InputPipePluginの最新版のダウンロードURLを取得
$InputPipePluginUrl = GithubLatestReleaseUrl "amate/InputPipePlugin"

Write-Host "完了"
Write-Host -NoNewline "InputPipePluginをダウンロードしています..."

# InputPipePluginのzipファイルをダウンロード（待機）
Start-Process curl.exe -ArgumentList "-OL $InputPipePluginUrl" -WindowStyle Minimized -Wait

Write-Host "完了"
Write-Host -NoNewline "InputPipePluginをインストールしています..."

# InputPipePluginのzipファイルを展開（待機）
Start-Process powershell -ArgumentList "-command Expand-Archive -Path InputPipePlugin_*.zip -Force" -WindowStyle Minimized -Wait

# カレントディレクトリをInputPipePluginのzipファイルを展開したディレクトリに変更
Set-Location "InputPipePlugin_*\InputPipePlugin"

# AviUtl\readme, AviUtl\license 内に inputPipePlugin ディレクトリを作成（待機）
Start-Process powershell -ArgumentList "-command New-Item C:\Applications\AviUtl\readme\inputPipePlugin, C:\Applications\AviUtl\license\inputPipePlugin -ItemType Directory -Force" -WindowStyle Minimized -Wait

# AviUtl\license\inputPipePlugin 内に LICENSE を、AviUtl\readme\inputPipePlugin 内に Readme.md を（待機）、
# AviUtl\plugins ディレクトリ内にその他のファイルをそれぞれ移動
Start-Process powershell -ArgumentList "-command Move-Item LICENSE C:\Applications\AviUtl\license\inputPipePlugin -Force; Move-Item Readme.md C:\Applications\AviUtl\readme\inputPipePlugin -Force" -WindowStyle Minimized -Wait
Move-Item * C:\Applications\AviUtl\plugins -Force

# カレントディレクトリを tmp ディレクトリに変更
Set-Location ..\..

Write-Host "完了"
Write-Host -NoNewline "`r`nx264guiExの最新版情報を取得しています..."

# x264guiExの最新版のダウンロードURLを取得
$x264guiExUrl = GithubLatestReleaseUrl "rigaya/x264guiEx"

Write-Host "完了"
Write-Host -NoNewline "x264guiExをダウンロードしています..."

# x264guiExのzipファイルをダウンロード（待機）
Start-Process curl.exe -ArgumentList "-OL $x264guiExUrl" -WindowStyle Minimized -Wait

Write-Host "完了"
Write-Host -NoNewline "x264guiExをインストールしています..."

# x264guiExのzipファイルを展開（待機）
Start-Process powershell -ArgumentList "-command Expand-Archive -Path x264guiEx_*.zip -Force" -WindowStyle Minimized -Wait

# カレントディレクトリをx264guiExのzipファイルを展開したディレクトリに変更
Set-Location "x264guiEx_*\x264guiEx_*"

# AviUtl\readme 内に x264guiEx ディレクトリを作成（待機）
Start-Process powershell -ArgumentList "-command New-Item C:\Applications\AviUtl\readme\x264guiEx -ItemType Directory -Force" -WindowStyle Minimized -Wait

# カレントディレクトリをx264guiExのzipファイルを展開したディレクトリ内の plugins ディレクトリに変更
Set-Location plugins

# AviUtl\plugins 内に現在のディレクトリのファイルを全て移動（待機）
Start-Process powershell -ArgumentList "-command Move-Item * C:\Applications\AviUtl\plugins -Force" -WindowStyle Minimized -Wait

# カレントディレクトリをx264guiExのzipファイルを展開したディレクトリに変更
Set-Location ..

# x264guiExのzipファイルを展開したディレクトリ内の空になった plugins ディレクトリはこの後の処理で邪魔になるので削除する（待機）
Start-Process powershell -ArgumentList "-command Remove-Item plugins -Recurse" -WindowStyle Minimized -Wait

# AviUtl\readme\x264guiEx 内に x264guiEx_readme.txt を（待機）、AviUtl ディレクトリ内にその他のファイルをそれぞれ移動
Start-Process powershell -ArgumentList "-command Move-Item x264guiEx_readme.txt C:\Applications\AviUtl\readme\x264guiEx -Force" -WindowStyle Minimized -Wait
Move-Item * C:\Applications\AviUtl -Force

# カレントディレクトリを tmp ディレクトリに変更
Set-Location ..\..

Write-Host "完了"
Write-Host -NoNewline "`r`n設定ファイルをコピーしています..."

# カレントディレクトリを settings ディレクトリに変更
Set-Location ..\settings

# AviUtl\plugins 内に lsmash.ini を、AviUtl 内にその他のファイルをコピー
Copy-Item lsmash.ini C:\Applications\AviUtl\plugins
Copy-Item aviutl.ini C:\Applications\AviUtl
Copy-Item exedit.ini C:\Applications\AviUtl
Copy-Item デフォルト.cfg C:\Applications\AviUtl

# カレントディレクトリを tmp ディレクトリに変更
Set-Location ..\tmp

Write-Host "完了"
Write-Host -NoNewline "`r`nデスクトップにショートカットファイルを作成しています..."

# WSHを用いてデスクトップにAviUtlのショートカットを作成する
$ShortcutFolder = [Environment]::GetFolderPath("Desktop")
$ShortcutFile = Join-Path -Path $ShortcutFolder -ChildPath "AviUtl.lnk"
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = "C:\Applications\AviUtl\aviutl.exe"
$Shortcut.IconLocation = "C:\Applications\AviUtl\aviutl.exe,0"
$Shortcut.WorkingDirectory = "."
$Shortcut.Save()

Write-Host "完了"
Write-Host -NoNewline "スタートメニューにショートカットファイルを作成しています..."

# WSHを用いてスタートメニューにAviUtlのショートカットを作成する
$ShortcutFolder = [Environment]::GetFolderPath("Programs")
$ShortcutFile = Join-Path -Path $ShortcutFolder -ChildPath "AviUtl.lnk"
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = "C:\Applications\AviUtl\aviutl.exe"
$Shortcut.IconLocation = "C:\Applications\AviUtl\aviutl.exe,0"
$Shortcut.WorkingDirectory = "."
$Shortcut.Save()

Write-Host "完了"
Write-Host -NoNewline "`r`nインストールに使用した不要なファイルを削除しています..."

# カレントディレクトリをスクリプトファイルのあるディレクトリに変更
Set-Location ..

# tmp ディレクトリを削除
Remove-Item tmp -Recurse

Write-Host "完了"

# ユーザーの操作を待って終了
Write-Host -NoNewline "`r`n`r`n`r`nインストールが完了しました！`r`n`r`n`r`nreadmeフォルダを開いて"
Pause

# 終了時にreadmeフォルダを表示
Invoke-Item "C:\Applications\AviUtl\readme"