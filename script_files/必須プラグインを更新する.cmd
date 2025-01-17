@powershell -NoProfile -ExecutionPolicy Unrestricted "$s=[scriptblock]::create((gc \"%~f0\"|?{$_.readcount -gt 1})-join\"`n\");&$s" %*&goto:eof

<#!
 #  MIT License
 #
 #  Copyright (c) 2025 menndouyukkuri, atolycs, Yu-yu0202
 #
 #  Permission is hereby granted, free of charge, to any person obtaining a copy
 #  of this software and associated documentation files (the "Software"), to deal
 #  in the Software without restriction, including without limitation the rights
 #  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 #  copies of the Software, and to permit persons to whom the Software is
 #  furnished to do so, subject to the following conditions:
 #
 #  The above copyright notice and this permission notice shall be included in all
 #  copies or substantial portions of the Software.
 #
 #  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 #  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 #  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 #  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 #  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 #  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 #  SOFTWARE.
#>

# GitHubリポジトリの最新版リリースのダウンロードURLを取得する
function GithubLatestReleaseUrl ($repo) {
	# GitHubのAPIから最新版リリースの情報を取得する
	$api = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest"

	# 最新版リリースのダウンロードURLのみを返す
	return($api.assets.browser_download_url)
}

$Host.UI.RawUI.WindowTitle = "必須プラグインを更新する.cmd"

Write-Host "必須プラグイン (patch.aul・L-SMASH Works・InputPipePlugin・x264guiEx) および LuaJIT、ifheif の更新を開始します。`r`n`r`n"

# カレントディレクトリのパスを $scriptFileRoot に保存 (起動方法のせいで $PSScriptRoot が使用できないため)
$scriptFileRoot = (Get-Location).Path

Write-Host -NoNewline "AviUtlがインストールされているフォルダを確認しています..."

# aviutl.exe が入っているディレクトリを探し、$aviutlExeDirectory にパスを保存
New-Variable aviutlExeDirectory
if (Test-Path "C:\AviUtl\aviutl.exe") {
	Write-Host "完了"
	$aviutlExeDirectory = "C:\AviUtl"
} elseif (Test-Path "C:\Applications\AviUtl\aviutl.exe") {
	Write-Host "完了"
	$aviutlExeDirectory = "C:\Applications\AviUtl"
} else { # 確認できなかった場合、ユーザーにパスを入力させる
	# ユーザーにパスを入力させ、aviutl.exe が入っていることを確認したらループを抜ける
	do {
		Write-Host "完了"
		Write-Host "AviUtlがインストールされているフォルダが確認できませんでした。`r`n"

		Write-Host "aviutl.exe のパス、または aviutl.exe が入っているフォルダのパスを入力し、Enter を押してください。"
		$userInputAviutlExePath = Read-Host

		# ユーザーの入力をもとに aviutl.exe の入っているディレクトリのパスを $aviutlExeDirectory に代入
		if ($userInputAviutlExePath -match "\\aviutl\.exe") {
			$aviutlExeDirectory = Split-Path $userInputAviutlExePath -Parent
		} else {
			$aviutlExeDirectory = $userInputAviutlExePath
		}

		Write-Host -NoNewline "`r`nAviUtlがインストールされているフォルダを確認しています..."
	} while (!(Test-Path "${aviutlExeDirectory}\aviutl.exe"))
	Write-Host "完了"
}

Write-Host "${aviutlExeDirectory} に aviutl.exe を確認しました。"

Start-Sleep -Milliseconds 500

Write-Host -NoNewline "`r`n一時的にファイルを保管するフォルダを作成しています..."

# AviUtl ディレクトリ内に plugins, script, license, readme の4つのディレクトリを作成する (待機)
$aviutlPluginsDirectory = Join-Path -Path $aviutlExeDirectory -ChildPath plugins
$aviutlScriptDirectory = Join-Path -Path $aviutlExeDirectory -ChildPath script
$LicenseDirectoryRoot = Join-Path -Path $aviutlExeDirectory -ChildPath license
$ReadmeDirectoryRoot = Join-Path -Path $aviutlExeDirectory -ChildPath readme
Start-Process powershell -ArgumentList "-command New-Item $aviutlPluginsDirectory, $aviutlScriptDirectory, $LicenseDirectoryRoot, $ReadmeDirectoryRoot -ItemType Directory -Force" -WindowStyle Hidden -Wait

# tmp ディレクトリを作成する (待機)
Start-Process powershell -ArgumentList "-command New-Item tmp -ItemType Directory -Force" -WindowStyle Hidden -Wait

Write-Host "完了"
Write-Host -NoNewline "`r`n拡張編集Pluginのインストールされているフォルダを確認しています..."

