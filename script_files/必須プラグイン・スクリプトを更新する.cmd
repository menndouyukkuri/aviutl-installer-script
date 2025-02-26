@powershell -NoProfile -ExecutionPolicy Unrestricted "$s = [scriptblock]::create((Get-Content \"%~f0\" | Where-Object {$_.readcount -gt 1}) -join \"`n\"); & $s \"%~dp0 %*\"" & goto:eof

# これ以降は全てPowerShellのスクリプト

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

param (
	# カレントディレクトリのパス
	[string]$scriptFileRoot = (Get-Location).Path ,

	# AviUtlをインストールするディレクトリのパス
	[string]$Path
)

$Host.UI.RawUI.WindowTitle = "必須プラグイン・スクリプトを更新する.cmd"
Write-Host "必須プラグイン (patch.aul・L-SMASH Works・InputPipePlugin・x264guiEx) および LuaJIT、ifheif の更新を開始します。`r`n`r`n"

# settings ディレクトリの場所を確認
if (Test-Path ".\settings") {
	$settingsDirectoryPath = Convert-Path ".\settings"
} elseif (Test-Path "..\settings") {
	$settingsDirectoryPath = Convert-Path "..\settings"
} else {
	Write-Host "発生したエラー: settings フォルダが見つかりません。"
	Pause
	exit
}

# AviUtl Installer Scriptのzipファイルが展開されたと思われるディレクトリのパスを保存
$AisRootDir = Split-Path $settingsDirectoryPath -Parent

Write-Host -NoNewline "準備中..."

# AviUtl Installer Scriptのzipファイルが展開されたと思われるディレクトリ ($AisRootDir) 内の
# .cmd ファイルと .ps1 ファイルのブロックを解除 (実行時に無駄な警告を表示させないため)
Get-ChildItem -Path $AisRootDir -Include "*.cmd", "*.ps1" -Recurse | Unblock-File

Start-Sleep -Milliseconds 500

# script_files ディレクトリのパスを $scriptFilesDirectoryPath に格納
	# settings ディレクトリと同じ親ディレクトリを持つことを前提としているので注意
$scriptFilesDirectoryPath = Join-Path -Path $AisRootDir -ChildPath script_files

# script_files\ais-shared-function.ps1 を読み込み
. "${scriptFilesDirectoryPath}\ais-shared-function.ps1"

# script_files\PSConvertFromJsonEditable\ConvertFrom-JsonEditable.ps1 を読み込み
	# PSConvertFromJsonEditable (Author: ShwIws)
. "${scriptFilesDirectoryPath}\PSConvertFromJsonEditable\ConvertFrom-JsonEditable.ps1"

# 動作環境を事前にチェックし、問題がある場合は終了するかメッセージを表示する (ais-shared-function.ps1 の関数)
CheckOfEnvironment

Write-Host "完了"
Write-Host -NoNewline "`r`nAviUtlがインストールされているフォルダを確認しています..."

Start-Sleep -Milliseconds 500

# aviutl.exe が入っているディレクトリを探し、$Path にパスを保存
if (($null -ne $Path) -and (Test-Path "${Path}\aviutl.exe")) {
	# 既にパラメータとして aviutl.exe が入っているディレクトリが渡されている場合、メッセージだけ表示
	Write-Host "完了"
} elseif (Test-Path "C:\AviUtl\aviutl.exe") {
	$Path = "C:\AviUtl"
	Write-Host "完了"
} elseif (Test-Path "C:\Applications\AviUtl\aviutl.exe") {
	$Path = "C:\Applications\AviUtl"
	Write-Host "完了"
} else { # 確認できなかった場合、ユーザーにパスを入力させる
	# 1周目のメッセージの表示用に false に
	$PathIncludingSpace = $false

	# ユーザーにパスを入力させ、aviutl.exe が入っていることを確認したらループを抜ける
	do {
		if (!($PathIncludingSpace)) {
			Write-Host "完了"
			Write-Host "AviUtlがインストールされているフォルダが確認できませんでした。`r`n"
		}

		Write-Host "aviutl.exe のパス、または aviutl.exe が入っているフォルダのパスを入力し、Enter を押してください。"
		Write-Host -NoNewline "> "
		$userInputAviutlExePath = $Host.UI.ReadLine()

		# 入力されたパスにスペースが含まれている場合
		if ($userInputAviutlExePath.Contains(" ")) {
			$PathIncludingSpace = $true

			Write-Host "`r`nパスにスペースが含まれていると、不具合の原因になるため許可されていません。"

			# ユーザーの入力をもとに aviutl.exe の入っているディレクトリのパスを $Path に代入
			if ($userInputAviutlExePath -match "\\aviutl\.exe") {
				$Path = Split-Path $userInputAviutlExePath -Parent
			} else {
				$Path = $userInputAviutlExePath
			}

			# aviutl.exe の入ったフォルダの名前にしかスペースがないのか、それ以外にもスペースがあるのかを判別してメッセージを変える
			$PathParent = Split-Path $Path -Parent
			if ($PathParent.Contains(" ")) {
				Write-Host "aviutl.exe が入っているフォルダの場所を変更するなどして、パスにスペースが含まれないようにしてください。`r`n"
			} else {
				Write-Host "aviutl.exe が入っているフォルダの名前を変更するなどして、パスにスペースが含まれないようにしてください。`r`n"
			}
		# 入力されたパスにスペースが含まれていない場合
		} else {
			$PathIncludingSpace = $false

			# ユーザーの入力をもとに aviutl.exe の入っているディレクトリのパスを $Path に代入
			if ($userInputAviutlExePath -match "\\aviutl\.exe") {
				$Path = Split-Path $userInputAviutlExePath -Parent
			} else {
				$Path = $userInputAviutlExePath
			}

			Write-Host -NoNewline "`r`nAviUtlがインストールされているフォルダを確認しています..."
		}
	} while (!(Test-Path "${Path}\aviutl.exe") -or $PathIncludingSpace)
	Write-Host "完了"
}

Write-Host "${Path} に aviutl.exe を確認しました。"
Write-Host -NoNewline "`r`napm.json を確認しています..."

# apm.json が存在する場合、$apmJsonHash に読み込み、$apmJsonExist に true を格納
$apmJsonExist = $false
if (Test-Path "${Path}\apm.json") {
	$apmJsonHash = Get-Content "${Path}\apm.json" | ConvertFrom-JsonEditable
	$apmJsonExist = $true

# apm.json が存在しない場合、apm.json の元になるハッシュテーブルを用意して $apmJsonHash に代入
} else {
	$apmJsonHash = [ordered]@{
		"dataVersion" = "3"
		"core" = [ordered]@{
			"aviutl" = "1.10"
			"exedit" = "0.92"
		}
		"packages" = [ordered]@{
			"nazono/patch" = [ordered]@{
				"id" = "nazono/patch"
				"version" = "r43_69"
			}
			"MrOjii/LSMASHWorks" = [ordered]@{
				"id" = "MrOjii/LSMASHWorks"
				"version" = "2025/02/18"
			}
			"amate/InputPipePlugin" = [ordered]@{
				"id" = "amate/InputPipePlugin"
				"version" = "v2.0_1"
			}
			"rigaya/x264guiEx" = [ordered]@{
				"id" = "rigaya/x264guiEx"
				"version" = "3.31"
			}
			"amate/MFVideoReader" = [ordered]@{
				"id" = "amate/MFVideoReader"
				"version" = "v1.0"
			}
			"satsuki/satsuki" = [ordered]@{
				"id" = "satsuki/satsuki"
				"version" = "20160828"
			}
			"nagomiku/paracustomobj" = [ordered]@{
				"id" = "nagomiku/paracustomobj"
				"version" = "v2.10"
			}
			"ePi/LuaJIT" = [ordered]@{
				"id" = "ePi/LuaJIT"
				"version" = "2.1.0-beta3"
			}
		}
	}
}

Write-Host "完了"
Write-Host -NoNewline "`r`nais.json を確認しています..."

# ais.json が存在する場合、$aisJsonHash に読み込み、$aisJsonExist に true を格納
$aisJsonExist = $false
if (Test-Path "${Path}\ais.json") {
	$aisJsonHash = Get-Content "${Path}\ais.json" | ConvertFrom-JsonEditable
	$aisJsonExist = $true

# ais.json が存在しない場合、ais.json の元になるハッシュテーブルを用意して $aisJsonHash に代入
} else {
	$aisJsonHash = [ordered]@{
		"dataVersion" = "1"
		"packages" = [ordered]@{
			"TORO/iftwebp" = @{
				"version" = "1.1"
			}
			"Mr-Ojii/ifheif" = @{
				"version" = "r62"
			}
			"tikubonn/straightLineObj" = @{
				"version" = "2021/03/07"
			}
			"Per-Terra/LuaJIT" = @{
				"version" = "2025/02/20"
			}
		}
	}
}

Write-Host "完了"
Write-Host -NoNewline "`r`n一時的にファイルを保管するフォルダを作成しています..."

# AviUtl ディレクトリ内に plugins, script, license, readme の4つのディレクトリを作成する (待機)
$aviutlPluginsDirectory = Join-Path -Path $Path -ChildPath plugins
$aviutlScriptDirectory = Join-Path -Path $Path -ChildPath script
$LicenseDirectoryRoot = Join-Path -Path $Path -ChildPath license
$ReadmeDirectoryRoot = Join-Path -Path $Path -ChildPath readme
Start-Process powershell -ArgumentList "-command New-Item $aviutlPluginsDirectory, $aviutlScriptDirectory, $LicenseDirectoryRoot, $ReadmeDirectoryRoot -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

# tmp ディレクトリを作成する (待機)
Start-Process powershell -ArgumentList "-command New-Item tmp -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

