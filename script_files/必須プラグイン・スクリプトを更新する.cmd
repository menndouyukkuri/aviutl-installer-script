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

$Host.UI.RawUI.WindowTitle = "必須プラグイン・スクリプトを更新する.cmd"
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
Start-Process powershell -ArgumentList "-command New-Item `"${LicenseDirectoryRoot}\patch-aul`" -ItemType Directory -Force" -WindowStyle Hidden -Wait

# patch.aul が plugins ディレクトリ内にある場合、削除して patch.aul.json を移動させる (エラーの防止)
if (Test-Path "${aviutlPluginsDirectory}\patch.aul") {
	Remove-Item "${aviutlPluginsDirectory}\patch.aul"
	if ((Test-Path "${aviutlPluginsDirectory}\patch.aul.json") -and (!(Test-Path "${aviutlExeDirectory}\patch.aul.json"))) {
		Move-Item "${aviutlPluginsDirectory}\patch.aul.json" $aviutlExeDirectory -Force
	} elseif (Test-Path "${aviutlPluginsDirectory}\patch.aul.json") {
		Remove-Item "${aviutlPluginsDirectory}\patch.aul.json"
	}
}

# AviUtl ディレクトリ内に patch.aul を (待機) 、AviUtl\license\patch-aul 内にその他のファイルをそれぞれ移動
Start-Process powershell -ArgumentList "-command Move-Item patch.aul $aviutlExeDirectory -Force" -WindowStyle Hidden -Wait
Move-Item * "${LicenseDirectoryRoot}\patch-aul" -Force

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
Get-ChildItem -Attributes Directory -Recurse | ForEach-Object {
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
Write-Host "x264guiExをインストールしています。"

# x264guiExのzipファイルを展開 (待機)
Start-Process powershell -ArgumentList "-command Expand-Archive -Path x264guiEx_*.zip -Force" -WindowStyle Hidden -Wait

# カレントディレクトリをx264guiExのzipファイルを展開したディレクトリに変更
Set-Location "x264guiEx_*\x264guiEx_*"

# カレントディレクトリをx264guiExのzipファイルを展開したディレクトリ内の plugins ディレクトリに変更
Set-Location plugins

# AviUtl\plugins 内に x264guiEx_stg ディレクトリがあれば以下の処理を実行
if (Test-Path "${aviutlPluginsDirectory}\x264guiEx_stg") {
	# プロファイルを上書きするかどうかユーザーに確認する (既定は 上書きしない)
	# 選択ここから

	$x264guiExChoiceTitle = "x264guiExのプロファイルを上書きしますか？"
	$x264guiExChoiceMessage = "プロファイルは更新で新しくなっている可能性がありますが、上書きを実行すると追加したプロファイルやプロファイルへの変更が削除されます。"

	$x264guiExTChoiceDescription = "System.Management.Automation.Host.ChoiceDescription"
	$x264guiExChoiceOptions = @(
		New-Object $x264guiExTChoiceDescription ("はい(&Y)",  "上書きを実行します。")
		New-Object $x264guiExTChoiceDescription ("いいえ(&N)", "上書きをせず、スキップして次の処理に進みます。")
	)

	$x264guiExChoiceResult = $host.ui.PromptForChoice($x264guiExChoiceTitle, $x264guiExChoiceMessage, $x264guiExChoiceOptions, 1)
	switch ($x264guiExChoiceResult) {
		0 {
			Write-Host -NoNewline "`r`nx264guiExのプロファイルを上書きします..."

			# AviUtl\plugins 内の x264guiEx_stg ディレクトリを削除する (待機)
			Start-Process powershell -ArgumentList "-command Remove-Item `"${aviutlPluginsDirectory}\x264guiEx_stg`" -Recurse" -WindowStyle Hidden -Wait

			# AviUtl\plugins 内に x264guiEx_stg ディレクトリを移動
			Move-Item x264guiEx_stg $aviutlPluginsDirectory -Force

			Write-Host "完了"
			break
		}
		1 {
			# 後で邪魔になるので削除
			Remove-Item x264guiEx_stg -Recurse

			Write-Host "`r`nx264guiExのプロファイルの上書きをスキップしました。"
			break
		}
	}

	# 選択ここまで
}