# 拡張編集Pluginが plugins ディレクトリ内にある場合、AviUtl ディレクトリ内に移動させる (エラーの防止)
if (Test-Path "${aviutlPluginsDirectory}\exedit.auf") {
	# カレントディレクトリを plugins ディレクトリに変更
	Set-Location $aviutlPluginsDirectory

	# 拡張編集Pluginのファイルを全て AviUtl ディレクトリ内に移動
	Move-Item "exedit*" $aviutlExeDirectory -Force
	Move-Item lua51.dll $aviutlExeDirectory -Force
	if (Test-Path "${aviutlPluginsDirectory}\lua.txt") {
		Move-Item lua.txt $aviutlExeDirectory -Force
	}

	# Susieプラグインの場所も併せて変更
	if (Test-Path "${aviutlPluginsDirectory}\*.spi") {
		Move-Item "*.spi" $aviutlExeDirectory -Force
	}

	# カレントディレクトリをスクリプトファイルのあるディレクトリに変更
	Set-Location $scriptFileRoot
}

# カレントディレクトリを tmp ディレクトリに変更
Set-Location tmp

Write-Host "完了"

# 拡張編集Plugin 0.93テスト版に付属する lua51jit.dll を発見した場合、0.92で置き換える
if ((Test-Path "${aviutlExeDirectory}\lua51jit.dll") -or (Test-Path "${aviutlPluginsDirectory}\lua51jit.dll")) {
	Write-Host -NoNewline "`r`n拡張編集Plugin version 0.92をダウンロードしています..."

	# 拡張編集Plugin version 0.92のzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL http://spring-fragrance.mints.ne.jp/aviutl/exedit92.zip" -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "拡張編集Pluginをインストールしています..."

	# 拡張編集Pluginのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path exedit92.zip -Force" -WindowStyle Hidden -Wait

	# カレントディレクトリを exedit92 ディレクトリに変更
	Set-Location exedit92

	# AviUtl\readme 内に exedit ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${ReadmeDirectoryRoot}\exedit`" -ItemType Directory -Force" -WindowStyle Hidden -Wait

	# exedit.ini は使用せず、かつこの後の処理で邪魔になるので削除する (待機)
	Start-Process powershell -ArgumentList "-command Remove-Item exedit.ini" -WindowStyle Hidden -Wait

	# AviUtl\readme\exedit 内に exedit.txt, lua.txt を (待機) 、AviUtl ディレクトリ内にその他のファイルをそれぞれ移動
	Start-Process powershell -ArgumentList "-command Move-Item *.txt `"${ReadmeDirectoryRoot}\exedit`" -Force" -WindowStyle Hidden -Wait
	Move-Item * $aviutlExeDirectory -Force

	# 不要な lua51jit.dll を削除
	if (Test-Path "${aviutlExeDirectory}\lua51jit.dll") {
		Remove-Item "${aviutlExeDirectory}\lua51jit.dll"
	} else {
		Remove-Item "${aviutlPluginsDirectory}\lua51jit.dll"
	}

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..

	Write-Host "完了"
}

Write-Host -NoNewline "`r`npatch.aul (謎さうなフォーク版) の最新版情報を取得しています..."

# patch.aul (謎さうなフォーク版) の最新版のダウンロードURLを取得
$patchAulUrl = GithubLatestReleaseUrl "nazonoSAUNA/patch.aul"

Write-Host "完了"
Write-Host -NoNewline "patch.aul (謎さうなフォーク版) をダウンロードしています..."

# patch.aul (謎さうなフォーク版) のzipファイルをダウンロード (待機)
Start-Process -FilePath curl.exe -ArgumentList "-OL $patchAulUrl" -WindowStyle Hidden -Wait

Write-Host "完了"
Write-Host -NoNewline "patch.aul (謎さうなフォーク版) をインストールしています..."

# patch.aulのzipファイルを展開 (待機)
Start-Process powershell -ArgumentList "-command Expand-Archive -Path patch.aul_*.zip -Force" -WindowStyle Hidden -Wait

# カレントディレクトリをpatch.aulのzipファイルを展開したディレクトリに変更
Set-Location "patch.aul_*"

# AviUtl\license 内に patch-aul ディレクトリを作成 (待機)
$patchAulLicenseDirectory = Join-Path -Path $LicenseDirectoryRoot -ChildPath patch-aul
Start-Process powershell -ArgumentList "-command New-Item $patchAulLicenseDirectory -ItemType Directory -Force" -WindowStyle Hidden -Wait

# patch.aul が plugins ディレクトリ内にある場合、削除して patch.aul.json を移動させる (エラーの防止)
$patchAulPluginsPath = Join-Path -Path $aviutlPluginsDirectory -ChildPath patch.aul
if (Test-Path $patchAulPluginsPath) {
	Remove-Item $patchAulPluginsPath
	$patchAulJsonPath = Join-Path -Path $aviutlExeDirectory -ChildPath patch.aul.json
	$patchAulJsonPluginsPath = Join-Path -Path $aviutlPluginsDirectory -ChildPath patch.aul.json
	if ((Test-Path $patchAulJsonPluginsPath) -and (!(Test-Path $patchAulJsonPath))) {
		Move-Item $patchAulJsonPluginsPath $aviutlExeDirectory -Force
	} elseif (Test-Path $patchAulJsonPluginsPath) {
		Remove-Item $patchAulJsonPluginsPath
	}
}

# AviUtl ディレクトリ内に patch.aul を (待機) 、AviUtl\license\patch-aul 内にその他のファイルをそれぞれ移動
Start-Process powershell -ArgumentList "-command Move-Item patch.aul $aviutlExeDirectory -Force" -WindowStyle Hidden -Wait
Move-Item * $patchAulLicenseDirectory -Force

# カレントディレクトリを tmp ディレクトリに変更
Set-Location ..

Write-Host "完了"
Write-Host -NoNewline "`r`npatch.aul (謎さうなフォーク版) と競合するプラグインの有無を確認しています..."

# カレントディレクトリを plugins ディレクトリに変更
Set-Location $aviutlPluginsDirectory

# bakusoku.auf を確認し、あったら削除
if (Test-Path "${aviutlExeDirectory}\bakusoku.auf") {
	Remove-Item "${aviutlExeDirectory}\bakusoku.auf"
}
if (Test-Path "${aviutlPluginsDirectory}\bakusoku.auf") {
	Remove-Item "${aviutlPluginsDirectory}\bakusoku.auf"
}
Get-ChildItem -Attributes Directory | ForEach-Object {
	if (Test-Path -Path "${_}\bakusoku.auf") {
		Remove-Item "${_}\bakusoku.auf"
	}
}

# Boost.auf を確認し、あったら削除
if (Test-Path "${aviutlExeDirectory}\Boost.auf") {
	Remove-Item "${aviutlExeDirectory}\Boost.auf"
}
if (Test-Path "${aviutlPluginsDirectory}\Boost.auf") {
	Remove-Item "${aviutlPluginsDirectory}\Boost.auf"
}
Get-ChildItem -Attributes Directory | ForEach-Object {
	if (Test-Path -Path "${_}\Boost.auf") {
		Remove-Item "${_}\Boost.auf"
	}
}

# カレントディレクトリを tmp ディレクトリに変更
Set-Location "${scriptFileRoot}\tmp"

Write-Host "完了"
Write-Host -NoNewline "`r`nL-SMASH Works (Mr-Ojii版) の最新版情報を取得しています..."

# L-SMASH Works (Mr-Ojii版) の最新版のダウンロードURLを取得
$lSmashWorksAllUrl = GithubLatestReleaseUrl "Mr-Ojii/L-SMASH-Works-Auto-Builds"

# 複数ある中からAviUtl用のもののみ残す
$lSmashWorksUrl = $lSmashWorksAllUrl | Where-Object {$_ -like "*Mr-Ojii_vimeo*"}

Write-Host "完了"
Write-Host -NoNewline "L-SMASH Works (Mr-Ojii版) をダウンロードしています..."

# L-SMASH Works (Mr-Ojii版) のzipファイルをダウンロード (待機)
Start-Process -FilePath curl.exe -ArgumentList "-OL $lSmashWorksUrl" -WindowStyle Hidden -Wait

Write-Host "完了"
Write-Host -NoNewline "L-SMASH Works (Mr-Ojii版) をインストールしています..."

# AviUtl\license\l-smash_works 内に Licenses ディレクトリがあれば削除する (エラーの防止)
if (Test-Path "${LicenseDirectoryRoot}\l-smash_works\Licenses") {
	Remove-Item "${LicenseDirectoryRoot}\l-smash_works\Licenses" -Recurse
}

# カレントディレクトリを AviUtl ディレクトリに変更
Set-Location $aviutlExeDirectory

# AviUtl ディレクトリやそのサブディレクトリ内の .lwi ファイルを削除する (エラーの防止)
if (Test-Path "*.lwi") {
	Remove-Item "*.lwi"
}
Get-ChildItem -Attributes Directory | ForEach-Object {
	if (Test-Path -Path "${_}\*.lwi") {
		Remove-Item "${_}\*.lwi"
	}
}

# カレントディレクトリを tmp ディレクトリに変更
Set-Location "${scriptFileRoot}\tmp"

# L-SMASH Worksのzipファイルを展開 (待機)
Start-Process powershell -ArgumentList "-command Expand-Archive -Path L-SMASH-Works_*.zip -Force" -WindowStyle Hidden -Wait

# カレントディレクトリをL-SMASH Worksのzipファイルを展開したディレクトリに変更
Set-Location "L-SMASH-Works_*"

# AviUtl\readme, AviUtl\license 内に l-smash_works ディレクトリを作成 (待機)
Start-Process powershell -ArgumentList "-command New-Item `"${ReadmeDirectoryRoot}\l-smash_works`", `"${LicenseDirectoryRoot}\l-smash_works`" -ItemType Directory -Force" -WindowStyle Hidden -Wait

# L-SMASH Worksの入っているディレクトリを探し、$lwinputAuiDirectory にパスを保存
# $inputPipePluginDeleteCheckDirectory は $lwinputAuiDirectory の逆、後に使用
New-Variable lwinputAuiDirectory
New-Variable inputPipePluginDeleteCheckDirectory
if (Test-Path "${aviutlExeDirectory}\lwinput.aui") {
	$lwinputAuiDirectory = $aviutlExeDirectory
	$inputPipePluginDeleteCheckDirectory = $aviutlPluginsDirectory
} else {
	$lwinputAuiDirectory = $aviutlPluginsDirectory
	$inputPipePluginDeleteCheckDirectory = $aviutlExeDirectory
}

Start-Sleep -Milliseconds 500

# AviUtl\plugins ディレクトリ内に lw*.au* を、AviUtl\readme\l-smash_works 内に READM* を (待機) 、
# AviUtl\license\l-smash_works 内にその他のファイルをそれぞれ移動
Start-Process powershell -ArgumentList "-command Move-Item lw*.au* $lwinputAuiDirectory -Force; Move-Item READM* `"${ReadmeDirectoryRoot}\l-smash_works`" -Force" -WindowStyle Hidden -Wait
Move-Item * "${LicenseDirectoryRoot}\l-smash_works" -Force

# カレントディレクトリを tmp ディレクトリに変更
Set-Location ..

Write-Host "完了"
Write-Host -NoNewline "`r`nInputPipePluginの最新版情報を取得しています..."

# InputPipePluginの最新版のダウンロードURLを取得
$InputPipePluginUrl = GithubLatestReleaseUrl "amate/InputPipePlugin"

Write-Host "完了"
Write-Host -NoNewline "InputPipePluginをダウンロードしています..."

# InputPipePluginのzipファイルをダウンロード (待機)
Start-Process -FilePath curl.exe -ArgumentList "-OL $InputPipePluginUrl" -WindowStyle Hidden -Wait

Write-Host "完了"
Write-Host -NoNewline "InputPipePluginをインストールしています..."

# InputPipePluginのzipファイルを展開 (待機)
Start-Process powershell -ArgumentList "-command Expand-Archive -Path InputPipePlugin_*.zip -Force" -WindowStyle Hidden -Wait

# カレントディレクトリをInputPipePluginのzipファイルを展開したディレクトリに変更
Set-Location "InputPipePlugin_*\InputPipePlugin"

# AviUtl\readme, AviUtl\license 内に inputPipePlugin ディレクトリを作成 (待機)
Start-Process powershell -ArgumentList "-command New-Item `"${ReadmeDirectoryRoot}\inputPipePlugin`", `"${LicenseDirectoryRoot}\inputPipePlugin`" -ItemType Directory -Force" -WindowStyle Hidden -Wait

# AviUtl\license\inputPipePlugin 内に LICENSE を、AviUtl\readme\inputPipePlugin 内に Readme.md を (待機) 、
# AviUtl\plugins ディレクトリ内にその他のファイルをそれぞれ移動
Start-Process powershell -ArgumentList "-command Move-Item LICENSE `"${LicenseDirectoryRoot}\inputPipePlugin`" -Force; Move-Item Readme.md `"${ReadmeDirectoryRoot}\inputPipePlugin`" -Force" -WindowStyle Hidden -Wait
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
Start-Process -FilePath curl.exe -ArgumentList "-OL $x264guiExUrl" -WindowStyle Hidden -Wait

Write-Host "完了"
Write-Host -NoNewline "x264guiExをインストールしています。`r`n"

# x264guiExのzipファイルを展開 (待機)
Start-Process powershell -ArgumentList "-command Expand-Archive -Path x264guiEx_*.zip -Force" -WindowStyle Hidden -Wait

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
	New-Object $x264guiExTChoiceDescription ("はい(&Y)",	   "上書きを実行します。")
	New-Object $x264guiExTChoiceDescription ("いいえ(&N)",	 "上書きをせず、スキップして次の処理に進みます。")
)