# カレントディレクトリを tmp ディレクトリに変更
Set-Location tmp

Write-Host "完了"
Write-Host -NoNewline "`r`nフォルダーオプションを確認しています..."

# フォルダーオプションの「登録されている拡張子は表示しない」が有効の場合、無効にする
$ExplorerAdvancedRegKey = Get-ItemProperty -LiteralPath "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if ($ExplorerAdvancedRegKey.HideFileExt -ne "0") {
	Write-Host "完了"
	Write-Host -NoNewline "「登録されている拡張子は表示しない」を無効にしています..."

	# C:\Applications\AviUtl-Installer-Script ディレクトリを作成する (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"C:\Applications\AviUtl-Installer-Script`" -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion" をバックアップ (待機)
	Start-Process powershell -ArgumentList "-command reg export `"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion`" `"C:\Applications\AviUtl-Installer-Script\Backup.reg`"" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" がない場合、作成する (待機)
	if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced")) {
		Start-Process powershell -ArgumentList "-command New-Item `"HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced`" -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait
	}

	# レジストリを書き換えて「登録されている拡張子は表示しない」を無効化
	Set-ItemProperty -LiteralPath "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value "0" -Force
}

Write-Host "完了"
Write-Host -NoNewline "`r`nAviUtl本体のバージョンを確認しています..."

# apm.json が存在する場合、AviUtlのバージョンを参照して1.10でなければ更新する。また、apm.json が存在しない場合、
# aviutl.vfp を発見したら1.00以前の可能性があるため更新する (1.10には aviutl.vfp は付属しないため)
if (($apmJsonExist -and ($apmJsonHash["core"]["aviutl"] -ne "1.10")) -or
	(($apmJsonExist -eq $false) -and (Test-Path "${Path}\aviutl.vfp"))) {
	Write-Host "完了"
	Write-Host -NoNewline "AviUtl本体 (version 1.10) をダウンロードしています..."

	# AviUtl version 1.10のzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL http://spring-fragrance.mints.ne.jp/aviutl/aviutl110.zip" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "AviUtl本体をインストールしています..."

	# AviUtlのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path aviutl110.zip -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# カレントディレクトリを aviutl110 ディレクトリに変更
	Set-Location aviutl110

	# AviUtl\readme 内に aviutl ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${ReadmeDirectoryRoot}\aviutl`" -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# AviUtl ディレクトリ内に aviutl.exe と aviutl.txt を移動
	Move-Item "aviutl.exe", "aviutl.txt" $Path -Force
	
	# 不要な aviutl.vfp を削除
	Remove-Item "${Path}\aviutl.vfp"

	# VFPluginがレジストリに登録されているか確認
	if (Test-Path "HKCU:\Software\VFPlugin") {
		# aviutl.vfp のレジストリへのVFPlugin登録を確認
		$vfpluginRegKey = Get-ItemProperty "HKCU:\Software\VFPlugin"
		if ($null -ne $vfpluginRegKey.AviUtl) {
			# aviutl.vfp のレジストリへのVFPlugin登録を削除
			Remove-ItemProperty -Path "HKCU:\Software\VFPlugin" -Name AviUtl
		}
	}

	# apm.json のAviUtlのバージョンを更新
	$apmJsonHash["core"]["aviutl"] = "1.10"

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..

	# AviUtl\readme\aviutl 内に aviutl.txt をコピー
	Copy-Item "${Path}\aviutl.txt" "${ReadmeDirectoryRoot}\aviutl" -Force
}

Write-Host "完了"
Write-Host -NoNewline "`r`n拡張編集Pluginのインストールされているフォルダを確認しています..."

# 拡張編集Pluginが plugins ディレクトリ内にある場合、AviUtl ディレクトリ内に移動させる (エラーの防止)
if (Test-Path "${aviutlPluginsDirectory}\exedit.auf") {
	# カレントディレクトリを plugins ディレクトリに変更
	Set-Location $aviutlPluginsDirectory

	# 拡張編集Pluginのファイルを全て AviUtl ディレクトリ内に移動
	Move-Item "exedit*" $Path -Force
	Move-Item lua51.dll $Path -Force
	if (Test-Path "${aviutlPluginsDirectory}\lua.txt") {
		Move-Item lua.txt $Path -Force
	}
	if (Test-Path "${aviutlPluginsDirectory}\lua51jit.dll") {
		Move-Item lua51jit.dll $Path -Force
	}

	# script ディレクトリの場所も併せて変更
	if (Test-Path "${aviutlPluginsDirectory}\script") {
		Move-Item "${aviutlPluginsDirectory}\script" $Path -Force
	}

	# Susieプラグインの場所も併せて変更
	if (Test-Path "${aviutlPluginsDirectory}\*.spi") {
		Move-Item "*.spi" $Path -Force
	}

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location "${scriptFileRoot}\tmp"
}

Write-Host "完了"

# 拡張編集Pluginが見つからない場合、拡張編集Pluginをダウンロードして導入する
# apm.json が存在する場合、拡張編集Pluginのバージョンを参照して0.92でなければ置き換える。また、apm.json が
# 存在しない場合、拡張編集Plugin 0.93テスト版にのみ付属する lua51jit.dll を発見したら0.92で置き換える
if ((!(Test-Path "${Path}\exedit.auf")) -or
	($apmJsonExist -and ($apmJsonHash["core"]["exedit"] -ne "0.92")) -or
	(($apmJsonExist -eq $false) -and (Test-Path "${Path}\lua51jit.dll"))) {
	Write-Host -NoNewline "`r`n拡張編集Plugin version 0.92をダウンロードしています..."

	# 拡張編集Plugin version 0.92のzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL http://spring-fragrance.mints.ne.jp/aviutl/exedit92.zip" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "拡張編集Pluginをインストールしています..."

	# 拡張編集Pluginのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path exedit92.zip -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# カレントディレクトリを exedit92 ディレクトリに変更
	Set-Location exedit92

	# AviUtl\readme 内に exedit ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${ReadmeDirectoryRoot}\exedit`" -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# exedit.ini は使用せず、かつこの後の処理で邪魔になるので削除する (待機)
	Start-Process powershell -ArgumentList "-command Remove-Item exedit.ini" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# AviUtl ディレクトリ内にファイルを全て移動
	Move-Item * $Path -Force

	# 不要な lua51jit.dll を削除
	if (Test-Path "${Path}\lua51jit.dll") {
		Remove-Item "${Path}\lua51jit.dll"
	}

	# apm.json の拡張編集Pluginのバージョンを更新
	$apmJsonHash["core"]["exedit"] = "0.92"

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..

	Write-Host "完了"

	# AviUtl\readme\exedit 内に exedit.txt, lua.txt をコピー
	Copy-Item "${Path}\exedit.txt", "${Path}\lua.txt" "${ReadmeDirectoryRoot}\exedit" -Force
}

Write-Host -NoNewline "`r`npatch.aul (謎さうなフォーク版) の最新版情報を取得しています..."

# patch.aul (謎さうなフォーク版) の最新版のダウンロードURLを取得
$patchAulGithubApi = GithubLatestRelease "nazonoSAUNA/patch.aul"
$patchAulUrl = $patchAulGithubApi.assets.browser_download_url

# apm.json があり、かつ最新版の情報が記載されている場合はスキップする
if (!($apmJsonExist -and $apmJsonHash.packages.Contains("nazono/patch") -and
	($apmJsonHash["packages"]["nazono/patch"]["version"] -eq $patchAulGithubApi.tag_name))) {
	Write-Host "完了"
	Write-Host -NoNewline "patch.aul (謎さうなフォーク版) をダウンロードしています..."

	# patch.aul (謎さうなフォーク版) のzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $patchAulUrl" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "patch.aul (謎さうなフォーク版) をインストールしています..."

	# patch.aulのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path patch.aul_*.zip -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# カレントディレクトリをpatch.aulのzipファイルを展開したディレクトリに変更
	Set-Location "patch.aul_*"

	# AviUtl\license 内に patch-aul ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${LicenseDirectoryRoot}\patch-aul`" -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# patch.aul が plugins ディレクトリ内にある場合、削除して patch.aul.json を移動させる (エラーの防止)
	if (Test-Path "${aviutlPluginsDirectory}\patch.aul") {
		Remove-Item "${aviutlPluginsDirectory}\patch.aul"
		if ((Test-Path "${aviutlPluginsDirectory}\patch.aul.json") -and (!(Test-Path "${Path}\patch.aul.json"))) {
			Move-Item "${aviutlPluginsDirectory}\patch.aul.json" $Path -Force
		} elseif (Test-Path "${aviutlPluginsDirectory}\patch.aul.json") {
			Remove-Item "${aviutlPluginsDirectory}\patch.aul.json"
		}
	}

	# AviUtl ディレクトリ内に patch.aul を (待機) 、AviUtl\license\patch-aul 内にその他のファイルをそれぞれ移動
	Start-Process powershell -ArgumentList "-command Move-Item patch.aul $Path -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait
	Move-Item * "${LicenseDirectoryRoot}\patch-aul" -Force

	# apm.json に ePi/patch が登録されている場合は削除
	if ($apmJsonHash.packages.Contains("ePi/patch")) {
		$apmJsonHash.packages.Remove("ePi/patch")
	}

	# apm.json に sets/scrapboxAviUtl が登録されている場合は削除
	if ($apmJsonHash.packages.Contains("sets/scrapboxAviUtl")) {
		$apmJsonHash.packages.Remove("sets/scrapboxAviUtl")
	}

	# apm.json に nazono/patch が登録されていない場合はキーを作成してidを登録
	if (!($apmJsonHash.packages.Contains("nazono/patch"))) {
		$apmJsonHash["packages"]["nazono/patch"] = [ordered]@{}
		$apmJsonHash["packages"]["nazono/patch"]["id"] = "nazono/patch"
	}

	# apm.json の nazono/patch のバージョンを更新
	$apmJsonHash["packages"]["nazono/patch"]["version"] = $patchAulGithubApi.tag_name

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..
}