# AviUtl\plugins 内に現在のディレクトリのファイルを全て移動
Move-Item * $aviutlPluginsDirectory -Force

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
Write-Host -NoNewline "`r`n「AviUtlスクリプト一式」を確認しています..."

# カレントディレクトリを script ディレクトリに変更
Set-Location $aviutlScriptDirectory

# script ディレクトリ、またはそのサブディレクトリに @ANM1.anm があるか確認し、ある場合は
# $CheckAviUtlScriptSet (初期値: false) を true とする
$CheckAviUtlScriptSet = $false
if (Test-Path "${aviutlScriptDirectory}\@ANM1.anm") {
	$CheckAviUtlScriptSet = $true
} else {
	Get-ChildItem -Attributes Directory | ForEach-Object {
		if (Test-Path -Path "${_}\@ANM1.anm") {
			$CheckAviUtlScriptSet = $true
		}
	}
}

# カレントディレクトリを tmp ディレクトリに変更
Set-Location "${scriptFileRoot}\tmp"

Start-Sleep -Milliseconds 500

Write-Host "完了"

if (!($CheckAviUtlScriptSet)) {
	Write-Host -NoNewline "「AviUtlスクリプト一式」をダウンロードしています..."

	# 「AviUtlスクリプト一式」のzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL https://ss1.xrea.com/menkuri.s270.xrea.com/aviutl-installer-script/scripts/script_20160828.zip" -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "「AviUtlスクリプト一式」をインストールしています..."

	# AviUtl\script 内に さつき_AviUtlスクリプト一式 ディレクトリがあれば削除する (エラーの防止)
	if (Test-Path "${aviutlScriptDirectory}\さつき_AviUtlスクリプト一式") {
		Remove-Item "${aviutlScriptDirectory}\さつき_AviUtlスクリプト一式" -Recurse
	}

	# AviUtl\script 内に さつき_ANM_ssd ディレクトリがあれば削除する (エラーの防止)
	if (Test-Path "${aviutlScriptDirectory}\さつき_ANM_ssd") {
		Remove-Item "${aviutlScriptDirectory}\さつき_ANM_ssd" -Recurse
	}

	# AviUtl\script 内に さつき_TA_ssd ディレクトリがあれば削除する (エラーの防止)
	if (Test-Path "${aviutlScriptDirectory}\さつき_TA_ssd") {
		Remove-Item "${aviutlScriptDirectory}\さつき_TA_ssd" -Recurse
	}

	# 「AviUtlスクリプト一式」のzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path script_20160828.zip -Force" -WindowStyle Hidden -Wait

	# カレントディレクトリを script_20160828\script_20160828 ディレクトリに変更
	Set-Location script_20160828\script_20160828

	# ANM_ssd ディレクトリを さつき_ANM_ssd に、TA_ssd ディレクトリを さつき_TA_ssd にそれぞれリネーム (待機)
	Start-Process powershell -ArgumentList "-command Rename-Item `"ANM_ssd`" `"さつき_ANM_ssd`"; Rename-Item `"TA_ssd`" `"さつき_TA_ssd`"" -WindowStyle Hidden -Wait

	# AviUtl\script 内に さつき_AviUtlスクリプト一式 ディレクトリを、AviUtl\readme 内に AviUtlスクリプト一式 ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${aviutlScriptDirectory}\さつき_AviUtlスクリプト一式`", `"${ReadmeDirectoryRoot}\AviUtlスクリプト一式`" -ItemType Directory -Force" -WindowStyle Hidden -Wait

	# AviUtl\script 内に さつき_ANM_ssd と さつき_TA_ssd を、AviUtl\readme\AviUtlスクリプト一式 内に readme.txt と 使い方.txt を (待機) 、
	# AviUtl\script\さつき_AviUtlスクリプト一式 内にその他のファイルをそれぞれ移動
	Start-Process powershell -ArgumentList "-command Move-Item `"さつき_ANM_ssd`" $aviutlScriptDirectory -Force; Move-Item `"さつき_TA_ssd`" $aviutlScriptDirectory -Force; Move-Item *.txt `"${ReadmeDirectoryRoot}\AviUtlスクリプト一式`" -Force" -WindowStyle Hidden -Wait
	Move-Item * "${aviutlScriptDirectory}\さつき_AviUtlスクリプト一式" -Force

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..\..

	Write-Host "完了"
}

Write-Host -NoNewline "`r`n「値で図形」を確認しています..."

# カレントディレクトリを script ディレクトリに変更
Set-Location $aviutlScriptDirectory

# script ディレクトリ、またはそのサブディレクトリに 値で図形.obj があるか確認し、ある場合は
# $CheckShapeWithValuesObj (初期値: false) を true とする
$CheckShapeWithValuesObj = $false
if (Test-Path "${aviutlScriptDirectory}\値で図形.obj") {
	$CheckShapeWithValuesObj = $true
} else {
	Get-ChildItem -Attributes Directory | ForEach-Object {
		if (Test-Path -Path "${_}\値で図形.obj") {
			$CheckShapeWithValuesObj = $true
		}
	}
}

# カレントディレクトリを tmp ディレクトリに変更
Set-Location "${scriptFileRoot}\tmp"

Start-Sleep -Milliseconds 500

Write-Host "完了"

if (!($CheckShapeWithValuesObj)) {
	Write-Host -NoNewline "`r`n「値で図形」をダウンロードしています..."

	# 値で図形.obj をダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL `"https://ss1.xrea.com/menkuri.s270.xrea.com/aviutl-installer-script/scripts/値で図形.obj`"" -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "「値で図形」をインストールしています..."

	# AviUtl\script 内に 値で図形.obj を移動
	Move-Item "値で図形.obj" $aviutlScriptDirectory -Force

	Write-Host "完了"
}