$x264guiExChoiceResult = $host.ui.PromptForChoice($x264guiExChoiceTitle, $x264guiExChoiceMessage, $x264guiExChoiceOptions, 1)
switch ($x264guiExChoiceResult) {
	0 {
		Write-Host -NoNewline "`r`nx264guiExのプロファイルを上書きします..."

		# AviUtl\plugins 内に x264guiEx_stg ディレクトリがあれば削除する
		if (Test-Path "${aviutlPluginsDirectory}\x264guiEx_stg") {
			Remove-Item "${aviutlPluginsDirectory}\x264guiEx_stg" -Recurse
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
Start-Process powershell -ArgumentList "-command New-Item `"${aviutlExeDirectory}\exe_files`" -ItemType Directory -Force" -WindowStyle Hidden -Wait

# AviUtl\exe_files 内に x264_*.exe があれば削除 (待機)
Start-Process powershell -ArgumentList "-command if (Test-Path `"${aviutlExeDirectory}\exe_files\x264_*.exe`") { Remove-Item `"${aviutlExeDirectory}\exe_files\x264_*.exe`" }" -WindowStyle Hidden -Wait

# AviUtl\exe_files 内に現在のディレクトリのファイルを全て移動
Move-Item * "${aviutlExeDirectory}\exe_files" -Force

# カレントディレクトリをx264guiExのzipファイルを展開したディレクトリに変更
Set-Location ..

# AviUtl\readme 内に x264guiEx ディレクトリを作成 (待機)
Start-Process powershell -ArgumentList "-command New-Item `"${ReadmeDirectoryRoot}\x264guiEx`" -ItemType Directory -Force" -WindowStyle Hidden -Wait

# AviUtl\readme\x264guiEx 内に x264guiEx_readme.txt を移動
Move-Item x264guiEx_readme.txt "${ReadmeDirectoryRoot}\x264guiEx" -Force

# カレントディレクトリを tmp ディレクトリに変更
Set-Location ..\..

Write-Host "`r`nx264guiExのインストールが完了しました。"


# LuaJITの更新 by Yu-yu0202 (20250109)
	# 不具合が直らなかったため再実装 by menndouyukkuri (20250110)

# AviUtl ディレクトリ内に old_lua51.dll があれば削除する
if (Test-Path "${aviutlExeDirectory}\old_lua51.dll") {
	Remove-Item "${aviutlExeDirectory}\old_lua51.dll"
}

Write-Host -NoNewline "`r`nLuaJITの最新版情報を取得しています..."

# LuaJITの最新版のダウンロードURLを取得
$luaJitAllUrl = GithubLatestReleaseUrl "Per-Terra/LuaJIT-Auto-Builds"

# 複数ある中からAviUtl用のもののみ残す
$luaJitUrl = $luaJitAllUrl | Where-Object {$_ -like "*LuaJIT_2.1_Win_x86.zip"}

Write-Host "完了"
Write-Host -NoNewline "LuaJITをダウンロードしています..."

# LuaJITのzipファイルをダウンロード (待機)
Start-Process -FilePath curl.exe -ArgumentList "-OL $luaJitUrl" -WindowStyle Hidden -Wait

Write-Host "完了"
Write-Host -NoNewline "LuaJITをインストールしています..."

# AviUtl ディレクトリ内に exedit_lua51.dll がない場合、既にある lua51.dll をリネームしてバックアップする
if (!(Test-Path "${aviutlExeDirectory}\exedit_lua51.dll")) {
	Rename-Item "${aviutlExeDirectory}\lua51.dll" "old_lua51.dll" -Force
}

# AviUtl\readme\LuaJIT 内に doc ディレクトリがあれば削除する (エラーの防止)
if (Test-Path "${ReadmeDirectoryRoot}\LuaJIT\doc") {
	Remove-Item "${ReadmeDirectoryRoot}\LuaJIT\doc" -Recurse
}

# LuaJITのzipファイルを展開 (待機)
Start-Process powershell -ArgumentList "-command Expand-Archive -Path 'LuaJIT_2.1_Win_x86.zip' -Force" -WindowStyle Hidden -Wait

# カレントディレクトリをLuaJITのzipファイルを展開したディレクトリに変更
Set-Location "LuaJIT_2.1_Win_x86"

# AviUtl\readme, AviUtl\license 内に LuaJIT ディレクトリを作成 (待機)
Start-Process powershell -ArgumentList "-command New-Item `"${ReadmeDirectoryRoot}\LuaJIT`", `"${LicenseDirectoryRoot}\LuaJIT`" -ItemType Directory -Force" -WindowStyle Hidden -Wait

# AviUtl ディレクトリ内に lua51.dll を、AviUtl\readme\LuaJIT 内に README と doc を、AviUtl\license\LuaJIT 内に
# COPYRIGHT と About-This-Build.txt をそれぞれ移動
Move-Item "lua51.dll" $aviutlExeDirectory -Force
Move-Item README "${ReadmeDirectoryRoot}\LuaJIT" -Force
Move-Item doc "${ReadmeDirectoryRoot}\LuaJIT" -Force
Move-Item COPYRIGHT "${LicenseDirectoryRoot}\LuaJIT" -Force
Move-Item "About-This-Build.txt" "${LicenseDirectoryRoot}\LuaJIT" -Force

# カレントディレクトリを tmp ディレクトリに変更
Set-Location ..

Write-Host "完了"


Write-Host -NoNewline "`r`nWebP Susie Plug-inを確認しています..."

# WebP Susie Plug-inが導入されていない場合のみ以下の処理を実行
if (!(Test-Path "${aviutlExeDirectory}\iftwebp.spi")) {
	Write-Host "完了"
	Write-Host -NoNewline "`r`nWebP Susie Plug-inをダウンロードしています..."

	# WebP Susie Plug-inのzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL https://toroidj.github.io/plugin/iftwebp11.zip" -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "WebP Susie Plug-inをインストールしています..."

	# WebP Susie Plug-inのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path iftwebp11.zip -Force" -WindowStyle Hidden -Wait

	# カレントディレクトリを iftwebp11 ディレクトリに変更
	Set-Location iftwebp11

	# AviUtl\readme 内に iftwebp ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${ReadmeDirectoryRoot}\iftwebp`" -ItemType Directory -Force" -WindowStyle Hidden -Wait

	# AviUtl ディレクトリ内に iftwebp.spi を、AviUtl\readme\iftwebp 内に iftwebp.txt をそれぞれ移動
	Move-Item iftwebp.spi $aviutlExeDirectory -Force
	Move-Item iftwebp.txt "${ReadmeDirectoryRoot}\iftwebp" -Force

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..
}

Write-Host "完了"
Write-Host -NoNewline "`r`nifheifの最新版情報を取得しています..."

# ifheifの最新版のダウンロードURLを取得
$ifheifUrl = GithubLatestReleaseUrl "Mr-Ojii/ifheif"

Write-Host "完了"
Write-Host -NoNewline "ifheifをダウンロードしています..."

# ifheifのzipファイルをダウンロード (待機)
Start-Process -FilePath curl.exe -ArgumentList "-OL $ifheifUrl" -WindowStyle Hidden -Wait

Write-Host "完了"
Write-Host -NoNewline "ifheifをインストールしています..."

# AviUtl\license\ifheif 内に Licenses ディレクトリがあれば削除する (エラーの防止)
if (Test-Path "${LicenseDirectoryRoot}\ifheif\Licenses") {
	Remove-Item "${LicenseDirectoryRoot}\ifheif\Licenses" -Recurse
}

# ifheifのzipファイルを展開 (待機)
Start-Process powershell -ArgumentList "-command Expand-Archive -Path ifheif.zip -Force" -WindowStyle Hidden -Wait

# カレントディレクトリをifheifのzipファイルを展開したディレクトリに変更
Set-Location "ifheif"

# AviUtl\readme, AviUtl\license 内に ifheif ディレクトリを作成 (待機)
Start-Process powershell -ArgumentList "-command New-Item `"${ReadmeDirectoryRoot}\ifheif`", `"${LicenseDirectoryRoot}\ifheif`" -ItemType Directory -Force" -WindowStyle Hidden -Wait

# AviUtl ディレクトリ内に ifheif.spi を、AviUtl\license\ifheif 内に LICENSE と Licenses ディレクトリを、
# AviUtl\readme\ifheif 内に Readme.md をそれぞれ移動
Move-Item ifheif.spi $aviutlExeDirectory -Force
Move-Item "LICENS*" "${LicenseDirectoryRoot}\ifheif" -Force
Move-Item Readme.md "${ReadmeDirectoryRoot}\ifheif" -Force

# カレントディレクトリを tmp ディレクトリに変更
Set-Location ..

Write-Host "完了"
Write-Host -NoNewline "`r`nVisual C++ 再頒布可能パッケージを確認しています..."

# レジストリからデスクトップアプリの一覧を取得する
$installedApps = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
								  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
								  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
Where-Object { $_.DisplayName -and $_.UninstallString -and -not $_.SystemComponent -and ($_.ReleaseType -notin 'Update','Hotfix') -and -not $_.ParentKeyName } |
Select-Object DisplayName

# Microsoft Visual C++ 2015-20xx Redistributable (x86) がインストールされているか確認する
	# Visual C++ 再頒布可能パッケージに2020や2021はないので、20[2-9][0-9] としておけば2022以降を指定できる
$Vc2015App = $installedApps.DisplayName -match "Microsoft Visual C\+\+ 2015-20[2-9][0-9] Redistributable \(x86\)"

# Microsoft Visual C++ 2008 Redistributable - x86 がインストールされているか確認する
$Vc2008App = $installedApps.DisplayName -match "Microsoft Visual C\+\+ 2008 Redistributable - x86"

Write-Host "完了"

# $Vc2015App と $Vc2008App の結果で処理を分岐する

# 両方インストールされている場合、メッセージだけ表示
if ($Vc2015App -and $Vc2008App) {
	Write-Host "Microsoft Visual C++ 2015-20xx Redistributable (x86) はインストール済みです。"
	Write-Host "Microsoft Visual C++ 2008 Redistributable - x86 はインストール済みです。"

# 2008のみインストールされている場合、2015を自動インストール
} elseif ($Vc2008App) {
	Write-Host "Microsoft Visual C++ 2015-20xx Redistributable (x86) はインストールされていません。"
	Write-Host "このパッケージは patch.aul など重要なプラグインの動作に必要です。インストールには管理者権限が必要です。`r`n"
	Write-Host -NoNewline "Microsoft Visual C++ 2015-20xx Redistributable (x86) のインストーラーをダウンロードしています..."

	# Visual C++ 2015-20xx Redistributable (x86) のインストーラーをダウンロード (待機)
	Start-Process curl.exe -ArgumentList "-OL https://aka.ms/vs/17/release/vc_redist.x86.exe" -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host "Microsoft Visual C++ 2015-20xx Redistributable (x86) のインストールを行います。"
	Write-Host "デバイスへの変更が必要になります。ユーザーアカウント制御のポップアップが出たら [はい] を押して許可してください。`r`n"

	# Visual C++ 2015-20xx Redistributable (x86) のインストーラーを実行 (待機)
		# 自動インストールオプションを追加 by Atolycs (20250106)
	Start-Process -FilePath vc_redist.x86.exe -ArgumentList "/install /passive" -WindowStyle Hidden -Wait

	Write-Host "インストーラーが終了しました。"
	Write-Host "`r`nMicrosoft Visual C++ 2008 Redistributable - x86 はインストール済みです。"

# 2015のみインストールされている場合、2008のインストールをユーザーに選択させる
} elseif ($Vc2015App) {
	Write-Host "Microsoft Visual C++ 2008 Redistributable - x86 はインストールされていません。"

	# 選択ここから

	$choiceTitle = "Microsoft Visual C++ 2008 Redistributable - x86 をインストールしますか？"
	$choiceMessage = "このパッケージは一部のスクリプトの動作に必要です。インストールには管理者権限が必要です。"

	$tChoiceDescription = "System.Management.Automation.Host.ChoiceDescription"
	$choiceOptions = @(
		New-Object $tChoiceDescription ("はい(&Y)", "インストールを実行します。")
		New-Object $tChoiceDescription ("いいえ(&N)", "インストールをせず、スキップして次の処理に進みます。")
	)

	$result = $host.ui.PromptForChoice($choiceTitle, $choiceMessage, $choiceOptions, 0)
	switch ($result) {
		0 {
			Write-Host -NoNewline "`r`nMicrosoft Visual C++ 2008 Redistributable - x86 のインストーラーをダウンロードしています..."

			# Visual C++ 2008 Redistributable - x86 のインストーラーをダウンロード (待機)
			Start-Process curl.exe -ArgumentList "-OL https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe" -WindowStyle Hidden -Wait

			Write-Host "完了"
			Write-Host "Microsoft Visual C++ 2008 Redistributable - x86 のインストールを行います。"
			Write-Host "デバイスへの変更が必要になります。ユーザーアカウント制御のポップアップが出たら [はい] を押して許可してください。`r`n"

			# Visual C++ 2008 Redistributable - x86 のインストーラーを実行 (待機)
				# 自動インストールオプションを追加 by Atolycs (20250106)
			Start-Process -FilePath vcredist_x86.exe -ArgumentList "/qb" -WindowStyle Hidden -Wait

			Write-Host "インストーラーが終了しました。"
			break
		}
		1 {
			Write-Host "`r`nMicrosoft Visual C++ 2008 Redistributable - x86 のインストールをスキップしました。"
			break
		}
	}

	# 選択ここまで

# 両方インストールされていない場合、2008のインストールをユーザーに選択させ、2008をインストールする場合は両方インストールし、
# 2008をインストールしない場合は2015のみ自動インストール
} else  {
	Write-Host "Microsoft Visual C++ 2015-20xx Redistributable (x86) はインストールされていません。"
	Write-Host "このパッケージは patch.aul など重要なプラグインの動作に必要です。インストールには管理者権限が必要です。`r`n"
	Write-Host -NoNewline "Microsoft Visual C++ 2015-20xx Redistributable (x86) のインストーラーをダウンロードしています..."

	# Visual C++ 2015-20xx Redistributable (x86) のインストーラーをダウンロード (待機)
	Start-Process curl.exe -ArgumentList "-OL https://aka.ms/vs/17/release/vc_redist.x86.exe" -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host "`r`nMicrosoft Visual C++ 2008 Redistributable - x86 はインストールされていません。"

	# 選択ここから

	$choiceTitle = "Microsoft Visual C++ 2008 Redistributable - x86 をインストールしますか？"
	$choiceMessage = "このパッケージは一部のスクリプトの動作に必要です。インストールには管理者権限が必要です。"

	$tChoiceDescription = "System.Management.Automation.Host.ChoiceDescription"
	$choiceOptions = @(
		New-Object $tChoiceDescription ("はい(&Y)",  "インストールを実行します。")
		New-Object $tChoiceDescription ("いいえ(&N)", "インストールをせず、スキップして次の処理に進みます。")
	)

	$result = $host.ui.PromptForChoice($choiceTitle, $choiceMessage, $choiceOptions, 0)
	switch ($result) {
		0 {
			Write-Host -NoNewline "`r`nMicrosoft Visual C++ 2008 Redistributable - x86 のインストーラーをダウンロードしています..."

			# Visual C++ 2008 Redistributable - x86 のインストーラーをダウンロード (待機)
			Start-Process curl.exe -ArgumentList "-OL https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe" -WindowStyle Hidden -Wait

			Write-Host "完了"
			Write-Host "`r`nMicrosoft Visual C++ 2015-20xx Redistributable (x86) と`r`nMicrosoft Visual C++ 2008 Redistributable - x86 のインストールを行います。"
			Write-Host "デバイスへの変更が必要になります。ユーザーアカウント制御のポップアップが出たら [はい] を押して許可してください。`r`n"

			# VCruntimeInstall2015and2008.cmd の存在するディレクトリを確認
				# VCruntimeInstall2015and2008.cmd は Visual C++ 2015-20xx Redistributable (x86) と
				# Visual C++ 2008 Redistributable - x86 のインストーラーを順番に実行していくだけのスクリプト
			$VCruntimeInstallCmdDirectory = Join-Path -Path $scriptFileRoot -ChildPath script_files
			$VCruntimeInstallCmdPath = Join-Path -Path $VCruntimeInstallCmdDirectory -ChildPath 'VCruntimeInstall2015and2008.cmd'
			if (!(Test-Path $VCruntimeInstallCmdPath)) {
				$VCruntimeInstallCmdDirectory = $scriptFileRoot
			}

			Start-Sleep -Milliseconds 500

			# VCruntimeInstall2015and2008.cmd を管理者権限で実行 (待機)
			Start-Process -FilePath cmd.exe -ArgumentList "/C cd $VCruntimeInstallCmdDirectory & call VCruntimeInstall2015and2008.cmd & exit" -Verb RunAs -WindowStyle Hidden -Wait

			Write-Host "インストーラーが終了しました。"
			break
		}
		1 {
			Write-Host "Microsoft Visual C++ 2015-20xx Redistributable (x86) のインストールを行います。"
			Write-Host "デバイスへの変更が必要になります。ユーザーアカウント制御のポップアップが出たら [はい] を押して許可してください。`r`n"

			# Visual C++ 2015-20xx Redistributable (x86) のインストーラーを実行 (待機)
				# 自動インストールオプションを追加 by Atolycs (20250106)
			Start-Process -FilePath vc_redist.x86.exe -ArgumentList "/install /passive" -WindowStyle Hidden -Wait

			Write-Host "インストーラーが終了しました。"
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
Write-Host -NoNewline "`r`n`r`n`r`n更新が完了しました！`r`n`r`n`r`nreadme フォルダを開いて"
Pause

# 終了時に readme ディレクトリを表示
Invoke-Item $ReadmeDirectoryRoot