Write-Host "完了"
Write-Host -NoNewline "`r`npatch.aul (謎さうなフォーク版) と競合するプラグインの有無を確認しています..."

# bakusoku.auf を確認し、あったら削除
if (Test-Path "${Path}\bakusoku.auf") {
	Remove-Item "${Path}\bakusoku.auf"
}
if (Test-Path "${aviutlPluginsDirectory}\bakusoku.auf") {
	Remove-Item "${aviutlPluginsDirectory}\bakusoku.auf"
}
Get-ChildItem -Path $aviutlPluginsDirectory -Directory | ForEach-Object {
	if (Test-Path -Path "${_}\bakusoku.auf") {
		Remove-Item "${_}\bakusoku.auf"
	}
}

# apm.json に suzune/bakusoku が登録されている場合は削除
if ($apmJsonHash.packages.Contains("suzune/bakusoku")) {
	$apmJsonHash.packages.Remove("suzune/bakusoku")
}

# Boost.auf を確認し、あったら削除
if (Test-Path "${Path}\Boost.auf") {
	Remove-Item "${Path}\Boost.auf"
}
if (Test-Path "${aviutlPluginsDirectory}\Boost.auf") {
	Remove-Item "${aviutlPluginsDirectory}\Boost.auf"
}
Get-ChildItem -Path $aviutlPluginsDirectory -Directory | ForEach-Object {
	if (Test-Path -Path "${_}\Boost.auf") {
		Remove-Item "${_}\Boost.auf"
	}
}

# apm.json に suzune/bakusoku が登録されている場合は削除
if ($apmJsonHash.packages.Contains("yanagi/Boost")) {
	$apmJsonHash.packages.Remove("yanagi/Boost")
}

Write-Host "完了"
Write-Host -NoNewline "`r`nL-SMASH Works (Mr-Ojii版) の最新版情報を取得しています..."

# L-SMASH Worksの入っているディレクトリを探し、$lwinputAuiDirectory にパスを保存
# $inputPipePluginDeleteCheckDirectory は $lwinputAuiDirectory の逆、後に使用
if (Test-Path "${Path}\lwinput.aui") {
	$lwinputAuiDirectory = $Path
	$inputPipePluginDeleteCheckDirectory = $aviutlPluginsDirectory
} else {
	$lwinputAuiDirectory = $aviutlPluginsDirectory
	$inputPipePluginDeleteCheckDirectory = $Path
}

# L-SMASH Works (Mr-Ojii版) の最新版のダウンロードURLを取得
$lSmashWorksGithubApi = GithubLatestRelease "Mr-Ojii/L-SMASH-Works-Auto-Builds"
$lSmashWorksAllUrl = $lSmashWorksGithubApi.assets.browser_download_url

# 複数ある中からAviUtl用のもののみ残す
$lSmashWorksUrl = $lSmashWorksAllUrl | Where-Object {$_ -like "*Mr-Ojii_vimeo*"}

# apm.json 用にタグ名を取得してビルド日だけ取り出し yyyy/mm/dd に整形
$lSmashWorksTagNameSplitArray = ($lSmashWorksGithubApi.tag_name) -split "-"
$lSmashWorksBuildDate = $lSmashWorksTagNameSplitArray[1] + "/" + $lSmashWorksTagNameSplitArray[2] + "/" + $lSmashWorksTagNameSplitArray[3]

# apm.json のL-SMASH Worksのバージョンを / で分割して $apmJsonLSmashWorksVersionArray に格納
if ($apmJsonExist -and $apmJsonHash.packages.Contains("MrOjii/LSMASHWorks")) {
	$apmJsonLSmashWorksVersionArray = $apmJsonHash["packages"]["MrOjii/LSMASHWorks"]["version"] -split "/"
} else {
	$apmJsonLSmashWorksVersionArray = 0, 0, 0
}

# $lSmashWorksUpdate にL-SMASH Worksを更新するかどうかを格納
$lSmashWorksUpdate = $true

# apm.json の年 > 取得したビルド日の年
if ($apmJsonLSmashWorksVersionArray[0] -gt $lSmashWorksTagNameSplitArray[1]) {
	$lSmashWorksUpdate = $false

# apm.json の年 < 取得したビルド日の年
} elseif ($apmJsonLSmashWorksVersionArray[0] -lt $lSmashWorksTagNameSplitArray[1]) {
	# if文を離脱、これより下の条件は apm.json の年 = 取得したビルド日の年

# apm.json の月 > 取得したビルド日の月
} elseif ($apmJsonLSmashWorksVersionArray[1] -gt $lSmashWorksTagNameSplitArray[2]) {
	$lSmashWorksUpdate = $false

# apm.json の月 < 取得したビルド日の月
} elseif ($apmJsonLSmashWorksVersionArray[1] -lt $lSmashWorksTagNameSplitArray[2]) {
	# if文を離脱、これより下の条件は apm.json の月 = 取得したビルド日の月

# apm.json の日 >= 取得したビルド日の日
} elseif ($apmJsonLSmashWorksVersionArray[2] -ge $lSmashWorksTagNameSplitArray[3]) {
	$lSmashWorksUpdate = $false
}

# apm.json のバージョンより取得したビルド日の方が新しい場合は更新する
if ($lSmashWorksUpdate) {
	Write-Host "完了"
	Write-Host -NoNewline "L-SMASH Works (Mr-Ojii版) をダウンロードしています..."

	# L-SMASH Works (Mr-Ojii版) のzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $lSmashWorksUrl" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "L-SMASH Works (Mr-Ojii版) をインストールしています..."

	# AviUtl\license\l-smash_works 内に Licenses ディレクトリがあれば削除する (エラーの防止)
	if (Test-Path "${LicenseDirectoryRoot}\l-smash_works\Licenses") {
		Remove-Item "${LicenseDirectoryRoot}\l-smash_works\Licenses" -Recurse
	}

	# AviUtl ディレクトリやそのサブディレクトリ内の .lwi ファイルを削除する (エラーの防止)
	if (Test-Path "*.lwi") {
		Remove-Item "*.lwi"
	}
	Get-ChildItem -Path $Path -Directory -Recurse | ForEach-Object {
		if (Test-Path -Path "${_}\*.lwi") {
			Remove-Item "${_}\*.lwi"
		}
	}

	# L-SMASH Worksのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path L-SMASH-Works_*.zip -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# カレントディレクトリをL-SMASH Worksのzipファイルを展開したディレクトリに変更
	Set-Location "L-SMASH-Works_*"

	# AviUtl\readme, AviUtl\license 内に l-smash_works ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${ReadmeDirectoryRoot}\l-smash_works`", `"${LicenseDirectoryRoot}\l-smash_works`" -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# $lwinputAuiDirectory ディレクトリ内に lw*.au* を、AviUtl\readme\l-smash_works 内に READM* を (待機) 、
	# AviUtl\license\l-smash_works 内にその他のファイルをそれぞれ移動
	Start-Process powershell -ArgumentList "-command Move-Item lw*.au* $lwinputAuiDirectory -Force; Move-Item READM* `"${ReadmeDirectoryRoot}\l-smash_works`" -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait
	Move-Item * "${LicenseDirectoryRoot}\l-smash_works" -Force

	# apm.json に pop4bit/LSMASHWorks が登録されている場合は削除
	if ($apmJsonHash.packages.Contains("pop4bit/LSMASHWorks")) {
		$apmJsonHash.packages.Remove("pop4bit/LSMASHWorks")
	}

	# apm.json に VFRmaniac/LSMASHWorks が登録されている場合は削除
	if ($apmJsonHash.packages.Contains("VFRmaniac/LSMASHWorks")) {
		$apmJsonHash.packages.Remove("VFRmaniac/LSMASHWorks")
	}

	# apm.json に HolyWu/LSMASHWorks が登録されている場合は削除
	if ($apmJsonHash.packages.Contains("HolyWu/LSMASHWorks")) {
		$apmJsonHash.packages.Remove("HolyWu/LSMASHWorks")
	}

	# apm.json に MrOjii/LSMASHWorks が登録されていない場合はキーを作成してidを登録
	if (!($apmJsonHash.packages.Contains("MrOjii/LSMASHWorks"))) {
		$apmJsonHash["packages"]["MrOjii/LSMASHWorks"] = [ordered]@{}
		$apmJsonHash["packages"]["MrOjii/LSMASHWorks"]["id"] = "MrOjii/LSMASHWorks"
	}

	# apm.json の MrOjii/LSMASHWorks のバージョンを更新
	$apmJsonHash["packages"]["MrOjii/LSMASHWorks"]["version"] = $lSmashWorksBuildDate

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..
}

# L-SMASH Worksの設定ファイルが見つからない場合のみ、以下の処理を実行
if (!(Test-Path "${lwinputAuiDirectory}\lsmash.ini")) {
	Copy-Item "${settingsDirectoryPath}\lsmash.ini" $lwinputAuiDirectory
}

Write-Host "完了"
Write-Host -NoNewline "`r`nInputPipePluginの最新版情報を取得しています..."

# InputPipePluginの最新版のダウンロードURLを取得
$InputPipePluginGithubApi = GithubLatestRelease "amate/InputPipePlugin"
$InputPipePluginUrl = $InputPipePluginGithubApi.assets.browser_download_url

# GitHubから取得した情報をもとに、apm.json に記載されているバージョンを比較するために形式を合わせたバージョン名を
# $InputPipePluginLatestApmFormat に格納する
	# 基本的には取得したタグ名をそのまま格納すればよい。
	# ただし、AviUtl Package Manager が L-SMASH Works と InputPipePlugin のネイティブ64bit対応の
	# ファイルをインストールしなかった問題 (Issue: https://github.com/team-apm/apm/issues/1666 etc.)
	# の修正により、区別のため apm.json には InputPipePlugin のバージョン2.0が v2.0_1 と記載されるように
	# なっている模様。そのため、v2.0 の場合はそのまま登録するのではなく v2.0_1 とする。
	# 参考: https://github.com/team-apm/apm-data/commit/240a170cc0b121f9b9d1edbe20f19f89146f03aa
if ($InputPipePluginGithubApi.tag_name -eq "v2.0") {
	$InputPipePluginLatestApmFormat = "v2.0_1"
} else {
	$InputPipePluginLatestApmFormat = $InputPipePluginGithubApi.tag_name
}

# apm.json があり、かつ最新版の情報が記載されている場合はスキップする
if (!($apmJsonExist -and $apmJsonHash.packages.Contains("amate/InputPipePlugin") -and
	($apmJsonHash["packages"]["amate/InputPipePlugin"]["version"] -eq $InputPipePluginLatestApmFormat))) {
	Write-Host "完了"
	Write-Host -NoNewline "InputPipePluginをダウンロードしています..."

	# InputPipePluginのzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $InputPipePluginUrl" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "InputPipePluginをインストールしています..."

	# InputPipePluginのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path InputPipePlugin_*.zip -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# カレントディレクトリをInputPipePluginのzipファイルを展開したディレクトリに変更
	Set-Location "InputPipePlugin_*\InputPipePlugin"

	# AviUtl\readme, AviUtl\license 内に inputPipePlugin ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${ReadmeDirectoryRoot}\inputPipePlugin`", `"${LicenseDirectoryRoot}\inputPipePlugin`" -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# AviUtl\license\inputPipePlugin 内に LICENSE を、AviUtl\readme\inputPipePlugin 内に Readme.md を (待機) 、
	# $lwinputAuiDirectory ディレクトリ内にその他のファイルをそれぞれ移動
	Start-Process powershell -ArgumentList "-command Move-Item LICENSE `"${LicenseDirectoryRoot}\inputPipePlugin`" -Force; Move-Item Readme.md `"${ReadmeDirectoryRoot}\inputPipePlugin`" -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait
	Move-Item * $lwinputAuiDirectory -Force

	# トラブルの原因になるファイルの除去
	Set-Location $inputPipePluginDeleteCheckDirectory
	if (Test-Path "InputPipe*") {
		Remove-Item "InputPipe*"
	}
	Set-Location $scriptFileRoot

	# apm.json に amate/InputPipePlugin が登録されていない場合はキーを作成してidを登録
	if (!($apmJsonHash.packages.Contains("amate/InputPipePlugin"))) {
		$apmJsonHash["packages"]["amate/InputPipePlugin"] = [ordered]@{}
		$apmJsonHash["packages"]["amate/InputPipePlugin"]["id"] = "amate/InputPipePlugin"
	}

	# apm.json の amate/InputPipePlugin のバージョンを更新
	if ($InputPipePluginGithubApi.tag_name -eq "v2.0") {
		$apmJsonHash["packages"]["amate/InputPipePlugin"]["version"] = "v2.0_1"
	} else {
		$apmJsonHash["packages"]["amate/InputPipePlugin"]["version"] = $InputPipePluginGithubApi.tag_name
	}

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location tmp
}

