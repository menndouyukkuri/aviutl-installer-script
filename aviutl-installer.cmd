@powershell -NoProfile -ExecutionPolicy Unrestricted "$s = [scriptblock]::create((Get-Content \"%~f0\" | Where-Object { $_.readcount -gt 1 }) -join \"`n\"); & $s %~dp0 %*" & goto :eof

# これ以降は全てPowerShellのスクリプト

<#!
 #  MIT License
 #
 #  Copyright (c) 2025 menndouyukkuri, atolycs, Yu-yu0202, FullWidth-mion
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
	# 以下は1行目の処理によって自動で追加されたパラメーター

	[ValidateScript({
		# 1行目の処理に失敗していて、正しいパラメーターを渡されていない場合
		if ([string]::IsNullOrWhiteSpace($_)) {
			# エラーメッセージを表示
			Write-Host "エラー: スクリプトの実行に必要な情報が取得できませんでした。"

			# 不具合の報告を促すメッセージを表示
			Write-Host "`r`n以下のリンク先で Issue を作成して、この不具合を報告していただけると助かります。`r`nCtrl キーを押しながらクリックするとリンク先が表示できます。`r`nhttps://github.com/menndouyukkuri/aviutl-installer-script/issues/new?template=01-bug-report.md`r`n"

			# ユーザーの操作を待ってスクリプトを終了
			Pause
			exit 1
		}

		# 正しいパラメーターを渡されている場合、$true を返却
		return $true
	})][string]$scriptFileRoot , # スクリプトのファイルが存在するディレクトリのパス


	# 以下はバッチファイル実行時に渡された引数

	# AviUtlをインストールするディレクトリのパス
	[string]$Path = "C:\Applications\AviUtl"
)

# 一時作業フォルダをUserProfile側のTempに展開するように設定 by Atolycs
# これ以降の一時作業フォルダの場所はスクリプトとは別の場所に保存

function New-TempDirectory() {
  $path = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
  while (Test-Path $path) {
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
  }
  New-Item -ItemType Directory -Path $path
}

$TempPath = New-TempDirectory

# バージョン情報を記載
$VerNum = "1.1.21"
$ReleaseDate = "2025-04-20"

# 更新確認用にバージョン情報を格納
$Version = "v" + $VerNum

# バージョン表示
$DisplayNameOfThisScript = "AviUtl Installer Script (Version ${VerNum}_${ReleaseDate})"
$Host.UI.RawUI.WindowTitle = $DisplayNameOfThisScript
Write-Host "$($DisplayNameOfThisScript)`r`n`r`n"

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

# 動作環境を事前にチェックし、問題がある場合は終了するかメッセージを表示する (ais-shared-function.ps1 の関数)
CheckOfEnvironment

Write-Host "完了"


# 本体の更新確認 by Yu-yu0202 (20250121)

Write-Host -NoNewline "`r`nAviUtl Installer Scriptの更新を確認します..."