Write-Host -NoNewline "`r`n直線スクリプトを確認しています..."

# カレントディレクトリを script ディレクトリに変更
Set-Location $aviutlScriptDirectory

# script ディレクトリ、またはそのサブディレクトリに 直線.obj があるか確認し、ある場合は
# $CheckStraightLineObj (初期値: false) を true とする
$CheckStraightLineObj = $false
if (Test-Path "${aviutlScriptDirectory}\直線.obj") {
	$CheckStraightLineObj = $true
} else {
	Get-ChildItem -Attributes Directory | ForEach-Object {
		if (Test-Path -Path "${_}\直線.obj") {
			$CheckStraightLineObj = $true
		}
	}
}

# カレントディレクトリを tmp ディレクトリに変更
Set-Location "${scriptFileRoot}\tmp"

Start-Sleep -Milliseconds 500

Write-Host "完了"

if (!($CheckStraightLineObj)) {
	Write-Host -NoNewline "`r`n直線スクリプトをダウンロードしています..."

	# 直線スクリプトのzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL `"https://ss1.xrea.com/menkuri.s270.xrea.com/aviutl-installer-script/scripts/直線スクリプト.zip`"" -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "直線スクリプトをインストールしています..."

	# 直線スクリプトのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path `"直線スクリプト.zip`" -Force" -WindowStyle Hidden -Wait

	# カレントディレクトリを 直線スクリプト ディレクトリに変更
	Set-Location "直線スクリプト"

	# AviUtl\readme, AviUtl\license 内に 直線スクリプト ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${ReadmeDirectoryRoot}\直線スクリプト`", `"${LicenseDirectoryRoot}\直線スクリプト`" -ItemType Directory -Force" -WindowStyle Hidden -Wait

	# AviUtl\script 内に 直線.obj を、AviUtl\license\直線スクリプト 内に LICENSE.txt を (待機) 、
	# AviUtl\readme\直線スクリプト 内にその他のファイルをそれぞれ移動
	Start-Process powershell -ArgumentList "-command Move-Item `"直線.obj`" $aviutlScriptDirectory -Force; Move-Item LICENSE.txt `"${LicenseDirectoryRoot}\直線スクリプト`" -Force" -WindowStyle Hidden -Wait
	Move-Item * "${ReadmeDirectoryRoot}\直線スクリプト" -Force

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..

	Write-Host "完了"
}


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