Write-Host "完了"
Write-Host -NoNewline "`r`nx264guiExの最新版情報を取得しています..."

# x264guiExの最新版のダウンロードURLを取得
$x264guiExGithubApi = GithubLatestRelease "rigaya/x264guiEx"
$x264guiExUrl = $x264guiExGithubApi.assets.browser_download_url

# apm.json があり、かつ最新版の情報が記載されている場合はスキップする
if (!($apmJsonExist -and $apmJsonHash.packages.Contains("rigaya/x264guiEx") -and
	($apmJsonHash["packages"]["rigaya/x264guiEx"]["version"] -eq $x264guiExGithubApi.tag_name))) {
	Write-Host "完了"
	Write-Host -NoNewline "x264guiExをダウンロードしています..."

	# x264guiExのzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $x264guiExUrl" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# x264guiExのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path x264guiEx_*.zip -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# カレントディレクトリをx264guiExのzipファイルを展開したディレクトリに変更
	Set-Location "x264guiEx_*\x264guiEx_*"

	# カレントディレクトリをx264guiExのzipファイルを展開したディレクトリ内の plugins ディレクトリに変更
	Set-Location plugins

	Write-Host "完了"

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
				Write-Host -NoNewline "プロファイルを上書きします..."

				# AviUtl\plugins 内の x264guiEx_stg ディレクトリを削除する (待機)
				Start-Process powershell -ArgumentList "-command Remove-Item `"${aviutlPluginsDirectory}\x264guiEx_stg`" -Recurse" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

				# AviUtl\plugins 内に x264guiEx_stg ディレクトリを移動
				Move-Item x264guiEx_stg $aviutlPluginsDirectory -Force

				Write-Host "完了`r`n"
				break
			}
			1 {
				# 後で邪魔になるので削除
				Remove-Item x264guiEx_stg -Recurse

				Write-Host "プロファイルの上書きをスキップしました。`r`n"
				break
			}
		}

		# 選択ここまで
	}

	Write-Host -NoNewline "x264guiExをインストールしています..."

	Start-Sleep -Milliseconds 500

	# AviUtl\plugins 内に現在のディレクトリのファイルを全て移動
	Move-Item * $aviutlPluginsDirectory -Force

	# カレントディレクトリをx264guiExのzipファイルを展開したディレクトリ内の exe_files ディレクトリに変更
	Set-Location ..\exe_files

	# AviUtl ディレクトリ内に exe_files ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\exe_files`" -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# AviUtl\exe_files 内に x264_*.exe があれば削除 (待機)
	Start-Process powershell -ArgumentList "-command if (Test-Path `"${Path}\exe_files\x264_*.exe`") { Remove-Item `"${Path}\exe_files\x264_*.exe`" }" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# AviUtl\exe_files 内に現在のディレクトリのファイルを全て移動
	Move-Item * "${Path}\exe_files" -Force

	# カレントディレクトリをx264guiExのzipファイルを展開したディレクトリに変更
	Set-Location ..

	# AviUtl\readme 内に x264guiEx ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${ReadmeDirectoryRoot}\x264guiEx`" -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# AviUtl\readme\x264guiEx 内に x264guiEx_readme.txt を移動
	Move-Item x264guiEx_readme.txt "${ReadmeDirectoryRoot}\x264guiEx" -Force

	# apm.json に rigaya/x264guiEx が登録されていない場合はキーを作成してidを登録
	if (!($apmJsonHash.packages.Contains("rigaya/x264guiEx"))) {
		$apmJsonHash["packages"]["rigaya/x264guiEx"] = [ordered]@{}
		$apmJsonHash["packages"]["rigaya/x264guiEx"]["id"] = "rigaya/x264guiEx"
	}

	# apm.json の rigaya/x264guiEx のバージョンを更新
	$apmJsonHash["packages"]["rigaya/x264guiEx"]["version"] = $x264guiExGithubApi.tag_name

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..\..
}

Write-Host "完了"
Write-Host -NoNewline "`r`nMFVideoReaderの最新版情報を取得しています..."

# MFVideoReaderの入っているディレクトリを探し、$MFVideoReaderAuiDirectory にパスを保存
if (Test-Path "${Path}\MFVideoReaderPlugin.aui") {
	$MFVideoReaderAuiDirectory = $Path
} else {
	$MFVideoReaderAuiDirectory = $aviutlPluginsDirectory
}

# MFVideoReaderの最新版のダウンロードURLを取得
$MFVideoReaderGithubApi = GithubLatestRelease "amate/MFVideoReader"
$MFVideoReaderUrl = $MFVideoReaderGithubApi.assets.browser_download_url

# apm.json があり、かつ最新版の情報が記載されている場合はスキップする
if (!($apmJsonExist -and $apmJsonHash.packages.Contains("amate/MFVideoReader") -and
	($apmJsonHash["packages"]["amate/MFVideoReader"]["version"] -eq $MFVideoReaderGithubApi.tag_name))) {
	Write-Host "完了"
	Write-Host -NoNewline "MFVideoReaderをダウンロードしています..."

	# MFVideoReaderのzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $MFVideoReaderUrl" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "MFVideoReaderをインストールしています..."

	# MFVideoReaderのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path MFVideoReader_*.zip -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# カレントディレクトリをMFVideoReaderのzipファイルを展開したディレクトリに変更
	Set-Location "MFVideoReader_*\MFVideoReader"

	# AviUtl\readme, AviUtl\license 内に MFVideoReader ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${ReadmeDirectoryRoot}\MFVideoReader`", `"${LicenseDirectoryRoot}\MFVideoReader`" -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# AviUtl\license\MFVideoReader 内に LICENSE を、AviUtl\readme\MFVideoReader 内に Readme.md を (待機) 、
	# $MFVideoReaderAuiDirectory ディレクトリ内にその他のファイルをそれぞれ移動
	Start-Process powershell -ArgumentList "-command Move-Item LICENSE `"${LicenseDirectoryRoot}\MFVideoReader`" -Force; Move-Item Readme.md `"${ReadmeDirectoryRoot}\MFVideoReader`" -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait
	Move-Item * $MFVideoReaderAuiDirectory -Force

	# apm.json に amate/MFVideoReader が登録されていない場合はキーを作成してidを登録
	if (!($apmJsonHash.packages.Contains("amate/MFVideoReader"))) {
		$apmJsonHash["packages"]["amate/MFVideoReader"] = [ordered]@{}
		$apmJsonHash["packages"]["amate/MFVideoReader"]["id"] = "amate/MFVideoReader"
	}

	# apm.json の amate/MFVideoReader のバージョンを更新
	$apmJsonHash["packages"]["amate/MFVideoReader"]["version"] = $MFVideoReaderGithubApi.tag_name

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..\..
}