$AisGithubApi = GithubLatestRelease "menndouyukkuri/aviutl-installer-script"
$AisTagName = $AisGithubApi.tag_name
if (($AisTagName -ne $Version) -and ($scriptFileRoot -eq $AisRootDir)) {
	Write-Host "完了"
	Write-Host -NoNewline "新しいバージョンがあります。更新を行います..."

	# 古いバージョンのファイルを削除
	Remove-Item "${AisRootDir}\docs" -Recurse | Out-Null
	Remove-Item "${AisRootDir}\script_files" -Recurse | Out-Null
	Remove-Item "${AisRootDir}\settings" -Recurse | Out-Null

	# newver ディレクトリを作成し、カレントディレクトリを移動
	New-Item -ItemType Directory -Path newver -Force | Out-Null
	Set-Location newver

	# 本体の最新版のダウンロードURLを取得
	$AISDownloadUrl = $AisGithubApi.assets.browser_download_url

	# 本体のzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $AISDownloadUrl" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# $AisTagName から先頭の「v」を削除
	$AisTagName = $AisTagName.Substring(1)

	# 本体のzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path aviutl-installer_$AisTagName.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# 展開後のzipを削除
	Remove-Item aviutl-installer_$($AisTagName).zip

	# 新バージョンのファイル (aviutl-installer.cmd 以外) をAviUtl Installer Scriptのzipファイルが展開されたと
	# 思われるディレクトリに移動
	Get-ChildItem -Path "aviutl-installer_$AisTagName" | Where-Object { $_.Name -ne "aviutl-installer.cmd" } | Move-Item -Destination $AisRootDir -Force | Out-Null

	Write-Host "完了"

	# 一旦ウィンドウをクリア(Host.UI.RauUI.WindowTitleとコンソールをクリア)にする
	$Host.UI.RawUI.WindowTitle = ""
	Clear-Host

	# カレントディレクトリをスクリプトファイルのあるディレクトリに変更
	Set-Location ..

	# 新バージョンのcmdファイルの2行目からを展開し実行
	$scriptObject = Get-Content -Path "newver\aviutl-installer_$AisTagName\aviutl-installer.cmd" | Select-Object -Skip 1
	$script = Out-String -InputObject $scriptObject
	Invoke-Expression $script


} else {
	Write-Host "完了"

	# 最新版の情報と一致しない場合
	if ($AisTagName -ne $Version) {
		# 最新版の情報を通知
		Write-Host "${AisTagName} がリリースされていますが、自動更新が利用できません。最新版を利用するためには`r`n　　https://github.com/menndouyukkuri/aviutl-installer-script/releases/latest`r`nからダウンロードする必要があります。"

	# 最新版の情報と一致する場合
	} else {
		Write-Host "${Version} は最新版です。"
	}

	# apm.json の元になるハッシュテーブル $apmJsonHash を用意
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

	# ais.json の元になるハッシュテーブル $aisJsonHash を用意
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

	Write-Host -NoNewline "`r`nAviUtlをインストールするフォルダを作成しています..."

	# $Path ディレクトリを作成する (待機)
	Start-Process powershell -ArgumentList "-command New-Item $Path -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl ディレクトリ内に plugins, script, license, readme の4つのディレクトリを作成する (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\plugins`", `"${Path}\script`", `"${Path}\license`", `"${Path}\readme`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "`r`n一時的にファイルを保管するフォルダを作成しています..."

	# tmp ディレクトリを作成する (待機)
	# Start-Process powershell -ArgumentList "-command New-Item ${TempPath} -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ${TempPath}

	Write-Host "完了"
	Write-Host -NoNewline "`r`nフォルダーオプションを確認しています..."

	# フォルダーオプションの「登録されている拡張子は表示しない」が有効の場合、無効にする
	$ExplorerAdvancedRegKey = Get-ItemProperty -LiteralPath "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
	if ($ExplorerAdvancedRegKey.HideFileExt -ne "0") {
		Write-Host "完了"
		Write-Host -NoNewline "「登録されている拡張子は表示しない」を無効にしています..."

		# C:\Applications\AviUtl-Installer-Script ディレクトリを作成する (待機)
		Start-Process powershell -ArgumentList "-command New-Item `"C:\Applications\AviUtl-Installer-Script`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

		# "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion" をバックアップ (待機)
		Start-Process powershell -ArgumentList "-command reg export `"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion`" `"C:\Applications\AviUtl-Installer-Script\Backup.reg`"" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

		# "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" がない場合、作成する (待機)
		if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced")) {
			Start-Process powershell -ArgumentList "-command New-Item `"HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced`" -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait
		}

		# レジストリを書き換えて「登録されている拡張子は表示しない」を無効化
		Set-ItemProperty -LiteralPath "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value "0" -Force
	}

	Write-Host "完了"
	Write-Host -NoNewline "`r`nAviUtl本体 (version 1.10) をダウンロードしています..."

	# AviUtl version 1.10のzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL http://spring-fragrance.mints.ne.jp/aviutl/aviutl110.zip" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "AviUtl本体をインストールしています..."

	# AviUtlのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path aviutl110.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# カレントディレクトリを aviutl110 ディレクトリに変更
	Set-Location aviutl110

	# AviUtl\readme 内に aviutl ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\readme\aviutl`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl ディレクトリ内に aviutl.exe と aviutl.txt を移動
	Move-Item "aviutl.exe", "aviutl.txt" $Path -Force

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..

	# AviUtl\readme\aviutl 内に aviutl.txt をコピー
	Copy-Item "${Path}\aviutl.txt" "${Path}\readme\aviutl" -Force

	Write-Host "完了"
	Write-Host -NoNewline "`r`n拡張編集Plugin version 0.92をダウンロードしています..."

	# 拡張編集Plugin version 0.92のzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL http://spring-fragrance.mints.ne.jp/aviutl/exedit92.zip" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "拡張編集Pluginをインストールしています..."

	# 拡張編集Pluginのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path exedit92.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# カレントディレクトリを exedit92 ディレクトリに変更
	Set-Location exedit92

	# AviUtl\readme 内に exedit ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\readme\exedit`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# exedit.ini は使用せず、かつこの後の処理で邪魔になるので削除する (待機)
	Start-Process powershell -ArgumentList "-command Remove-Item exedit.ini" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl ディレクトリ内にファイルを全て移動
	Move-Item * $Path -Force

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..

	# AviUtl\readme\exedit 内に exedit.txt, lua.txt をコピー
	Copy-Item "${Path}\exedit.txt", "${Path}\lua.txt" "${Path}\readme\exedit" -Force

	Write-Host "完了"
	Write-Host -NoNewline "`r`npatch.aul (謎さうなフォーク版) の最新版情報を取得しています..."

	# patch.aul (謎さうなフォーク版) の最新版のダウンロードURLを取得
	$patchAulGithubApi = GithubLatestRelease "nazonoSAUNA/patch.aul"
	$patchAulUrl = $patchAulGithubApi.assets.browser_download_url

	# $apmJsonHash のバージョン情報をGitHubから取得したデータで最新のものに更新
	$apmJsonHash["packages"]["nazono/patch"]["version"] = $patchAulGithubApi.tag_name

	Write-Host "完了"
	Write-Host -NoNewline "patch.aul (謎さうなフォーク版) をダウンロードしています..."

	# patch.aul (謎さうなフォーク版) のzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $patchAulUrl" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "patch.aul (謎さうなフォーク版) をインストールしています..."

	# patch.aulのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path patch.aul_*.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# カレントディレクトリをpatch.aulのzipファイルを展開したディレクトリに変更
	Set-Location "patch.aul_*"

	# AviUtl\license 内に patch-aul ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\license\patch-aul`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl ディレクトリ内に patch.aul を (待機) 、AviUtl\license\patch-aul 内にその他のファイルをそれぞれ移動
	Start-Process powershell -ArgumentList "-command Move-Item patch.aul $Path -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait
	Move-Item * "${Path}\license\patch-aul" -Force

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..

	Write-Host "完了"
	Write-Host -NoNewline "`r`nL-SMASH Works (Mr-Ojii版) の最新版情報を取得しています..."

	# L-SMASH Works (Mr-Ojii版) の最新版のダウンロードURLを取得
	$lSmashWorksGithubApi = GithubLatestRelease "Mr-Ojii/L-SMASH-Works-Auto-Builds"
	$lSmashWorksAllUrl = $lSmashWorksGithubApi.assets.browser_download_url

	# 複数ある中からAviUtl用のもののみ残す
	$lSmashWorksUrl = $lSmashWorksAllUrl | Where-Object {$_ -like "*Mr-Ojii_vimeo*"}

	# $apmJsonHash のバージョン情報をGitHubから取得したデータで最新のものに更新
		# yyyy/mm/dd を入れる必要があるため tag_name を分割してビルド日のみ取り出して使用
	$lSmashWorksTagNameSplitArray = ($lSmashWorksGithubApi.tag_name) -split "-"
	$lSmashWorksBuildDate = $lSmashWorksTagNameSplitArray[1] + "/" + $lSmashWorksTagNameSplitArray[2] + "/" + $lSmashWorksTagNameSplitArray[3]
	$apmJsonHash["packages"]["MrOjii/LSMASHWorks"]["version"] = $lSmashWorksBuildDate

	Write-Host "完了"
	Write-Host -NoNewline "L-SMASH Works (Mr-Ojii版) をダウンロードしています..."

	# L-SMASH Works (Mr-Ojii版) のzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $lSmashWorksUrl" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "L-SMASH Works (Mr-Ojii版) をインストールしています..."

	# AviUtl\license\l-smash_works 内に Licenses ディレクトリがあれば削除する (エラーの防止)
	if (Test-Path "${Path}\license\l-smash_works\Licenses") {
		Remove-Item "${Path}\license\l-smash_works\Licenses" -Recurse
	}

	# L-SMASH Worksのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path L-SMASH-Works_*.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# カレントディレクトリをL-SMASH Worksのzipファイルを展開したディレクトリに変更
	Set-Location "L-SMASH-Works_*"

	# AviUtl\readme, AviUtl\license 内に l-smash_works ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\readme\l-smash_works`", `"${Path}\license\l-smash_works`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl\plugins ディレクトリ内に lw*.au* を、AviUtl\readme\l-smash_works 内に READM* を (待機) 、
	# AviUtl\license\l-smash_works 内にその他のファイルをそれぞれ移動
	Start-Process powershell -ArgumentList "-command Move-Item lw*.au* `"${Path}\plugins`" -Force; Move-Item READM* `"${Path}\readme\l-smash_works`" -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait
	Move-Item * "${Path}\license\l-smash_works" -Force

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..

	Write-Host "完了"
	Write-Host -NoNewline "`r`nInputPipePluginの最新版情報を取得しています..."

	# InputPipePluginの最新版のダウンロードURLを取得
	$InputPipePluginGithubApi = GithubLatestRelease "amate/InputPipePlugin"
	$InputPipePluginUrl = $InputPipePluginGithubApi.assets.browser_download_url

	# $apmJsonHash のバージョン情報をGitHubから取得したデータで最新のものに更新
		# 基本的には取得したタグ名をそのまま登録すればよい。
		# ただし、AviUtl Package Manager が L-SMASH Works と InputPipePlugin のネイティブ64bit対応の
		# ファイルをインストールしなかった問題 (Issue: https://github.com/team-apm/apm/issues/1666 etc.)
		# の修正により、区別のため apm.json には InputPipePlugin のバージョン2.0が v2.0_1 と記載されるように
		# なっている模様。そのため、v2.0 の場合はそのまま登録するのではなく v2.0_1 とする。
		# 参考: https://github.com/team-apm/apm-data/commit/240a170cc0b121f9b9d1edbe20f19f89146f03aa
	if ($InputPipePluginGithubApi.tag_name -eq "v2.0") {
		$apmJsonHash["packages"]["amate/InputPipePlugin"]["version"] = "v2.0_1"
	} else {
		$apmJsonHash["packages"]["amate/InputPipePlugin"]["version"] = $InputPipePluginGithubApi.tag_name
	}

	Write-Host "完了"
	Write-Host -NoNewline "InputPipePluginをダウンロードしています..."

	# InputPipePluginのzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $InputPipePluginUrl" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "InputPipePluginをインストールしています..."

	# InputPipePluginのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path InputPipePlugin_*.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# カレントディレクトリをInputPipePluginのzipファイルを展開したディレクトリに変更
	Set-Location "InputPipePlugin_*\InputPipePlugin"

	# AviUtl\readme, AviUtl\license 内に inputPipePlugin ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\readme\inputPipePlugin`", `"${Path}\license\inputPipePlugin`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl\license\inputPipePlugin 内に LICENSE を、AviUtl\readme\inputPipePlugin 内に Readme.md を (待機) 、
	# AviUtl\plugins ディレクトリ内にその他のファイルをそれぞれ移動
	Start-Process powershell -ArgumentList "-command Move-Item LICENSE `"${Path}\license\inputPipePlugin`" -Force; Move-Item Readme.md `"${Path}\readme\inputPipePlugin`" -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait
	Move-Item * "${Path}\plugins" -Force

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..\..

	Write-Host "完了"
	Write-Host -NoNewline "`r`nx264guiExの最新版情報を取得しています..."

	# x264guiExの最新版のダウンロードURLを取得
	$x264guiExGithubApi = GithubLatestRelease "rigaya/x264guiEx"
	$x264guiExUrl = $x264guiExGithubApi.assets.browser_download_url

	# $apmJsonHash のバージョン情報をGitHubから取得したデータで最新のものに更新
	$apmJsonHash["packages"]["rigaya/x264guiEx"]["version"] = $x264guiExGithubApi.tag_name

	Write-Host "完了"
	Write-Host -NoNewline "x264guiExをダウンロードしています..."

	# x264guiExのzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $x264guiExUrl" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "x264guiExをインストールしています..."

	# AviUtl\plugins 内に x264guiEx_stg ディレクトリがあれば削除する (エラーの防止)
	if (Test-Path "${Path}\plugins\x264guiEx_stg") {
		Remove-Item "${Path}\plugins\x264guiEx_stg" -Recurse
	}

	# x264guiExのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path x264guiEx_*.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# カレントディレクトリをx264guiExのzipファイルを展開したディレクトリに変更
	Set-Location "x264guiEx_*\x264guiEx_*"

	# カレントディレクトリをx264guiExのzipファイルを展開したディレクトリ内の plugins ディレクトリに変更
	Set-Location plugins

	# AviUtl\plugins 内に現在のディレクトリのファイルを全て移動
	Move-Item * "${Path}\plugins" -Force

	# カレントディレクトリをx264guiExのzipファイルを展開したディレクトリ内の exe_files ディレクトリに変更
	Set-Location ..\exe_files

	# AviUtl ディレクトリ内に exe_files ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\exe_files`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl\exe_files 内に現在のディレクトリのファイルを全て移動
	Move-Item * "${Path}\exe_files" -Force

	# カレントディレクトリをx264guiExのzipファイルを展開したディレクトリに変更
	Set-Location ..

	# AviUtl\readme 内に x264guiEx ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\readme\x264guiEx`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl\readme\x264guiEx 内に x264guiEx_readme.txt を移動
	Move-Item x264guiEx_readme.txt "${Path}\readme\x264guiEx" -Force

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..\..

	Write-Host "完了"
	Write-Host -NoNewline "`r`nMFVideoReaderの最新版情報を取得しています..."

	# MFVideoReaderの最新版のダウンロードURLを取得
	$MFVideoReaderGithubApi = GithubLatestRelease "amate/MFVideoReader"
	$MFVideoReaderUrl = $MFVideoReaderGithubApi.assets.browser_download_url

	# $apmJsonHash のバージョン情報をGitHubから取得したデータで最新のものに更新
	$apmJsonHash["packages"]["amate/MFVideoReader"]["version"] = $MFVideoReaderGithubApi.tag_name

	Write-Host "完了"
	Write-Host -NoNewline "MFVideoReaderをダウンロードしています..."

	# MFVideoReaderのzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $MFVideoReaderUrl" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "MFVideoReaderをインストールしています..."

	# MFVideoReaderのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path MFVideoReader_*.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# カレントディレクトリをMFVideoReaderのzipファイルを展開したディレクトリに変更
	Set-Location "MFVideoReader_*\MFVideoReader"

	# AviUtl\readme, AviUtl\license 内に MFVideoReader ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\readme\MFVideoReader`", `"${Path}\license\MFVideoReader`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl\license\MFVideoReader 内に LICENSE を、AviUtl\readme\MFVideoReader 内に Readme.md を (待機) 、
	# AviUtl\plugins ディレクトリ内にその他のファイルをそれぞれ移動
	Start-Process powershell -ArgumentList "-command Move-Item LICENSE `"${Path}\license\MFVideoReader`" -Force; Move-Item Readme.md `"${Path}\readme\MFVideoReader`" -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait
	Move-Item * "${Path}\plugins" -Force

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..\..

	Write-Host "完了"
	Write-Host -NoNewline "`r`nWebP Susie Plug-inをダウンロードしています..."

	# WebP Susie Plug-inのzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL https://toroidj.github.io/plugin/iftwebp11.zip" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "WebP Susie Plug-inをインストールしています..."

	# WebP Susie Plug-inのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path iftwebp11.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# カレントディレクトリを iftwebp11 ディレクトリに変更
	Set-Location iftwebp11

	# AviUtl\readme 内に iftwebp ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\readme\iftwebp`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl ディレクトリ内に iftwebp.spi を、AviUtl\readme\iftwebp 内に iftwebp.txt をそれぞれ移動
	Move-Item iftwebp.spi $Path -Force
	Move-Item iftwebp.txt "${Path}\readme\iftwebp" -Force

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..

	Write-Host "完了"
	Write-Host -NoNewline "`r`nifheifの最新版情報を取得しています..."

	# ifheifの最新版のダウンロードURLを取得
	$ifheifGithubApi = GithubLatestRelease "Mr-Ojii/ifheif"
	$ifheifUrl = $ifheifGithubApi.assets.browser_download_url

	# $aisJsonHash のバージョン情報をGitHubから取得したデータで最新のものに更新
	$aisJsonHash["packages"]["Mr-Ojii/ifheif"]["version"] = $ifheifGithubApi.tag_name

	Write-Host "完了"
	Write-Host -NoNewline "ifheifをダウンロードしています..."

	# ifheifのzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $ifheifUrl" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "ifheifをインストールしています..."

	# AviUtl\license\ifheif 内に Licenses ディレクトリがあれば削除する (エラーの防止)
	if (Test-Path "${Path}\license\ifheif\Licenses") {
		Remove-Item "${Path}\license\ifheif\Licenses" -Recurse
	}

	# ifheifのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path ifheif.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# カレントディレクトリをifheifのzipファイルを展開したディレクトリに変更
	Set-Location "ifheif"

	# AviUtl\readme, AviUtl\license 内に ifheif ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\readme\ifheif`", `"${Path}\license\ifheif`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl ディレクトリ内に ifheif.spi を、AviUtl\license\ifheif 内に LICENSE と Licenses ディレクトリを、
	# AviUtl\readme\ifheif 内に Readme.md をそれぞれ移動
	Move-Item ifheif.spi $Path -Force
	Move-Item "LICENS*" "${Path}\license\ifheif" -Force
	Move-Item Readme.md "${Path}\readme\ifheif" -Force

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..

	Write-Host "完了"
	Write-Host -NoNewline "`r`n「AviUtlスクリプト一式」をダウンロードしています..."

	# 「AviUtlスクリプト一式」のzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL https://ss1.xrea.com/menkuri.s270.xrea.com/aviutl-installer-script/scripts/script_20160828.zip" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "「AviUtlスクリプト一式」をインストールしています..."

	# AviUtl\script 内に さつき ディレクトリがあれば削除する (エラーの防止)
	if (Test-Path "${Path}\script\さつき") {
		Remove-Item "${Path}\script\さつき" -Recurse
	}

	# AviUtl\script 内に ANM_ssd ディレクトリがあれば削除する (エラーの防止)
	if (Test-Path "${Path}\script\ANM_ssd") {
		Remove-Item "${Path}\script\ANM_ssd" -Recurse
	}

	# AviUtl\script 内に TA_ssd ディレクトリがあれば削除する (エラーの防止)
	if (Test-Path "${Path}\script\TA_ssd") {
		Remove-Item "${Path}\script\TA_ssd" -Recurse
	}

	# 「AviUtlスクリプト一式」のzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path script_20160828.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# カレントディレクトリを script_20160828\script_20160828 ディレクトリに変更
	Set-Location script_20160828\script_20160828

	# AviUtl\script 内に さつき ディレクトリを、AviUtl\readme 内に AviUtlスクリプト一式 ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\script\さつき`", `"${Path}\readme\AviUtlスクリプト一式`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl\script 内に ANM_ssd と TA_ssd を、AviUtl\readme\AviUtlスクリプト一式 内に readme.txt と 使い方.txt を (待機) 、
	# AviUtl\script\さつき 内にその他のファイルをそれぞれ移動
	Start-Process powershell -ArgumentList "-command Move-Item ANM_ssd `"${Path}\script`" -Force; Move-Item TA_ssd `"${Path}\script`" -Force; Move-Item *.txt `"${Path}\readme\AviUtlスクリプト一式`" -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait
	Move-Item * "${Path}\script\さつき" -Force

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..\..

	Write-Host "完了"
	Write-Host -NoNewline "`r`n「値で図形」をダウンロードしています..."

	# 値で図形.obj をダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL `"https://ss1.xrea.com/menkuri.s270.xrea.com/aviutl-installer-script/scripts/値で図形.obj`"" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "「値で図形」をインストールしています..."

	# AviUtl\script 内に Nagomiku ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\script\Nagomiku`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl\script\Nagomiku 内に 値で図形.obj を移動
	Move-Item "値で図形.obj" "${Path}\script\Nagomiku" -Force

	Write-Host "完了"
	Write-Host -NoNewline "`r`n直線スクリプトをダウンロードしています..."

	# 直線スクリプトのzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL `"https://ss1.xrea.com/menkuri.s270.xrea.com/aviutl-installer-script/scripts/直線スクリプト.zip`"" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "直線スクリプトをインストールしています..."

	# 直線スクリプトのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path `"直線スクリプト.zip`" -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# カレントディレクトリを 直線スクリプト ディレクトリに変更
	Set-Location "直線スクリプト"

	# AviUtl\script 内に ちくぼん ディレクトリを、AviUtl\readme, AviUtl\license 内に 直線スクリプト ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\script\ちくぼん`", `"${Path}\readme\直線スクリプト`", `"${Path}\license\直線スクリプト`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl\script\ちくぼん 内に 直線.obj を、AviUtl\license\直線スクリプト 内に LICENSE.txt を (待機) 、
	# AviUtl\readme\直線スクリプト 内にその他のファイルをそれぞれ移動
	Start-Process powershell -ArgumentList "-command Move-Item `"直線.obj`" `"${Path}\script\ちくぼん`" -Force; Move-Item LICENSE.txt `"${Path}\license\直線スクリプト`" -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait
	Move-Item * "${Path}\readme\直線スクリプト" -Force

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..

	Write-Host "完了"


	# LuaJITのインストール by Yu-yu0202 (20250109)
		# 不具合が直らなかったため再実装 by menndouyukkuri (20250110)

	Write-Host -NoNewline "`r`nLuaJITの最新版情報を取得しています..."

	# LuaJITの最新版のダウンロードURLを取得
	$luaJitGithubApi = GithubLatestRelease "Per-Terra/LuaJIT-Auto-Builds"
	$luaJitAllUrl = $luaJitGithubApi.assets.browser_download_url

	# 複数ある中からAviUtl用のもののみ残す
	$luaJitUrl = $luaJitAllUrl | Where-Object {$_ -like "*LuaJIT_2.1_Win_x86.zip"}

	# $aisJsonHash のバージョン情報をGitHubから取得したデータで最新のものに更新
		# yyyy/mm/dd を入れる必要があるため tag_name を分割してビルド日のみ取り出して使用
	$luaJitTagNameSplitArray = ($luaJitGithubApi.tag_name) -split "-"
	$luaJitBuildDate = $luaJitTagNameSplitArray[1] + "/" + $luaJitTagNameSplitArray[2] + "/" + $luaJitTagNameSplitArray[3]
	$aisJsonHash["packages"]["Per-Terra/LuaJIT"]["version"] = $luaJitBuildDate

	Write-Host "完了"
	Write-Host -NoNewline "LuaJITをダウンロードしています..."

	# LuaJITのzipファイルをダウンロード (待機)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $luaJitUrl" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "完了"
	Write-Host -NoNewline "LuaJITをインストールしています..."

	# 既に exedit_lua51.dll が存在する場合は以下の処理をスキップする (エラーの防止)
	if (!(Test-Path "${Path}\exedit_lua51.dll")) {
		# AviUtl ディレクトリに既にある lua51.dll (拡張編集Pluginのもの) をリネームしてバックアップする
		Rename-Item "${Path}\lua51.dll" "exedit_lua51.dll" -Force
	}

	# AviUtl\readme\LuaJIT 内に doc ディレクトリがあれば削除する (エラーの防止)
	if (Test-Path "${Path}\readme\LuaJIT\doc") {
		Remove-Item "${Path}\readme\LuaJIT\doc" -Recurse
	}

	# LuaJITのzipファイルを展開 (待機)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path `"LuaJIT_2.1_Win_x86.zip`" -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# カレントディレクトリをLuaJITのzipファイルを展開したディレクトリに変更
	Set-Location "LuaJIT_2.1_Win_x86"

	# AviUtl\readme, AviUtl\license 内に LuaJIT ディレクトリを作成 (待機)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\readme\LuaJIT`", `"${Path}\license\LuaJIT`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl ディレクトリ内に lua51.dll を、AviUtl\readme\LuaJIT 内に README と doc を、AviUtl\license\LuaJIT 内に
	# COPYRIGHT と About-This-Build.txt をそれぞれ移動
	Move-Item "lua51.dll" $Path -Force
	Move-Item README "${Path}\readme\LuaJIT" -Force
	Move-Item doc "${Path}\readme\LuaJIT" -Force
	Move-Item COPYRIGHT "${Path}\license\LuaJIT" -Force
	Move-Item "About-This-Build.txt" "${Path}\license\LuaJIT" -Force

	# カレントディレクトリを tmp ディレクトリに変更
	Set-Location ..

	Write-Host "完了"


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
		Start-Process -FilePath curl.exe -ArgumentList "-OL $downloadUrl" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

		Write-Host -NoNewline "."

		# zipファイルを展開 (待機)
		Start-Process powershell -ArgumentList "-command Expand-Archive -Path Aviutl_${repoName}_*.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait
	}

	Write-Host " 完了"
	Write-Host "エンコーダーのチェック、および使用可能な出力プラグインのインストールを行います。"

	$hwEncoders = [ordered]@{
		"NVEnc"  = "NVEncC.exe"
		"QSVEnc" = "QSVEncC.exe"
		"VCEEnc" = "VCEEncC.exe"
	}

	# 画質のよいNVEncから順にQSVEnc、VCEEncとチェックしていき、最初に使用可能なものを確認した時点でそれを導入してforeachを離脱
	foreach ($hwEncoder in $hwEncoders.GetEnumerator()) {
		# エンコーダーの実行ファイルのパスを格納
		Set-Location "Aviutl_$($hwEncoder.Key)_*"
		$extdir = ${TempPath}
		$encoderPath = Join-Path -Path $extdir -ChildPath "exe_files\$($hwEncoder.Key)C\x86\$($hwEncoder.Value)"
		Set-Location ..

		# エンコーダーの実行ファイルの有無を確認
		if (Test-Path $encoderPath) {
			# ハードウェアエンコードできるかチェック
			$process = Start-Process -FilePath $encoderPath -ArgumentList "--check-hw" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait -PassThru

			# ExitCode が 0 = 使用可能な場合はインストール
			if ($process.ExitCode -eq 0) {
				# AviUtl\exe_files 内に $($hwEncoder.Key)C ディレクトリがあれば削除する (エラーの防止)
				if (Test-Path "${Path}\exe_files\$($hwEncoder.Key)C") {
					Remove-Item "${Path}\exe_files\$($hwEncoder.Key)C" -Recurse
				}

				# AviUtl\plugins 内に $($hwEncoder.Key)_stg ディレクトリがあれば削除する (エラーの防止)
				if (Test-Path "${Path}\plugins\$($hwEncoder.Key)_stg") {
					Remove-Item "${Path}\plugins\$($hwEncoder.Key)_stg" -Recurse
				}

				Write-Host -NoNewline "$($hwEncoder.Key)が使用可能です。$($hwEncoder.Key)をインストールしています..."

				# readme ディレクトリを作成
				New-Item -ItemType Directory -Path "${Path}\readme\$($hwEncoder.Key)" -Force | Out-Null

				# 展開後のそれぞれのファイルを移動
				Move-Item -Path "$extdir\exe_files\*" -Destination "${Path}\exe_files" -Force
				Move-Item -Path "$extdir\plugins\*" -Destination "${Path}\plugins" -Force
				Move-Item -Path "$extdir\*.bat" -Destination $Path -Force
				Move-Item -Path "$extdir\*_readme.txt" -Destination "${Path}\readme\$($hwEncoder.Key)" -Force

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
		Start-Process -FilePath curl.exe -ArgumentList "-OL https://aka.ms/vs/17/release/vc_redist.x86.exe" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

		Write-Host "完了"
		Write-Host "Microsoft Visual C++ 2015-20xx Redistributable (x86) のインストールを行います。"
		Write-Host "デバイスへの変更が必要になります。ユーザーアカウント制御のポップアップが出たら [はい] を押して許可してください。`r`n"

		# Visual C++ 2015-20xx Redistributable (x86) のインストーラーを実行 (待機)
			# 自動インストールオプションを追加 by Atolycs (20250106)
		Start-Process -FilePath vc_redist.x86.exe -ArgumentList "/install /passive" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

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
			New-Object $tChoiceDescription ("はい(&Y)",  "インストールを実行します。")
			New-Object $tChoiceDescription ("いいえ(&N)", "インストールをせず、スキップして次の処理に進みます。")
		)

		$result = $host.ui.PromptForChoice($choiceTitle, $choiceMessage, $choiceOptions, 0)
		switch ($result) {
			0 {
				Write-Host -NoNewline "`r`nMicrosoft Visual C++ 2008 Redistributable - x86 のインストーラーをダウンロードしています..."

				# Visual C++ 2008 Redistributable - x86 のインストーラーをダウンロード (待機)
				Start-Process -FilePath curl.exe -ArgumentList "-OL https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

				Write-Host "完了"
				Write-Host "Microsoft Visual C++ 2008 Redistributable - x86 のインストールを行います。"
				Write-Host "デバイスへの変更が必要になります。ユーザーアカウント制御のポップアップが出たら [はい] を押して許可してください。`r`n"

				# Visual C++ 2008 Redistributable - x86 のインストーラーを実行 (待機)
					# 自動インストールオプションを追加 by Atolycs (20250106)
				Start-Process -FilePath vcredist_x86.exe -ArgumentList "/qb" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

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
		Start-Process -FilePath curl.exe -ArgumentList "-OL https://aka.ms/vs/17/release/vc_redist.x86.exe" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

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
				Start-Process -FilePath curl.exe -ArgumentList "-OL https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

				Write-Host "完了"
				Write-Host "`r`nMicrosoft Visual C++ 2015-20xx Redistributable (x86) と`r`nMicrosoft Visual C++ 2008 Redistributable - x86 のインストールを行います。"
				Write-Host "デバイスへの変更が必要になります。ユーザーアカウント制御のポップアップが出たら [はい] を押して許可してください。`r`n"

				# VCruntimeInstall2015and2008.cmd を管理者権限で実行 (待機)
				Start-Process -FilePath cmd.exe -ArgumentList "/C cd $scriptFilesDirectoryPath & call VCruntimeInstall2015and2008.cmd $scriptFileRoot & exit" -Verb RunAs -WindowStyle Hidden -Wait

				Write-Host "インストーラーが終了しました。"
				break
			}
			1 {
				Write-Host "Microsoft Visual C++ 2015-20xx Redistributable (x86) のインストールを行います。"
				Write-Host "デバイスへの変更が必要になります。ユーザーアカウント制御のポップアップが出たら [はい] を押して許可してください。`r`n"

				# Visual C++ 2015-20xx Redistributable (x86) のインストーラーを実行 (待機)
					# 自動インストールオプションを追加 by Atolycs (20250106)
				Start-Process -FilePath vc_redist.x86.exe -ArgumentList "/install /passive" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

				Write-Host "インストーラーが終了しました。"
				Write-Host "`r`nMicrosoft Visual C++ 2008 Redistributable - x86 のインストールをスキップしました。"
				break
			}
		}

		# 選択ここまで
	}

	Write-Host -NoNewline "`r`n設定ファイルをコピーしています..."

	# AviUtl\plugins 内に lsmash.ini と MFVideoReaderConfig.ini をコピー
	Copy-Item "${settingsDirectoryPath}\lsmash.ini", "${settingsDirectoryPath}\MFVideoReaderConfig.ini" "${Path}\plugins"

	# AviUtl ディレクトリ内に aviutl.ini, exedit.ini と デフォルト.cfg をコピー
	Copy-Item "${settingsDirectoryPath}\aviutl.ini", "${settingsDirectoryPath}\exedit.ini", "${settingsDirectoryPath}\デフォルト.cfg" $Path

	# AviUtl ディレクトリ内の全ファイルのブロックを解除 (セキュリティ機能の不要な反応を可能な範囲で防ぐため)
	Get-ChildItem -Path $Path -Recurse | Unblock-File

	Write-Host "完了"
	Write-Host -NoNewline "`r`napm.json を作成しています..."

	# $apmJsonHash をJSON形式に変換し、apm.json として出力する
	ConvertTo-Json $apmJsonHash -Depth 8 -Compress | ForEach-Object { $_ + "`n" } | ForEach-Object { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Encoding Byte -Path "${Path}\apm.json"

	Write-Host "完了"
	Write-Host -NoNewline "`r`nais.json を作成しています..."

	# $aisJsonHash をJSON形式に変換し、ais.json として出力する
	ConvertTo-Json $aisJsonHash -Depth 8 -Compress | ForEach-Object { $_ + "`n" } | ForEach-Object { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Encoding Byte -Path "${Path}\ais.json"

	Write-Host "完了"
	Write-Host -NoNewline "`r`nデスクトップにショートカットファイルを作成しています..."

	# WSHを用いてデスクトップにAviUtlのショートカットを作成する
	$DesktopShortcutFolder = [Environment]::GetFolderPath("Desktop")
	$DesktopShortcutFile = Join-Path -Path $DesktopShortcutFolder -ChildPath "AviUtl.lnk"
	$DesktopWshShell = New-Object -comObject WScript.Shell
	$DesktopShortcut = $DesktopWshShell.CreateShortcut($DesktopShortcutFile)
	$DesktopShortcut.TargetPath = "${Path}\aviutl.exe"
	$DesktopShortcut.IconLocation = "${Path}\aviutl.exe,0"
	$DesktopShortcut.WorkingDirectory = $Path
	$DesktopShortcut.Save()

	Write-Host "完了"
	Write-Host -NoNewline "スタートメニューにショートカットファイルを作成しています..."

	# WSHを用いてスタートメニューにAviUtlのショートカットを作成する
	$ProgramsShortcutFolder = [Environment]::GetFolderPath("Programs")
	$ProgramsShortcutFile = Join-Path -Path $ProgramsShortcutFolder -ChildPath "AviUtl.lnk"
	$ProgramsWshShell = New-Object -comObject WScript.Shell
	$ProgramsShortcut = $ProgramsWshShell.CreateShortcut($ProgramsShortcutFile)
	$ProgramsShortcut.TargetPath = "${Path}\aviutl.exe"
	$ProgramsShortcut.IconLocation = "${Path}\aviutl.exe,0"
	$ProgramsShortcut.WorkingDirectory = $Path
	$ProgramsShortcut.Save()

	Write-Host "完了"
	Write-Host -NoNewline "`r`nインストールに使用した不要なファイルを削除しています..."

	# カレントディレクトリをスクリプトファイルのあるディレクトリに変更
	Set-Location ${Path}

	# tmp ディレクトリを削除 (By 20250307 Atolycs)
  # UserProfileに作成した一時フォルダを削除
	Remove-Item ${TempPath} -Recurse

	Write-Host "完了"

	if (Test-Path "script_files\必須プラグイン・スクリプトを更新する.cmd") {
		# 必須プラグイン・スクリプトを更新する.cmd をカレントディレクトリに移動
		Move-Item "script_files\必須プラグイン・スクリプトを更新する.cmd" . -Force

		# aviutl-installer.cmd の場所を確認
		if (Test-Path "newver\aviutl-installer_${VerNum}\aviutl-installer.cmd") {
			# aviutl-installer.cmd を script_files ディレクトリに移動
			Move-Item "newver\aviutl-installer_${VerNum}\aviutl-installer.cmd" script_files -Force

			# newver ディレクトリを削除
			Remove-Item newver -Recurse
		} else {
			# aviutl-installer.cmd を script_files ディレクトリに移動
			Move-Item aviutl-installer.cmd script_files -Force
		}
	} else {
		# aviutl-installer.cmd の場所を確認
		if (Test-Path "newver\aviutl-installer_${VerNum}\aviutl-installer.cmd") {
			# aviutl-installer.cmd をカレントディレクトリに移動
			Move-Item "newver\aviutl-installer_${VerNum}\aviutl-installer.cmd" . -Force

			# newver ディレクトリを削除
			Remove-Item newver -Recurse
		}
	}

	# ユーザーの操作を待って終了
	Write-Host -NoNewline "`r`n`r`n`r`nインストールが完了しました！`r`n`r`n`r`nreadme フォルダを開いて"
	Pause

	# 終了時に readme ディレクトリを表示
	Invoke-Item "${Path}\readme"
}