Write-Host "`r`nハードウェアエンコードの出力プラグイン (NVEnc / QSVEnc / VCEEnc) の状況を確認しています。"

$hwEncoders = [ordered]@{
	"NVEnc"  = "NVEncC.exe"
	"QSVEnc" = "QSVEncC.exe"
	"VCEEnc" = "VCEEncC.exe"
}

# ハードウェアエンコードの出力プラグインのインストールチェック用の変数を用意
$CheckHwEncoder = $false

foreach ($hwEncoder in $hwEncoders.GetEnumerator()) {
	# 導入の有無をチェック
	if (Test-Path "${aviutlPluginsDirectory}\$($hwEncoder.Key).auo") {
		Write-Host -NoNewline "`r`n$($hwEncoder.Key)が使用できるかチェックします..."

		# ハードウェアエンコードできるかチェック
		$process = Start-Process -FilePath "${aviutlExeDirectory}\exe_files\$($hwEncoder.Key)C\x86\$($hwEncoder.Value)" -ArgumentList "--check-hw" -Wait -WindowStyle Hidden -PassThru

		Write-Host "完了"

		# ExitCodeが0 (使用可能) の場合は更新、それ以外なら削除 (エラーの防止)
		if ($process.ExitCode -eq 0) {
			# ハードウェアエンコードの出力プラグインのインストールチェック用の変数を true に
			$CheckHwEncoder = $true

			Write-Host -NoNewline "$($hwEncoder.Key)を更新します。ダウンロードしています..."

			# 最新版のダウンロードURLを取得
			$downloadAllUrl = GithubLatestReleaseUrl "rigaya/$($hwEncoder.Key)"

			# 複数ある中からAviUtl用のもののみ残す
			$downloadUrl = $downloadAllUrl | Where-Object {$_ -like "*Aviutl*"}

			# zipファイルをダウンロード (待機)
			Start-Process -FilePath curl.exe -ArgumentList "-OL $downloadUrl" -WindowStyle Hidden -Wait

			# zipファイルを展開 (待機)
			Start-Process powershell -ArgumentList "-command Expand-Archive -Path Aviutl_$($hwEncoder.Key)_*.zip -Force" -WindowStyle Hidden -Wait

			# 展開されたディレクトリのパスを格納
			Set-Location "Aviutl_$($hwEncoder.Key)_*"
			$extdir = (Get-Location).Path
			Set-Location ..

			Write-Host "完了"

			# AviUtl\plugins 内に (NVEnc/QSVEnc/VCEEnc)_stg ディレクトリがあれば以下の処理を実行
			if (Test-Path "${aviutlPluginsDirectory}\$($hwEncoder.Key)_stg") {
				# プロファイルを上書きするかどうかユーザーに確認する (既定は 上書きしない)
				# 選択ここから

				$hwEncoderChoiceTitle = "$($hwEncoder.Key)のプロファイルを上書きしますか？"
				$hwEncoderChoiceMessage = "プロファイルは更新で新しくなっている可能性がありますが、上書きを実行すると追加したプロファイルやプロファイルへの変更が削除されます。"

				$hwEncoderTChoiceDescription = "System.Management.Automation.Host.ChoiceDescription"
				$hwEncoderChoiceOptions = @(
					New-Object $hwEncoderTChoiceDescription ("はい(&Y)",  "上書きを実行します。")
					New-Object $hwEncoderTChoiceDescription ("いいえ(&N)", "上書きをせず、スキップして次の処理に進みます。")
				)

				$hwEncoderChoiceResult = $host.ui.PromptForChoice($hwEncoderChoiceTitle, $hwEncoderChoiceMessage, $hwEncoderChoiceOptions, 1)
				switch ($hwEncoderChoiceResult) {
					0 {
						Write-Host -NoNewline "`r`n$($hwEncoder.Key)のプロファイルを上書きします..."

						# AviUtl\plugins 内の (NVEnc/QSVEnc/VCEEnc)_stg ディレクトリを削除する (待機)
						Start-Process powershell -ArgumentList "-command Remove-Item `"${aviutlPluginsDirectory}\$($hwEncoder.Key)_stg`" -Recurse" -WindowStyle Hidden -Wait

						# ダウンロードして展開した (NVEnc/QSVEnc/VCEEnc)_stg を AviUtl\plugins 内に移動
						Move-Item "$extdir\plugins\$($hwEncoder.Key)_stg" $aviutlPluginsDirectory -Force

						Write-Host "完了"
						break
					}
					1 {
						# 後で邪魔になるので削除
						Remove-Item "$extdir\plugins\$($hwEncoder.Key)_stg" -Recurse

						Write-Host "`r`n$($hwEncoder.Key)のプロファイルの上書きをスキップしました。"
						break
					}
				}

				# 選択ここまで
			}

			Write-Host -NoNewline "`r`n$($hwEncoder.Key)をインストールしています..."

			# AviUtl\exe_files\(NVEnc/QSVEnc/VCEEnc)C が後で邪魔になるので削除
			Remove-Item "${aviutlExeDirectory}\exe_files\$($hwEncoder.Key)C" -Recurse

			# readme ディレクトリを作成
			New-Item -ItemType Directory -Path "${ReadmeDirectoryRoot}\$($hwEncoder.Key)" -Force | Out-Null

			# 展開後のそれぞれのファイルを移動
			Move-Item -Path "$extdir\*.bat" -Destination $aviutlExeDirectory -Force
			Move-Item -Path "$extdir\plugins\*" -Destination $aviutlPluginsDirectory -Force
			Move-Item -Path "$extdir\exe_files\*" -Destination "${aviutlExeDirectory}\exe_files" -Force
			Move-Item -Path "$extdir\*_readme.txt" -Destination "${ReadmeDirectoryRoot}\$($hwEncoder.Key)" -Force

			Write-Host "完了"
		} else {
			Write-Host -NoNewline "$($hwEncoder.Key)は使用できません。削除しています..."

			# ファイルを削除
			Remove-Item "${aviutlExeDirectory}\exe_files\$($hwEncoder.Key)C" -Recurse
			Remove-Item "${aviutlPluginsDirectory}\$($hwEncoder.Key)*" -Recurse
			if (Test-Path "${ReadmeDirectoryRoot}\$($hwEncoder.Key)") {
				Remove-Item "${ReadmeDirectoryRoot}\$($hwEncoder.Key)" -Recurse
			}

			Write-Host "完了"
		}
	}
}

Write-Host "ハードウェアエンコードの出力プラグインの確認が完了しました。"


# ハードウェアエンコードの出力プラグインが1つも入っていない場合にインストールチェックする
if (!($CheckHwEncoder)) {
	# HWエンコーディングの使用可否をチェックし、可能であれば出力プラグインをインストール by Yu-yu0202 (20250107)

	Write-Host "`r`nハードウェアエンコード (NVEnc / QSVEnc / VCEEnc) が使用できるかチェックします。"
	Write-Host -NoNewline "必要なファイルをダウンロードしています (数分かかる場合があります) "

	$hwEncoderRepos = @("rigaya/NVEnc", "rigaya/QSVEnc", "rigaya/VCEEnc")
	foreach ($hwRepo in $hwEncoderRepos) {
		# あとで使うのでリポジトリ名を取っておく
		$repoName = ($hwRepo -split "/")[-1]

		# 最新版のダウンロードURLを取得
		$downloadAllUrl = GithubLatestReleaseUrl $hwRepo

		# 複数ある中からAviUtl用のもののみ残す
		$downloadUrl = $downloadAllUrl | Where-Object {$_ -like "*Aviutl*"}

		Write-Host -NoNewline "."

		# zipファイルをダウンロード (待機)
		Start-Process -FilePath curl.exe -ArgumentList "-OL $downloadUrl" -WindowStyle Hidden -Wait

		Write-Host -NoNewline "."

		# zipファイルを展開 (待機)
		Start-Process powershell -ArgumentList "-command Expand-Archive -Path Aviutl_${repoName}_*.zip -Force" -WindowStyle Hidden -Wait
	}

	Write-Host " 完了"
	Write-Host "`r`nエンコーダーのチェック、および使用可能な出力プラグインのインストールを行います。"

	# 画質のよいNVEncから順にQSVEnc、VCEEncとチェックしていき、最初に使用可能なものを確認した時点でそれを導入してforeachを離脱
	foreach ($hwEncoder in $hwEncoders.GetEnumerator()) {
		# エンコーダーの実行ファイルのパスを格納
		Set-Location "Aviutl_$($hwEncoder.Key)_*"
		$extdir = (Get-Location).Path
		$encoderPath = Join-Path -Path $extdir -ChildPath "exe_files\$($hwEncoder.Key)C\x86\$($hwEncoder.Value)"
		Set-Location ..

		# エンコーダーの実行ファイルの有無を確認
		if (Test-Path $encoderPath) {
			# ハードウェアエンコードできるかチェック
			$process = Start-Process -FilePath $encoderPath -ArgumentList "--check-hw" -Wait -WindowStyle Hidden -PassThru

			# ExitCodeが0の場合はインストール
			if ($process.ExitCode -eq 0) {
				# AviUtl\exe_files 内に $($hwEncoder.Key)C ディレクトリがあれば削除する (エラーの防止)
				if (Test-Path "C:\Applications\AviUtl\exe_files\$($hwEncoder.Key)C") {
					Remove-Item "C:\Applications\AviUtl\exe_files\$($hwEncoder.Key)C" -Recurse
				}

				# AviUtl\plugins 内に $($hwEncoder.Key)_stg ディレクトリがあれば削除する (エラーの防止)
				if (Test-Path "C:\Applications\AviUtl\plugins\$($hwEncoder.Key)_stg") {
					Remove-Item "C:\Applications\AviUtl\plugins\$($hwEncoder.Key)_stg" -Recurse
				}

				Write-Host -NoNewline "$($hwEncoder.Key)が使用可能です。$($hwEncoder.Key)をインストールしています..."

				# readme ディレクトリを作成
				New-Item -ItemType Directory -Path C:\Applications\AviUtl\readme\$($hwEncoder.Key) -Force | Out-Null

				# 展開後のそれぞれのファイルを移動
				Move-Item -Path "$extdir\exe_files\*" -Destination C:\Applications\AviUtl\exe_files -Force
				Move-Item -Path "$extdir\plugins\*" -Destination C:\Applications\AviUtl\plugins -Force
				Move-Item -Path "$extdir\*.bat" -Destination C:\Applications\AviUtl -Force
				Move-Item -Path "$extdir\*_readme.txt" -Destination C:\Applications\AviUtl\readme\$($hwEncoder.Key) -Force

				Write-Host "完了"

				# 一応、出力プラグインが共存しないようbreakでforeachを抜ける
				break

			# 最後のVCEEncも使用不可だった場合、ハードウェアエンコードが使用できない旨のメッセージを表示
			} elseif ($($hwEncoder.Key) -eq "VCEEnc") {
				Write-Host "この環境ではハードウェアエンコードは使用できません。"
			}

		# エンコーダーの実行ファイルが確認できない場合、エラーメッセージを表示する
		} else {
			Write-Host "発生したエラー: エンコーダーのチェックに失敗しました。`r`nエラーの原因　: $($hwEncoder.Key)の実行ファイルが確認できません。"
		}
	}
}


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