# MFVideoReaderの設定ファイルが見つからない場合のみ、以下の処理を実行
if (!(Test-Path "${MFVideoReaderAuiDirectory}\MFVideoReaderConfig.ini")) {
	Copy-Item "${settingsDirectoryPath}\MFVideoReaderConfig.ini" $MFVideoReaderAuiDirectory
}

Write-Host "完了"
Write-Host -NoNewline "`r`nWebP Susie Plug-inを確認しています..."

# ais.json があり、かつ TORO/iftwebp が記載されている場合はスキップする
if (!($aisJsonExist -and $aisJsonHash.packages.Contains("TORO/iftwebp") -and
	($aisJsonHash["packages"]["TORO/iftwebp"]["version"] -eq "1.1"))) {
	Write-Host "完了"
	Write-Host -NoNewline "WebP Susie Plug-inをダウンロードしています..."

	# WebP Susie Plug-inのzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL https://toroidj.github.io/plugin/iftwebp11.zip" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "WebP Susie Plug-inをインストールしています..."

	# WebP Susie Plug-inのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path iftwebp11.zip -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# カレントディレクトリを iftwebp11 ディレクトリに変更
	Set-Location iftwebp11

	# AviUtl\readme 内に iftwebp ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${ReadmeDirectoryRoot}\iftwebp`" -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# AviUtl ディレクトリ内に iftwebp.spi を、AviUtl\readme\iftwebp 内に iftwebp.txt をそれぞれ移動
	Move-Item iftwebp.spi $Path -Force
	Move-Item iftwebp.txt "${ReadmeDirectoryRoot}\iftwebp" -Force

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..
}

Write-Host "完了"
Write-Host -NoNewline "`r`nifheifの最新版情報を取得しています..."

# ifheifの最新版のダウンロードURLを取得
$ifheifGithubApi = GithubLatestRelease "Mr-Ojii/ifheif"
$ifheifUrl = $ifheifGithubApi.assets.browser_download_url

# ais.json があり、かつ最新版の情報が記載されている場合はスキップする
if (!($aisJsonExist -and $aisJsonHash.packages.Contains("Mr-Ojii/ifheif") -and
	($aisJsonHash["packages"]["Mr-Ojii/ifheif"]["version"] -eq $ifheifGithubApi.tag_name))) {
	Write-Host "完了"
	Write-Host -NoNewline "ifheifをダウンロードしています..."

	# ifheifのzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $ifheifUrl" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "ifheifをインストールしています..."

	# AviUtl\license\ifheif 内に Licenses ディレクトリがあれば削除する (エラーの防止)
	if (Test-Path "${LicenseDirectoryRoot}\ifheif\Licenses") {
		Remove-Item "${LicenseDirectoryRoot}\ifheif\Licenses" -Recurse
	}

	# ifheifのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path ifheif.zip -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# カレントディレクトリをifheifのzipファイルを展開したディレクトリに変更
	Set-Location "ifheif"

	# AviUtl\readme, AviUtl\license 内に ifheif ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${ReadmeDirectoryRoot}\ifheif`", `"${LicenseDirectoryRoot}\ifheif`" -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# AviUtl ディレクトリ内に ifheif.spi を、AviUtl\license\ifheif 内に LICENSE と Licenses ディレクトリを、
	# AviUtl\readme\ifheif 内に Readme.md をそれぞれ移動
	Move-Item ifheif.spi $Path -Force
	Move-Item "LICENS*" "${LicenseDirectoryRoot}\ifheif" -Force
	Move-Item Readme.md "${ReadmeDirectoryRoot}\ifheif" -Force

	# ais.json の Mr-Ojii/ifheif のバージョンを更新
	$aisJsonHash["packages"]["Mr-Ojii/ifheif"]["version"] = $ifheifGithubApi.tag_name

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..
}

Write-Host "完了"
Write-Host -NoNewline "`r`n「AviUtlスクリプト一式」を確認しています..."

# script ディレクトリ、またはそのサブディレクトリに @ANM1.anm があるか確認し、ある場合は $CheckAviUtlScriptSet を
# true とし、$AviUtlScriptSetDirectory にディレクトリのパスを記録する
$CheckAviUtlScriptSet = $false
if (Test-Path "${aviutlScriptDirectory}\@ANM1.anm") {
	$CheckAviUtlScriptSet = $true
	$AviUtlScriptSetDirectory = $aviutlScriptDirectory
} else {
	Get-ChildItem -Path $aviutlScriptDirectory -Directory | ForEach-Object {
		if (Test-Path -Path "${_}\@ANM1.anm") {
			$CheckAviUtlScriptSet = $true
			$AviUtlScriptSetDirectory = $_
		}
	}
}

Start-Sleep -Milliseconds 500

# @ANM1.anm を発見できなかった場合、$AviUtlScriptSetDirectory に AviUtl\script\さつき を記録する
# また、AviUtl\script 内に さつき ディレクトリを作成する
if (!($CheckAviUtlScriptSet)) {
	$AviUtlScriptSetDirectory = "${aviutlScriptDirectory}\さつき"
	Start-Process powershell -ArgumentList "-command New-Item `"${aviutlScriptDirectory}\さつき`" -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait
}

# script ディレクトリ、またはそのサブディレクトリに 震える_連動.anm があるか確認し、ある場合は $CheckAnmSsd を
# true とし、$anmSsdDirectory にディレクトリのパスを記録する
$CheckAnmSsd = $false
if (Test-Path "${aviutlScriptDirectory}\震える_連動.anm") {
	$CheckAnmSsd = $true
	$anmSsdDirectory = $aviutlScriptDirectory
} else {
	Get-ChildItem -Path $aviutlScriptDirectory -Directory | ForEach-Object {
		if (Test-Path -Path "${_}\震える_連動.anm") {
			$CheckAnmSsd = $true
			$anmSsdDirectory = $_
		}
	}
}

Start-Sleep -Milliseconds 500

# 震える_連動.anm を発見できなかった場合、$anmSsdDirectory に AviUtl\script\ANM_ssd を記録する
# また、AviUtl\script 内に ANM_ssd ディレクトリを作成する
if (!($CheckAnmSsd)) {
	$anmSsdDirectory = "${aviutlScriptDirectory}\ANM_ssd"
	Start-Process powershell -ArgumentList "-command New-Item `"${aviutlScriptDirectory}\ANM_ssd`" -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait
}

# script ディレクトリ、またはそのサブディレクトリに TA位置調整で移動.anm があるか確認し、ある場合は $CheckTaSsd を
# true とし、$taSsdDirectory にディレクトリのパスを記録する
$CheckTaSsd = $false
if (Test-Path "${aviutlScriptDirectory}\TA位置調整で移動.anm") {
	$CheckTaSsd = $true
	$taSsdDirectory = $aviutlScriptDirectory
} else {
	Get-ChildItem -Path $aviutlScriptDirectory -Directory | ForEach-Object {
		if (Test-Path -Path "${_}\TA位置調整で移動.anm") {
			$CheckTaSsd = $true
			$taSsdDirectory = $_
		}
	}
}

Start-Sleep -Milliseconds 500

# TA位置調整で移動.anm を発見できなかった場合、$taSsdDirectory に AviUtl\script\TA_ssd を記録する
# また、AviUtl\script 内に TA_ssd ディレクトリを作成する
if (!($CheckTaSsd)) {
	$taSsdDirectory = "${aviutlScriptDirectory}\TA_ssd"
	Start-Process powershell -ArgumentList "-command New-Item `"${aviutlScriptDirectory}\TA_ssd`" -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait
}

# apm.json があり、かつ最新版の情報が記載されている場合はスキップする
if (!($apmJsonExist -and $apmJsonHash.packages.Contains("satsuki/satsuki") -and
	($apmJsonHash["packages"]["satsuki/satsuki"]["version"] -eq "20160828"))) {

	# $AviUtlScriptSetDirectory 内に 削除済み ディレクトリがあれば削除する (エラーの防止)
	if (Test-Path "${AviUtlScriptSetDirectory}\削除済み") {
		Remove-Item "${AviUtlScriptSetDirectory}\削除済み" -Recurse
	}

	Write-Host "完了"
	Write-Host -NoNewline "「AviUtlスクリプト一式」をダウンロードしています..."

	# 「AviUtlスクリプト一式」のzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL https://ss1.xrea.com/menkuri.s270.xrea.com/aviutl-installer-script/scripts/script_20160828.zip" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "「AviUtlスクリプト一式」をインストールしています..."

	# 「AviUtlスクリプト一式」のzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path script_20160828.zip -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# カレントディレクトリを script_20160828\script_20160828 ディレクトリに変更
	Set-Location script_20160828\script_20160828

	# AviUtl\readme 内に AviUtlスクリプト一式 ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${ReadmeDirectoryRoot}\AviUtlスクリプト一式`" -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# $anmSsdDirectory 内に ANM_ssd の中身を、$taSsdDirectory 内に TA_ssd の中身を (待機) 、
	# AviUtl\readme\AviUtlスクリプト一式 内に readme.txt と 使い方.txt を (待機) 、
	# $AviUtlScriptSetDirectory 内にその他のファイルをそれぞれ移動
	Start-Process powershell -ArgumentList "-command Move-Item `"ANM_ssd\*`" $anmSsdDirectory -Force; Move-Item `"TA_ssd\*`" $taSsdDirectory -Force; Move-Item *.txt `"${ReadmeDirectoryRoot}\AviUtlスクリプト一式`" -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait
	Move-Item * $AviUtlScriptSetDirectory -Force

	# apm.json に satsuki/satsuki が登録されていない場合はキーを作成してidを登録
	if (!($apmJsonHash.packages.Contains("satsuki/satsuki"))) {
		$apmJsonHash["packages"]["satsuki/satsuki"] = [ordered]@{}
		$apmJsonHash["packages"]["satsuki/satsuki"]["id"] = "satsuki/satsuki"
	}

	# apm.json の satsuki/satsuki のバージョンを更新
	$apmJsonHash["packages"]["satsuki/satsuki"]["version"] = "20160828"

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..\..
}

Write-Host "完了"
Write-Host -NoNewline "`r`n「値で図形」を確認しています..."

# script ディレクトリ、またはそのサブディレクトリに 値で図形.obj があるか確認し、ある場合は $CheckShapeWithValuesObj を
# true とし、$shapeWithValuesObjDirectory にディレクトリのパスを記録する
$CheckShapeWithValuesObj = $false
if (Test-Path "${aviutlScriptDirectory}\値で図形.obj") {
	$CheckShapeWithValuesObj = $true
	$shapeWithValuesObjDirectory = $aviutlScriptDirectory
} else {
	Get-ChildItem -Path $aviutlScriptDirectory -Directory | ForEach-Object {
		if (Test-Path -Path "${_}\値で図形.obj") {
			$CheckShapeWithValuesObj = $true
			$shapeWithValuesObjDirectory = $_
		}
	}
}

Start-Sleep -Milliseconds 500

# 値で図形.obj を発見できなかった場合、$shapeWithValuesObjDirectory に AviUtl\script\Nagomiku を記録する
# また、AviUtl\script 内に Nagomiku ディレクトリを作成する
if (!($CheckShapeWithValuesObj)) {
	$shapeWithValuesObjDirectory = "${aviutlScriptDirectory}\Nagomiku"
	Start-Process powershell -ArgumentList "-command New-Item `"${aviutlScriptDirectory}\Nagomiku`" -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait
}

# apm.json があり、かつ最新版の情報が記載されている場合はスキップする
if (!($apmJsonExist -and $apmJsonHash.packages.Contains("nagomiku/paracustomobj") -and
	($apmJsonHash["packages"]["nagomiku/paracustomobj"]["version"] -eq "v2.10"))) {
	Write-Host "完了"
	Write-Host -NoNewline "「値で図形」をダウンロードしています..."

	# 値で図形.obj をダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL `"https://ss1.xrea.com/menkuri.s270.xrea.com/aviutl-installer-script/scripts/値で図形.obj`"" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "「値で図形」をインストールしています..."

	# AviUtl\script 内に 値で図形.obj を移動
	Move-Item "値で図形.obj" $aviutlScriptDirectory -Force

	# apm.json に nagomiku/paracustomobj が登録されていない場合はキーを作成してidを登録
	if (!($apmJsonHash.packages.Contains("nagomiku/paracustomobj"))) {
		$apmJsonHash["packages"]["nagomiku/paracustomobj"] = [ordered]@{}
		$apmJsonHash["packages"]["nagomiku/paracustomobj"]["id"] = "nagomiku/paracustomobj"
	}

	# apm.json の nagomiku/paracustomobj のバージョンを更新
	$apmJsonHash["packages"]["nagomiku/paracustomobj"]["version"] = "v2.10"
}

Write-Host "完了"
Write-Host -NoNewline "`r`n直線スクリプトを確認しています..."

# script ディレクトリ、またはそのサブディレクトリに 直線.obj があるか確認し、ある場合は $CheckStraightLineObj を
# true とし、$straightLineObjDirectory にディレクトリのパスを記録する
$CheckStraightLineObj = $false
if (Test-Path "${aviutlScriptDirectory}\直線.obj") {
	$CheckStraightLineObj = $true
	$straightLineObjDirectory = $aviutlScriptDirectory
} else {
	Get-ChildItem -Path $aviutlScriptDirectory -Directory | ForEach-Object {
		if (Test-Path -Path "${_}\直線.obj") {
			$CheckStraightLineObj = $true
			$straightLineObjDirectory = $_
		}
	}
}

Start-Sleep -Milliseconds 500

# 直線.obj を発見できなかった場合、$taSsdDirectory に AviUtl\script\ちくぼん を記録する
# また、AviUtl\script 内に ちくぼん ディレクトリを作成する (待機)
if (!($CheckStraightLineObj)) {
	$straightLineObjDirectory = "${aviutlScriptDirectory}\ちくぼん"
	Start-Process powershell -ArgumentList "-command New-Item `"${aviutlScriptDirectory}\ちくぼん`" -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait
}

Write-Host "完了"

# ais.json があり、かつ最新版の情報が記載されている場合はスキップする
if (!($aisJsonExist -and $aisJsonHash.packages.Contains("tikubonn/straightLineObj") -and
	($aisJsonHash["packages"]["tikubonn/straightLineObj"]["version"] -eq "2021/03/07"))) {
	Write-Host -NoNewline "直線スクリプトをダウンロードしています..."

	# 直線スクリプトのzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL `"https://ss1.xrea.com/menkuri.s270.xrea.com/aviutl-installer-script/scripts/直線スクリプト.zip`"" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "直線スクリプトをインストールしています..."

	# 直線スクリプトのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path `"直線スクリプト.zip`" -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# カレントディレクトリを 直線スクリプト ディレクトリに変更
	Set-Location "直線スクリプト"

	# AviUtl\readme, AviUtl\license 内に 直線スクリプト ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${ReadmeDirectoryRoot}\直線スクリプト`", `"${LicenseDirectoryRoot}\直線スクリプト`" -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# AviUtl\script 内に 直線.obj を、AviUtl\license\直線スクリプト 内に LICENSE.txt を (待機) 、
	# AviUtl\readme\直線スクリプト 内にその他のファイルをそれぞれ移動
	Start-Process powershell -ArgumentList "-command Move-Item `"直線.obj`" $aviutlScriptDirectory -Force; Move-Item LICENSE.txt `"${LicenseDirectoryRoot}\直線スクリプト`" -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait
	Move-Item * "${ReadmeDirectoryRoot}\直線スクリプト" -Force

	# ais.json の tikubonn/straightLineObj のバージョンを更新
	$aisJsonHash["packages"]["tikubonn/straightLineObj"]["version"] = "2021/03/07"

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..

	Write-Host "完了"
}


# LuaJITの更新 by Yu-yu0202 (20250109)
	# 不具合が直らなかったため再実装 by menndouyukkuri (20250110)
Write-Host -NoNewline "`r`nLuaJITの最新版情報を取得しています..."

# LuaJITの最新版のダウンロードURLを取得
$luaJitGithubApi = GithubLatestRelease "Per-Terra/LuaJIT-Auto-Builds"
$luaJitAllUrl = $luaJitGithubApi.assets.browser_download_url

# 複数ある中からAviUtl用のもののみ残す
$luaJitUrl = $luaJitAllUrl | Where-Object {$_ -like "*LuaJIT_2.1_Win_x86.zip"}

# ais.json 用にタグ名を取得してビルド日だけ取り出し yyyy/mm/dd に整形
$luaJitTagNameSplitArray = ($luaJitGithubApi.tag_name) -split "-"
$luaJitBuildDate = $luaJitTagNameSplitArray[1] + "/" + $luaJitTagNameSplitArray[2] + "/" + $luaJitTagNameSplitArray[3]

# ais.json のLuaJITのバージョンを / で分割して $aisJsonluaJitVersionArray に格納
if ($aisJsonExist -and $aisJsonHash.packages.Contains("Per-Terra/LuaJIT")) {
	$aisJsonluaJitVersionArray = $aisJsonHash["packages"]["Per-Terra/LuaJIT"]["version"] -split "/"
} else {
	$aisJsonluaJitVersionArray = 0, 0, 0
}

# $luaJitUpdate にLuaJITを更新するかどうかを格納
$luaJitUpdate = $true

# ais.json の年 > 取得したビルド日の年
if ($aisJsonluaJitVersionArray[0] -gt $luaJitTagNameSplitArray[1]) {
	$luaJitUpdate = $false

# ais.json の年 < 取得したビルド日の年
} elseif ($aisJsonluaJitVersionArray[0] -lt $luaJitTagNameSplitArray[1]) {
	# if文を離脱、これより下の条件は ais.json の年 = 取得したビルド日の年

# ais.json の月 > 取得したビルド日の月
} elseif ($aisJsonluaJitVersionArray[1] -gt $luaJitTagNameSplitArray[2]) {
	$luaJitUpdate = $false

# ais.json の月 < 取得したビルド日の月
} elseif ($aisJsonluaJitVersionArray[1] -lt $luaJitTagNameSplitArray[2]) {
	# if文を離脱、これより下の条件は ais.json の月 = 取得したビルド日の月

# ais.json の日 >= 取得したビルド日の日
} elseif ($aisJsonluaJitVersionArray[2] -ge $luaJitTagNameSplitArray[3]) {
	$luaJitUpdate = $false
}

# ais.json のバージョンより取得したビルド日の方が新しい場合は更新する
if ($luaJitUpdate) {
	Write-Host "完了"
	Write-Host -NoNewline "LuaJITをダウンロードしています..."

	# LuaJITのzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $luaJitUrl" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "LuaJITをインストールしています..."

	# AviUtl ディレクトリ内に exedit_lua51.dll も old_lua51.dll もない場合、既にある lua51.dll をリネームしてバックアップする
	if (!(Test-Path "${Path}\exedit_lua51.dll") -and !(Test-Path "${Path}\old_lua51.dll")) {
		Rename-Item "${Path}\lua51.dll" "old_lua51.dll" -Force
	}

	# AviUtl\readme\LuaJIT 内に doc ディレクトリがあれば削除する (エラーの防止)
	if (Test-Path "${ReadmeDirectoryRoot}\LuaJIT\doc") {
		Remove-Item "${ReadmeDirectoryRoot}\LuaJIT\doc" -Recurse
	}

	# LuaJITのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path `"LuaJIT_2.1_Win_x86.zip`" -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# カレントディレクトリをLuaJITのzipファイルを展開したディレクトリに変更
	Set-Location "LuaJIT_2.1_Win_x86"

	# AviUtl\readme, AviUtl\license 内に LuaJIT ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${ReadmeDirectoryRoot}\LuaJIT`", `"${LicenseDirectoryRoot}\LuaJIT`" -ItemType Directory -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	# AviUtl ディレクトリ内に lua51.dll を、AviUtl\readme\LuaJIT 内に README と doc を、AviUtl\license\LuaJIT 内に
	# COPYRIGHT と About-This-Build.txt をそれぞれ移動
	Move-Item "lua51.dll" $Path -Force
	Move-Item README "${ReadmeDirectoryRoot}\LuaJIT" -Force
	Move-Item doc "${ReadmeDirectoryRoot}\LuaJIT" -Force
	Move-Item COPYRIGHT "${LicenseDirectoryRoot}\LuaJIT" -Force
	Move-Item "About-This-Build.txt" "${LicenseDirectoryRoot}\LuaJIT" -Force

	# apm.json に ePi/LuaJIT が登録されていない場合はキーを作成してidとversionを登録
	if (!($apmJsonHash.packages.Contains("ePi/LuaJIT"))) {
		$apmJsonHash["packages"]["ePi/LuaJIT"] = [ordered]@{}
		$apmJsonHash["packages"]["ePi/LuaJIT"]["id"] = "ePi/LuaJIT"
		$apmJsonHash["packages"]["ePi/LuaJIT"]["version"] = "2.1.0-beta3"
	}

	# ais.json の Per-Terra/LuaJIT のバージョンを更新
	$aisJsonHash["packages"]["Per-Terra/LuaJIT"]["version"] = $luaJitBuildDate

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..
}

Write-Host "完了"


Write-Host "`r`nハードウェアエンコードの出力プラグイン (NVEnc / QSVEnc / VCEEnc) を確認しています。"

$hwEncoders = [ordered]@{
	"NVEnc"  = "NVEncC.exe"
	"QSVEnc" = "QSVEncC.exe"
	"VCEEnc" = "VCEEncC.exe"
}

# ハードウェアエンコードの出力プラグインを削除した時に記録するハッシュテーブルを用意
$hwEncodersRemove = @{
	"NVEnc" = $false
	"QSVEnc" = $false
	"VCEEnc" = $false
}

# ハードウェアエンコードの出力プラグインのインストールチェック用の変数を用意
$CheckHwEncoder = $false

foreach ($hwEncoder in $hwEncoders.GetEnumerator()) {
	# 導入の有無をチェック
	if (Test-Path "${aviutlPluginsDirectory}\$($hwEncoder.Key).auo") {
		Write-Host -NoNewline "`r`n$($hwEncoder.Key)が使用できるかチェックします..."

		# ハードウェアエンコードできるかチェック
		$process = Start-Process -FilePath "${Path}\exe_files\$($hwEncoder.Key)C\x86\$($hwEncoder.Value)" -ArgumentList "--check-hw" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait -PassThru

		Write-Host "完了"

		# ExitCodeが0 (使用可能) の場合は更新確認、それ以外なら削除 (エラーの防止)
		if ($process.ExitCode -eq 0) {
			# ハードウェアエンコードの出力プラグインのインストールチェック用の変数を true に
			$CheckHwEncoder = $true

			Write-Host -NoNewline "$($hwEncoder.Key)の最新版情報を取得しています..."

			# 最新版のダウンロードURLを取得
			$hwEncoderGithubApi = GithubLatestRelease "rigaya/$($hwEncoder.Key)"
			$downloadAllUrl = $hwEncoderGithubApi.assets.browser_download_url

			# 複数ある中からAviUtl用のもののみ残す
			$downloadUrl = $downloadAllUrl | Where-Object {$_ -like "*Aviutl*"}

			# apm.json があり、かつ最新版の情報が記載されている場合はスキップする
			if (!($apmJsonExist -and $apmJsonHash.packages.Contains("rigaya/$($hwEncoder.Key)") -and
				($apmJsonHash["packages"]["rigaya/$($hwEncoder.Key)"]["version"] -eq $hwEncoderGithubApi.tag_name))) {
				Write-Host "完了"
				Write-Host -NoNewline "$($hwEncoder.Key)を更新します。ダウンロードしています..."

				# zipファイルをダウンロード (待機)
				Start-Process -FilePath curl.exe -ArgumentList "-OL $downloadUrl" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

				# zipファイルを展開 (待機)
				Start-Process powershell -ArgumentList "-command Expand-Archive -Path Aviutl_$($hwEncoder.Key)_*.zip -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

				# 展開されたディレクトリのパスを格納
				Set-Location "Aviutl_$($hwEncoder.Key)_*"
				$extdir = $scriptFileRoot
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
							Write-Host -NoNewline "プロファイルを上書きします..."

							# AviUtl\plugins 内の (NVEnc/QSVEnc/VCEEnc)_stg ディレクトリを削除する (待機)
							Start-Process powershell -ArgumentList "-command Remove-Item `"${aviutlPluginsDirectory}\$($hwEncoder.Key)_stg`" -Recurse" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

							# ダウンロードして展開した (NVEnc/QSVEnc/VCEEnc)_stg を AviUtl\plugins 内に移動
							Move-Item "$extdir\plugins\$($hwEncoder.Key)_stg" $aviutlPluginsDirectory -Force

							Write-Host "完了`r`n"
							break
						}
						1 {
							# 後で邪魔になるので削除
							Remove-Item "$extdir\plugins\$($hwEncoder.Key)_stg" -Recurse

							Write-Host "プロファイルの上書きをスキップしました。`r`n"
							break
						}
					}

					# 選択ここまで
				}

				Write-Host -NoNewline "$($hwEncoder.Key)をインストールしています..."

				# AviUtl\exe_files\(NVEnc/QSVEnc/VCEEnc)C が後で邪魔になるので削除
				Remove-Item "${Path}\exe_files\$($hwEncoder.Key)C" -Recurse

				# readme ディレクトリを作成
				New-Item -ItemType Directory -Path "${ReadmeDirectoryRoot}\$($hwEncoder.Key)" -Force | Out-Null

				# 展開後のそれぞれのファイルを移動
				Move-Item -Path "$extdir\*.bat" -Destination $Path -Force
				Move-Item -Path "$extdir\plugins\*" -Destination $aviutlPluginsDirectory -Force
				Move-Item -Path "$extdir\exe_files\*" -Destination "${Path}\exe_files" -Force
				Move-Item -Path "$extdir\*_readme.txt" -Destination "${ReadmeDirectoryRoot}\$($hwEncoder.Key)" -Force

				# apm.json に rigaya/$($hwEncoder.Key) が登録されていない場合はキーを作成してidを登録
				if (!($apmJsonHash.packages.Contains("rigaya/$($hwEncoder.Key)"))) {
					$apmJsonHash["packages"]["rigaya/$($hwEncoder.Key)"] = [ordered]@{}
					$apmJsonHash["packages"]["rigaya/$($hwEncoder.Key)"]["id"] = "rigaya/$($hwEncoder.Key)"
				}

				# apm.json の rigaya/$($hwEncoder.Key) のバージョンを更新
				$apmJsonHash["packages"]["rigaya/$($hwEncoder.Key)"]["version"] = $hwEncoderGithubApi.tag_name
			}

			Write-Host "完了"

		} else {
			Write-Host -NoNewline "$($hwEncoder.Key)は使用できません。削除しています..."

			# ファイルを削除
			Remove-Item "${Path}\exe_files\$($hwEncoder.Key)C" -Recurse
			Remove-Item "${aviutlPluginsDirectory}\$($hwEncoder.Key)*" -Recurse
			if (Test-Path "${ReadmeDirectoryRoot}\$($hwEncoder.Key)") {
				Remove-Item "${ReadmeDirectoryRoot}\$($hwEncoder.Key)" -Recurse
			}

			# apm.json に rigaya/$($hwEncoder.Key) が登録されている場合は削除
			if ($apmJsonHash.packages.Contains("rigaya/$($hwEncoder.Key)")) {
				$apmJsonHash.packages.Remove("rigaya/$($hwEncoder.Key)")
			}

			# $hwEncodersRemove.$($hwEncoder.Key) に $true を代入
			$hwEncodersRemove.$($hwEncoder.Key) = $true

			Write-Host "完了"
		}
	} else {
		# apm.json に rigaya/$($hwEncoder.Key) が登録されている場合は削除
		if ($apmJsonHash.packages.Contains("rigaya/$($hwEncoder.Key)")) {
			$apmJsonHash.packages.Remove("rigaya/$($hwEncoder.Key)")
		}
	}
}

Write-Host "`r`nハードウェアエンコードの出力プラグインの確認が完了しました。"

# ハードウェアエンコードの出力プラグインが1つも入っていない (上の処理で削除された場合含む) 場合にインストールチェックする
# ただし、上の処理で全てのプラグインが削除されている場合はインストールチェックをする意味がないのでスキップする
if ((!($CheckHwEncoder)) -and
	(!($hwEncodersRemove.NVEnc -and $hwEncodersRemove.QSVEnc -and $hwEncodersRemove.VCEEnc))) {


	# HWエンコーディングの使用可否をチェックし、可能であれば出力プラグインをインストール by Yu-yu0202 (20250107)

	Write-Host "`r`nハードウェアエンコード (NVEnc / QSVEnc / VCEEnc) が使用できるかチェックします。"
	Write-Host -NoNewline "必要なファイルをダウンロードしています (数分かかる場合があります) "

	# apm.json 生成用にタグ名を保存するハッシュテーブルを作成
	$hwEncodersTagName = @{
		"NVEnc"  = "xxx"
		"QSVEnc" = "xxx"
		"VCEEnc" = "xxx"
	}

	$hwEncoderRepos = @("rigaya/NVEnc", "rigaya/QSVEnc", "rigaya/VCEEnc")
	foreach ($hwRepo in $hwEncoderRepos) {
		# あとで使うのでリポジトリ名を取っておく
		$repoName = ($hwRepo -split "/")[-1]

		# 最新版のダウンロードURLを取得
		$hwEncoderGithubApi = GithubLatestRelease $hwRepo
		$downloadAllUrl = $hwEncoderGithubApi.assets.browser_download_url

		# 複数ある中からAviUtl用のもののみ残す
		$downloadUrl = $downloadAllUrl | Where-Object {$_ -like "*Aviutl*"}

		# apm.json 生成用に $hwEncodersTagName にタグ名を保存
		$hwEncodersTagName.$repoName = $hwEncoderGithubApi.tag_name

		Write-Host -NoNewline "."

		# zipファイルをダウンロード (待機)
		Start-Process -FilePath curl.exe -ArgumentList "-OL $downloadUrl" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

		Write-Host -NoNewline "."

		# zipファイルを展開 (待機)
		Start-Process powershell -ArgumentList "-command Expand-Archive -Path Aviutl_${repoName}_*.zip -Force" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait
	}

	Write-Host " 完了"
	Write-Host "エンコーダーのチェック、および使用可能な出力プラグインのインストールを行います。"

	# 画質のよいNVEncから順にQSVEnc、VCEEncとチェックしていき、最初に使用可能なものを確認した時点でそれを導入してforeachを離脱
	foreach ($hwEncoder in $hwEncoders.GetEnumerator()) {
		# エンコーダーの実行ファイルのパスを格納
		Set-Location "Aviutl_$($hwEncoder.Key)_*"
		$extdir = $scriptFileRoot
		$encoderPath = Join-Path -Path $extdir -ChildPath "exe_files\$($hwEncoder.Key)C\x86\$($hwEncoder.Value)"
		Set-Location ..

		# エンコーダーの実行ファイルの有無を確認
		if (Test-Path $encoderPath) {
			# ハードウェアエンコードできるかチェック
			$process = Start-Process -FilePath $encoderPath -ArgumentList "--check-hw" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait -PassThru

			# ExitCodeが0の場合はインストール
			if ($process.ExitCode -eq 0) {
				# AviUtl\exe_files 内に $($hwEncoder.Key)C ディレクトリがあれば削除する (エラーの防止)
				if (Test-Path "${Path}\exe_files\$($hwEncoder.Key)C") {
					Remove-Item "${Path}\exe_files\$($hwEncoder.Key)C" -Recurse
				}

				# AviUtl\plugins 内に $($hwEncoder.Key)_stg ディレクトリがあれば削除する (エラーの防止)
				if (Test-Path "${aviutlPluginsDirectory}\$($hwEncoder.Key)_stg") {
					Remove-Item "${aviutlPluginsDirectory}\$($hwEncoder.Key)_stg" -Recurse
				}

				Write-Host -NoNewline "$($hwEncoder.Key)が使用可能です。$($hwEncoder.Key)をインストールしています..."

				# readme ディレクトリを作成
				New-Item -ItemType Directory -Path "${ReadmeDirectoryRoot}\$($hwEncoder.Key)" -Force | Out-Null

				# 展開後のそれぞれのファイルを移動
				Move-Item -Path "$extdir\exe_files\*" -Destination "${Path}\exe_files" -Force
				Move-Item -Path "$extdir\plugins\*" -Destination $aviutlPluginsDirectory -Force
				Move-Item -Path "$extdir\*.bat" -Destination $Path -Force
				Move-Item -Path "$extdir\*_readme.txt" -Destination "${ReadmeDirectoryRoot}\$($hwEncoder.Key)" -Force

				# apm.json に rigaya/$($hwEncoder.Key) が登録されていない場合はキーを作成してidを登録
				if (!($apmJsonHash.packages.Contains("rigaya/$($hwEncoder.Key)"))) {
					$apmJsonHash["packages"]["rigaya/$($hwEncoder.Key)"] = [ordered]@{}
					$apmJsonHash["packages"]["rigaya/$($hwEncoder.Key)"]["id"] = "rigaya/$($hwEncoder.Key)"
				}

				# apm.json の rigaya/$($hwEncoder.Key) のバージョンを更新
				$apmJsonHash["packages"]["rigaya/$($hwEncoder.Key)"]["version"] = $hwEncodersTagName.$($hwEncoder.Key)

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
$installedApps = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
								  "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
								  "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
Where-Object { $_.DisplayName -and $_.UninstallString -and -not $_.SystemComponent -and ($_.ReleaseType -notin "Update","Hotfix") -and -not $_.ParentKeyName } |
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
	Start-Process curl.exe -ArgumentList "-OL https://aka.ms/vs/17/release/vc_redist.x86.exe" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host "Microsoft Visual C++ 2015-20xx Redistributable (x86) のインストールを行います。"
	Write-Host "デバイスへの変更が必要になります。ユーザーアカウント制御のポップアップが出たら [はい] を押して許可してください。`r`n"

	# Visual C++ 2015-20xx Redistributable (x86) のインストーラーを実行 (待機)
		# 自動インストールオプションを追加 by Atolycs (20250106)
	Start-Process -FilePath vc_redist.x86.exe -ArgumentList "/install /passive" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

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
			Start-Process curl.exe -ArgumentList "-OL https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

			Write-Host "完了"
			Write-Host "Microsoft Visual C++ 2008 Redistributable - x86 のインストールを行います。"
			Write-Host "デバイスへの変更が必要になります。ユーザーアカウント制御のポップアップが出たら [はい] を押して許可してください。`r`n"

			# Visual C++ 2008 Redistributable - x86 のインストーラーを実行 (待機)
				# 自動インストールオプションを追加 by Atolycs (20250106)
			Start-Process -FilePath vcredist_x86.exe -ArgumentList "/qb" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

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
	Start-Process curl.exe -ArgumentList "-OL https://aka.ms/vs/17/release/vc_redist.x86.exe" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

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
			Start-Process curl.exe -ArgumentList "-OL https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

			Write-Host "完了"
			Write-Host "`r`nMicrosoft Visual C++ 2015-20xx Redistributable (x86) と`r`nMicrosoft Visual C++ 2008 Redistributable - x86 のインストールを行います。"
			Write-Host "デバイスへの変更が必要になります。ユーザーアカウント制御のポップアップが出たら [はい] を押して許可してください。`r`n"

			# VCruntimeInstall2015and2008.cmd を管理者権限で実行 (待機)
			Start-Process -FilePath cmd.exe -ArgumentList "/C cd $scriptFilesDirectoryPath & call VCruntimeInstall2015and2008.cmd & exit" -Verb RunAs -WindowStyle Hidden -Wait

			Write-Host "インストーラーが終了しました。"
			break
		}
		1 {
			Write-Host "Microsoft Visual C++ 2015-20xx Redistributable (x86) のインストールを行います。"
			Write-Host "デバイスへの変更が必要になります。ユーザーアカウント制御のポップアップが出たら [はい] を押して許可してください。`r`n"

			# Visual C++ 2015-20xx Redistributable (x86) のインストーラーを実行 (待機)
				# 自動インストールオプションを追加 by Atolycs (20250106)
			Start-Process -FilePath vc_redist.x86.exe -ArgumentList "/install /passive" -WorkingDirectory $scriptFileRoot -WindowStyle Hidden -Wait

			Write-Host "インストーラーが終了しました。"
			Write-Host "`r`nMicrosoft Visual C++ 2008 Redistributable - x86 のインストールをスキップしました。"
			break
		}
	}

	# 選択ここまで
}

# AviUtl ディレクトリ内の全ファイルのブロックを解除 (セキュリティ機能の不要な反応を可能な範囲で防ぐため)
Get-ChildItem -Path $Path -Recurse | Unblock-File

Write-Host -NoNewline "`r`napm.json を作成しています..."

# $apmJsonHash をJSON形式に変換し、apm.json として出力する
ConvertTo-Json $apmJsonHash -Depth 8 -Compress | ForEach-Object { $_ + "`n" } | ForEach-Object { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Encoding Byte -Path "${Path}\apm.json"

Write-Host "完了"
Write-Host -NoNewline "`r`nais.json を作成しています..."

# $aisJsonHash をJSON形式に変換し、ais.json として出力する
ConvertTo-Json $aisJsonHash -Depth 8 -Compress | ForEach-Object { $_ + "`n" } | ForEach-Object { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Encoding Byte -Path "${Path}\ais.json"

Write-Host "完了"
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
