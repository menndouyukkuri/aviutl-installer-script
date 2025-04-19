@powershell -NoProfile -ExecutionPolicy Unrestricted "$s = [scriptblock]::create((Get-Content \"%~f0\" | Where-Object { $_.readcount -gt 1 }) -join \"`n\"); & $s %~dp0 %*" & goto :eof

# ����ȍ~�͑S��PowerShell�̃X�N���v�g

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
	# �ȉ���1�s�ڂ̏����ɂ���Ď����Œǉ����ꂽ�p�����[�^�[

	[ValidateScript({
		# 1�s�ڂ̏����Ɏ��s���Ă��āA�������p�����[�^�[��n����Ă��Ȃ��ꍇ
		if ([string]::IsNullOrWhiteSpace($_)) {
			# �G���[���b�Z�[�W��\��
			Write-Host "�G���[: �X�N���v�g�̎��s�ɕK�v�ȏ�񂪎擾�ł��܂���ł����B"

			# �s��̕񍐂𑣂����b�Z�[�W��\��
			Write-Host "`r`n�ȉ��̃����N��� Issue ���쐬���āA���̕s���񍐂��Ă���������Ə�����܂��B`r`nCtrl �L�[�������Ȃ���N���b�N����ƃ����N�悪�\���ł��܂��B`r`nhttps://github.com/menndouyukkuri/aviutl-installer-script/issues/new?template=01-bug-report.md`r`n"

			# ���[�U�[�̑����҂��ăX�N���v�g���I��
			Pause
			exit 1
		}

		# �������p�����[�^�[��n����Ă���ꍇ�A$true ��ԋp
		return $true
	})][string]$scriptFileRoot , # �X�N���v�g�̃t�@�C�������݂���f�B���N�g���̃p�X


	# �ȉ��̓o�b�`�t�@�C�����s���ɓn���ꂽ����

	# AviUtl���C���X�g�[������f�B���N�g���̃p�X
	[string]$Path = "C:\Applications\AviUtl"
)

# �ꎞ��ƃt�H���_��UserProfile����Temp�ɓW�J����悤�ɐݒ� by Atolycs
# ����ȍ~�̈ꎞ��ƃt�H���_�̏ꏊ�̓X�N���v�g�Ƃ͕ʂ̏ꏊ�ɕۑ�

function New-TempDirectory() {
  $path = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
  while (Test-Path $path) {
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
  }
  New-Item -ItemType Directory -Path $path
}

$TempPath = New-TempDirectory

# �o�[�W���������L��
$VerNum = "1.1.21"
$ReleaseDate = "2025-04-20"

# �X�V�m�F�p�Ƀo�[�W���������i�[
$Version = "v" + $VerNum

# �o�[�W�����\��
$DisplayNameOfThisScript = "AviUtl Installer Script (Version ${VerNum}_${ReleaseDate})"
$Host.UI.RawUI.WindowTitle = $DisplayNameOfThisScript
Write-Host "$($DisplayNameOfThisScript)`r`n`r`n"

# settings �f�B���N�g���̏ꏊ���m�F
if (Test-Path ".\settings") {
	$settingsDirectoryPath = Convert-Path ".\settings"
} elseif (Test-Path "..\settings") {
	$settingsDirectoryPath = Convert-Path "..\settings"
} else {
	Write-Host "���������G���[: settings �t�H���_��������܂���B"
	Pause
	exit
}

# AviUtl Installer Script��zip�t�@�C�����W�J���ꂽ�Ǝv����f�B���N�g���̃p�X��ۑ�
$AisRootDir = Split-Path $settingsDirectoryPath -Parent

Write-Host -NoNewline "������..."

# AviUtl Installer Script��zip�t�@�C�����W�J���ꂽ�Ǝv����f�B���N�g�� ($AisRootDir) ����
# .cmd �t�@�C���� .ps1 �t�@�C���̃u���b�N������ (���s���ɖ��ʂȌx����\�������Ȃ�����)
Get-ChildItem -Path $AisRootDir -Include "*.cmd", "*.ps1" -Recurse | Unblock-File

Start-Sleep -Milliseconds 500

# script_files �f�B���N�g���̃p�X�� $scriptFilesDirectoryPath �Ɋi�[
	# settings �f�B���N�g���Ɠ����e�f�B���N�g���������Ƃ�O��Ƃ��Ă���̂Œ���
$scriptFilesDirectoryPath = Join-Path -Path $AisRootDir -ChildPath script_files

# script_files\ais-shared-function.ps1 ��ǂݍ���
. "${scriptFilesDirectoryPath}\ais-shared-function.ps1"

# ����������O�Ƀ`�F�b�N���A��肪����ꍇ�͏I�����邩���b�Z�[�W��\������ (ais-shared-function.ps1 �̊֐�)
CheckOfEnvironment

Write-Host "����"


# �{�̂̍X�V�m�F by Yu-yu0202 (20250121)

Write-Host -NoNewline "`r`nAviUtl Installer Script�̍X�V���m�F���܂�..."

$AisGithubApi = GithubLatestRelease "menndouyukkuri/aviutl-installer-script"
$AisTagName = $AisGithubApi.tag_name
if (($AisTagName -ne $Version) -and ($scriptFileRoot -eq $AisRootDir)) {
	Write-Host "����"
	Write-Host -NoNewline "�V�����o�[�W����������܂��B�X�V���s���܂�..."

	# �Â��o�[�W�����̃t�@�C�����폜
	Remove-Item "${AisRootDir}\docs" -Recurse | Out-Null
	Remove-Item "${AisRootDir}\script_files" -Recurse | Out-Null
	Remove-Item "${AisRootDir}\settings" -Recurse | Out-Null

	# newver �f�B���N�g�����쐬���A�J�����g�f�B���N�g�����ړ�
	New-Item -ItemType Directory -Path newver -Force | Out-Null
	Set-Location newver

	# �{�̂̍ŐV�ł̃_�E�����[�hURL���擾
	$AISDownloadUrl = $AisGithubApi.assets.browser_download_url

	# �{�̂�zip�t�@�C�����_�E�����[�h (�ҋ@)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $AISDownloadUrl" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# $AisTagName ����擪�́uv�v���폜
	$AisTagName = $AisTagName.Substring(1)

	# �{�̂�zip�t�@�C����W�J (�ҋ@)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path aviutl-installer_$AisTagName.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# �W�J���zip���폜
	Remove-Item aviutl-installer_$($AisTagName).zip

	# �V�o�[�W�����̃t�@�C�� (aviutl-installer.cmd �ȊO) ��AviUtl Installer Script��zip�t�@�C�����W�J���ꂽ��
	# �v����f�B���N�g���Ɉړ�
	Get-ChildItem -Path "aviutl-installer_$AisTagName" | Where-Object { $_.Name -ne "aviutl-installer.cmd" } | Move-Item -Destination $AisRootDir -Force | Out-Null

	Write-Host "����"

	# ��U�E�B���h�E���N���A(Host.UI.RauUI.WindowTitle�ƃR���\�[�����N���A)�ɂ���
	$Host.UI.RawUI.WindowTitle = ""
	Clear-Host

	# �J�����g�f�B���N�g�����X�N���v�g�t�@�C���̂���f�B���N�g���ɕύX
	Set-Location ..

	# �V�o�[�W������cmd�t�@�C����2�s�ڂ����W�J�����s
	$scriptObject = Get-Content -Path "newver\aviutl-installer_$AisTagName\aviutl-installer.cmd" | Select-Object -Skip 1
	$script = Out-String -InputObject $scriptObject
	Invoke-Expression $script


} else {
	Write-Host "����"

	# �ŐV�ł̏��ƈ�v���Ȃ��ꍇ
	if ($AisTagName -ne $Version) {
		# �ŐV�ł̏���ʒm
		Write-Host "${AisTagName} �������[�X����Ă��܂����A�����X�V�����p�ł��܂���B�ŐV�ł𗘗p���邽�߂ɂ�`r`n�@�@https://github.com/menndouyukkuri/aviutl-installer-script/releases/latest`r`n����_�E�����[�h����K�v������܂��B"

	# �ŐV�ł̏��ƈ�v����ꍇ
	} else {
		Write-Host "${Version} �͍ŐV�łł��B"
	}

	# apm.json �̌��ɂȂ�n�b�V���e�[�u�� $apmJsonHash ��p��
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

	# ais.json �̌��ɂȂ�n�b�V���e�[�u�� $aisJsonHash ��p��
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

	Write-Host -NoNewline "`r`nAviUtl���C���X�g�[������t�H���_���쐬���Ă��܂�..."

	# $Path �f�B���N�g�����쐬���� (�ҋ@)
	Start-Process powershell -ArgumentList "-command New-Item $Path -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl �f�B���N�g������ plugins, script, license, readme ��4�̃f�B���N�g�����쐬���� (�ҋ@)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\plugins`", `"${Path}\script`", `"${Path}\license`", `"${Path}\readme`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "����"
	Write-Host -NoNewline "`r`n�ꎞ�I�Ƀt�@�C����ۊǂ���t�H���_���쐬���Ă��܂�..."

	# tmp �f�B���N�g�����쐬���� (�ҋ@)
	# Start-Process powershell -ArgumentList "-command New-Item ${TempPath} -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# �J�����g�f�B���N�g���� tmp �f�B���N�g���ɕύX
	Set-Location ${TempPath}

	Write-Host "����"
	Write-Host -NoNewline "`r`n�t�H���_�[�I�v�V�������m�F���Ă��܂�..."

	# �t�H���_�[�I�v�V�����́u�o�^����Ă���g���q�͕\�����Ȃ��v���L���̏ꍇ�A�����ɂ���
	$ExplorerAdvancedRegKey = Get-ItemProperty -LiteralPath "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
	if ($ExplorerAdvancedRegKey.HideFileExt -ne "0") {
		Write-Host "����"
		Write-Host -NoNewline "�u�o�^����Ă���g���q�͕\�����Ȃ��v�𖳌��ɂ��Ă��܂�..."

		# C:\Applications\AviUtl-Installer-Script �f�B���N�g�����쐬���� (�ҋ@)
		Start-Process powershell -ArgumentList "-command New-Item `"C:\Applications\AviUtl-Installer-Script`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

		# "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion" ���o�b�N�A�b�v (�ҋ@)
		Start-Process powershell -ArgumentList "-command reg export `"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion`" `"C:\Applications\AviUtl-Installer-Script\Backup.reg`"" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

		# "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" ���Ȃ��ꍇ�A�쐬���� (�ҋ@)
		if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced")) {
			Start-Process powershell -ArgumentList "-command New-Item `"HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced`" -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait
		}

		# ���W�X�g�������������āu�o�^����Ă���g���q�͕\�����Ȃ��v�𖳌���
		Set-ItemProperty -LiteralPath "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value "0" -Force
	}

	Write-Host "����"
	Write-Host -NoNewline "`r`nAviUtl�{�� (version 1.10) ���_�E�����[�h���Ă��܂�..."

	# AviUtl version 1.10��zip�t�@�C�����_�E�����[�h (�ҋ@)
	Start-Process -FilePath curl.exe -ArgumentList "-OL http://spring-fragrance.mints.ne.jp/aviutl/aviutl110.zip" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "����"
	Write-Host -NoNewline "AviUtl�{�̂��C���X�g�[�����Ă��܂�..."

	# AviUtl��zip�t�@�C����W�J (�ҋ@)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path aviutl110.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# �J�����g�f�B���N�g���� aviutl110 �f�B���N�g���ɕύX
	Set-Location aviutl110

	# AviUtl\readme ���� aviutl �f�B���N�g�����쐬 (�ҋ@)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\readme\aviutl`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl �f�B���N�g������ aviutl.exe �� aviutl.txt ���ړ�
	Move-Item "aviutl.exe", "aviutl.txt" $Path -Force

	# �J�����g�f�B���N�g���� tmp �f�B���N�g���ɕύX
	Set-Location ..

	# AviUtl\readme\aviutl ���� aviutl.txt ���R�s�[
	Copy-Item "${Path}\aviutl.txt" "${Path}\readme\aviutl" -Force

	Write-Host "����"
	Write-Host -NoNewline "`r`n�g���ҏWPlugin version 0.92���_�E�����[�h���Ă��܂�..."

	# �g���ҏWPlugin version 0.92��zip�t�@�C�����_�E�����[�h (�ҋ@)
	Start-Process -FilePath curl.exe -ArgumentList "-OL http://spring-fragrance.mints.ne.jp/aviutl/exedit92.zip" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "����"
	Write-Host -NoNewline "�g���ҏWPlugin���C���X�g�[�����Ă��܂�..."

	# �g���ҏWPlugin��zip�t�@�C����W�J (�ҋ@)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path exedit92.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# �J�����g�f�B���N�g���� exedit92 �f�B���N�g���ɕύX
	Set-Location exedit92

	# AviUtl\readme ���� exedit �f�B���N�g�����쐬 (�ҋ@)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\readme\exedit`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# exedit.ini �͎g�p�����A�����̌�̏����Ŏז��ɂȂ�̂ō폜���� (�ҋ@)
	Start-Process powershell -ArgumentList "-command Remove-Item exedit.ini" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl �f�B���N�g�����Ƀt�@�C����S�Ĉړ�
	Move-Item * $Path -Force

	# �J�����g�f�B���N�g���� tmp �f�B���N�g���ɕύX
	Set-Location ..

	# AviUtl\readme\exedit ���� exedit.txt, lua.txt ���R�s�[
	Copy-Item "${Path}\exedit.txt", "${Path}\lua.txt" "${Path}\readme\exedit" -Force

	Write-Host "����"
	Write-Host -NoNewline "`r`npatch.aul (�䂳���ȃt�H�[�N��) �̍ŐV�ŏ����擾���Ă��܂�..."

	# patch.aul (�䂳���ȃt�H�[�N��) �̍ŐV�ł̃_�E�����[�hURL���擾
	$patchAulGithubApi = GithubLatestRelease "nazonoSAUNA/patch.aul"
	$patchAulUrl = $patchAulGithubApi.assets.browser_download_url

	# $apmJsonHash �̃o�[�W��������GitHub����擾�����f�[�^�ōŐV�̂��̂ɍX�V
	$apmJsonHash["packages"]["nazono/patch"]["version"] = $patchAulGithubApi.tag_name

	Write-Host "����"
	Write-Host -NoNewline "patch.aul (�䂳���ȃt�H�[�N��) ���_�E�����[�h���Ă��܂�..."

	# patch.aul (�䂳���ȃt�H�[�N��) ��zip�t�@�C�����_�E�����[�h (�ҋ@)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $patchAulUrl" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "����"
	Write-Host -NoNewline "patch.aul (�䂳���ȃt�H�[�N��) ���C���X�g�[�����Ă��܂�..."

	# patch.aul��zip�t�@�C����W�J (�ҋ@)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path patch.aul_*.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# �J�����g�f�B���N�g����patch.aul��zip�t�@�C����W�J�����f�B���N�g���ɕύX
	Set-Location "patch.aul_*"

	# AviUtl\license ���� patch-aul �f�B���N�g�����쐬 (�ҋ@)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\license\patch-aul`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl �f�B���N�g������ patch.aul �� (�ҋ@) �AAviUtl\license\patch-aul ���ɂ��̑��̃t�@�C�������ꂼ��ړ�
	Start-Process powershell -ArgumentList "-command Move-Item patch.aul $Path -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait
	Move-Item * "${Path}\license\patch-aul" -Force

	# �J�����g�f�B���N�g���� tmp �f�B���N�g���ɕύX
	Set-Location ..

	Write-Host "����"
	Write-Host -NoNewline "`r`nL-SMASH Works (Mr-Ojii��) �̍ŐV�ŏ����擾���Ă��܂�..."

	# L-SMASH Works (Mr-Ojii��) �̍ŐV�ł̃_�E�����[�hURL���擾
	$lSmashWorksGithubApi = GithubLatestRelease "Mr-Ojii/L-SMASH-Works-Auto-Builds"
	$lSmashWorksAllUrl = $lSmashWorksGithubApi.assets.browser_download_url

	# �������钆����AviUtl�p�̂��̂̂ݎc��
	$lSmashWorksUrl = $lSmashWorksAllUrl | Where-Object {$_ -like "*Mr-Ojii_vimeo*"}

	# $apmJsonHash �̃o�[�W��������GitHub����擾�����f�[�^�ōŐV�̂��̂ɍX�V
		# yyyy/mm/dd ������K�v�����邽�� tag_name �𕪊����ăr���h���̂ݎ��o���Ďg�p
	$lSmashWorksTagNameSplitArray = ($lSmashWorksGithubApi.tag_name) -split "-"
	$lSmashWorksBuildDate = $lSmashWorksTagNameSplitArray[1] + "/" + $lSmashWorksTagNameSplitArray[2] + "/" + $lSmashWorksTagNameSplitArray[3]
	$apmJsonHash["packages"]["MrOjii/LSMASHWorks"]["version"] = $lSmashWorksBuildDate

	Write-Host "����"
	Write-Host -NoNewline "L-SMASH Works (Mr-Ojii��) ���_�E�����[�h���Ă��܂�..."

	# L-SMASH Works (Mr-Ojii��) ��zip�t�@�C�����_�E�����[�h (�ҋ@)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $lSmashWorksUrl" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "����"
	Write-Host -NoNewline "L-SMASH Works (Mr-Ojii��) ���C���X�g�[�����Ă��܂�..."

	# AviUtl\license\l-smash_works ���� Licenses �f�B���N�g��������΍폜���� (�G���[�̖h�~)
	if (Test-Path "${Path}\license\l-smash_works\Licenses") {
		Remove-Item "${Path}\license\l-smash_works\Licenses" -Recurse
	}

	# L-SMASH Works��zip�t�@�C����W�J (�ҋ@)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path L-SMASH-Works_*.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# �J�����g�f�B���N�g����L-SMASH Works��zip�t�@�C����W�J�����f�B���N�g���ɕύX
	Set-Location "L-SMASH-Works_*"

	# AviUtl\readme, AviUtl\license ���� l-smash_works �f�B���N�g�����쐬 (�ҋ@)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\readme\l-smash_works`", `"${Path}\license\l-smash_works`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl\plugins �f�B���N�g������ lw*.au* ���AAviUtl\readme\l-smash_works ���� READM* �� (�ҋ@) �A
	# AviUtl\license\l-smash_works ���ɂ��̑��̃t�@�C�������ꂼ��ړ�
	Start-Process powershell -ArgumentList "-command Move-Item lw*.au* `"${Path}\plugins`" -Force; Move-Item READM* `"${Path}\readme\l-smash_works`" -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait
	Move-Item * "${Path}\license\l-smash_works" -Force

	# �J�����g�f�B���N�g���� tmp �f�B���N�g���ɕύX
	Set-Location ..

	Write-Host "����"
	Write-Host -NoNewline "`r`nInputPipePlugin�̍ŐV�ŏ����擾���Ă��܂�..."

	# InputPipePlugin�̍ŐV�ł̃_�E�����[�hURL���擾
	$InputPipePluginGithubApi = GithubLatestRelease "amate/InputPipePlugin"
	$InputPipePluginUrl = $InputPipePluginGithubApi.assets.browser_download_url

	# $apmJsonHash �̃o�[�W��������GitHub����擾�����f�[�^�ōŐV�̂��̂ɍX�V
		# ��{�I�ɂ͎擾�����^�O�������̂܂ܓo�^����΂悢�B
		# �������AAviUtl Package Manager �� L-SMASH Works �� InputPipePlugin �̃l�C�e�B�u64bit�Ή���
		# �t�@�C�����C���X�g�[�����Ȃ�������� (Issue: https://github.com/team-apm/apm/issues/1666 etc.)
		# �̏C���ɂ��A��ʂ̂��� apm.json �ɂ� InputPipePlugin �̃o�[�W����2.0�� v2.0_1 �ƋL�ڂ����悤��
		# �Ȃ��Ă���͗l�B���̂��߁Av2.0 �̏ꍇ�͂��̂܂ܓo�^����̂ł͂Ȃ� v2.0_1 �Ƃ���B
		# �Q�l: https://github.com/team-apm/apm-data/commit/240a170cc0b121f9b9d1edbe20f19f89146f03aa
	if ($InputPipePluginGithubApi.tag_name -eq "v2.0") {
		$apmJsonHash["packages"]["amate/InputPipePlugin"]["version"] = "v2.0_1"
	} else {
		$apmJsonHash["packages"]["amate/InputPipePlugin"]["version"] = $InputPipePluginGithubApi.tag_name
	}

	Write-Host "����"
	Write-Host -NoNewline "InputPipePlugin���_�E�����[�h���Ă��܂�..."

	# InputPipePlugin��zip�t�@�C�����_�E�����[�h (�ҋ@)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $InputPipePluginUrl" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "����"
	Write-Host -NoNewline "InputPipePlugin���C���X�g�[�����Ă��܂�..."

	# InputPipePlugin��zip�t�@�C����W�J (�ҋ@)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path InputPipePlugin_*.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# �J�����g�f�B���N�g����InputPipePlugin��zip�t�@�C����W�J�����f�B���N�g���ɕύX
	Set-Location "InputPipePlugin_*\InputPipePlugin"

	# AviUtl\readme, AviUtl\license ���� inputPipePlugin �f�B���N�g�����쐬 (�ҋ@)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\readme\inputPipePlugin`", `"${Path}\license\inputPipePlugin`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl\license\inputPipePlugin ���� LICENSE ���AAviUtl\readme\inputPipePlugin ���� Readme.md �� (�ҋ@) �A
	# AviUtl\plugins �f�B���N�g�����ɂ��̑��̃t�@�C�������ꂼ��ړ�
	Start-Process powershell -ArgumentList "-command Move-Item LICENSE `"${Path}\license\inputPipePlugin`" -Force; Move-Item Readme.md `"${Path}\readme\inputPipePlugin`" -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait
	Move-Item * "${Path}\plugins" -Force

	# �J�����g�f�B���N�g���� tmp �f�B���N�g���ɕύX
	Set-Location ..\..

	Write-Host "����"
	Write-Host -NoNewline "`r`nx264guiEx�̍ŐV�ŏ����擾���Ă��܂�..."

	# x264guiEx�̍ŐV�ł̃_�E�����[�hURL���擾
	$x264guiExGithubApi = GithubLatestRelease "rigaya/x264guiEx"
	$x264guiExUrl = $x264guiExGithubApi.assets.browser_download_url

	# $apmJsonHash �̃o�[�W��������GitHub����擾�����f�[�^�ōŐV�̂��̂ɍX�V
	$apmJsonHash["packages"]["rigaya/x264guiEx"]["version"] = $x264guiExGithubApi.tag_name

	Write-Host "����"
	Write-Host -NoNewline "x264guiEx���_�E�����[�h���Ă��܂�..."

	# x264guiEx��zip�t�@�C�����_�E�����[�h (�ҋ@)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $x264guiExUrl" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "����"
	Write-Host -NoNewline "x264guiEx���C���X�g�[�����Ă��܂�..."

	# AviUtl\plugins ���� x264guiEx_stg �f�B���N�g��������΍폜���� (�G���[�̖h�~)
	if (Test-Path "${Path}\plugins\x264guiEx_stg") {
		Remove-Item "${Path}\plugins\x264guiEx_stg" -Recurse
	}

	# x264guiEx��zip�t�@�C����W�J (�ҋ@)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path x264guiEx_*.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# �J�����g�f�B���N�g����x264guiEx��zip�t�@�C����W�J�����f�B���N�g���ɕύX
	Set-Location "x264guiEx_*\x264guiEx_*"

	# �J�����g�f�B���N�g����x264guiEx��zip�t�@�C����W�J�����f�B���N�g������ plugins �f�B���N�g���ɕύX
	Set-Location plugins

	# AviUtl\plugins ���Ɍ��݂̃f�B���N�g���̃t�@�C����S�Ĉړ�
	Move-Item * "${Path}\plugins" -Force

	# �J�����g�f�B���N�g����x264guiEx��zip�t�@�C����W�J�����f�B���N�g������ exe_files �f�B���N�g���ɕύX
	Set-Location ..\exe_files

	# AviUtl �f�B���N�g������ exe_files �f�B���N�g�����쐬 (�ҋ@)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\exe_files`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl\exe_files ���Ɍ��݂̃f�B���N�g���̃t�@�C����S�Ĉړ�
	Move-Item * "${Path}\exe_files" -Force

	# �J�����g�f�B���N�g����x264guiEx��zip�t�@�C����W�J�����f�B���N�g���ɕύX
	Set-Location ..

	# AviUtl\readme ���� x264guiEx �f�B���N�g�����쐬 (�ҋ@)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\readme\x264guiEx`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl\readme\x264guiEx ���� x264guiEx_readme.txt ���ړ�
	Move-Item x264guiEx_readme.txt "${Path}\readme\x264guiEx" -Force

	# �J�����g�f�B���N�g���� tmp �f�B���N�g���ɕύX
	Set-Location ..\..

	Write-Host "����"
	Write-Host -NoNewline "`r`nMFVideoReader�̍ŐV�ŏ����擾���Ă��܂�..."

	# MFVideoReader�̍ŐV�ł̃_�E�����[�hURL���擾
	$MFVideoReaderGithubApi = GithubLatestRelease "amate/MFVideoReader"
	$MFVideoReaderUrl = $MFVideoReaderGithubApi.assets.browser_download_url

	# $apmJsonHash �̃o�[�W��������GitHub����擾�����f�[�^�ōŐV�̂��̂ɍX�V
	$apmJsonHash["packages"]["amate/MFVideoReader"]["version"] = $MFVideoReaderGithubApi.tag_name

	Write-Host "����"
	Write-Host -NoNewline "MFVideoReader���_�E�����[�h���Ă��܂�..."

	# MFVideoReader��zip�t�@�C�����_�E�����[�h (�ҋ@)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $MFVideoReaderUrl" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "����"
	Write-Host -NoNewline "MFVideoReader���C���X�g�[�����Ă��܂�..."

	# MFVideoReader��zip�t�@�C����W�J (�ҋ@)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path MFVideoReader_*.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# �J�����g�f�B���N�g����MFVideoReader��zip�t�@�C����W�J�����f�B���N�g���ɕύX
	Set-Location "MFVideoReader_*\MFVideoReader"

	# AviUtl\readme, AviUtl\license ���� MFVideoReader �f�B���N�g�����쐬 (�ҋ@)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\readme\MFVideoReader`", `"${Path}\license\MFVideoReader`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl\license\MFVideoReader ���� LICENSE ���AAviUtl\readme\MFVideoReader ���� Readme.md �� (�ҋ@) �A
	# AviUtl\plugins �f�B���N�g�����ɂ��̑��̃t�@�C�������ꂼ��ړ�
	Start-Process powershell -ArgumentList "-command Move-Item LICENSE `"${Path}\license\MFVideoReader`" -Force; Move-Item Readme.md `"${Path}\readme\MFVideoReader`" -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait
	Move-Item * "${Path}\plugins" -Force

	# �J�����g�f�B���N�g���� tmp �f�B���N�g���ɕύX
	Set-Location ..\..

	Write-Host "����"
	Write-Host -NoNewline "`r`nWebP Susie Plug-in���_�E�����[�h���Ă��܂�..."

	# WebP Susie Plug-in��zip�t�@�C�����_�E�����[�h (�ҋ@)
	Start-Process -FilePath curl.exe -ArgumentList "-OL https://toroidj.github.io/plugin/iftwebp11.zip" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "����"
	Write-Host -NoNewline "WebP Susie Plug-in���C���X�g�[�����Ă��܂�..."

	# WebP Susie Plug-in��zip�t�@�C����W�J (�ҋ@)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path iftwebp11.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# �J�����g�f�B���N�g���� iftwebp11 �f�B���N�g���ɕύX
	Set-Location iftwebp11

	# AviUtl\readme ���� iftwebp �f�B���N�g�����쐬 (�ҋ@)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\readme\iftwebp`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl �f�B���N�g������ iftwebp.spi ���AAviUtl\readme\iftwebp ���� iftwebp.txt �����ꂼ��ړ�
	Move-Item iftwebp.spi $Path -Force
	Move-Item iftwebp.txt "${Path}\readme\iftwebp" -Force

	# �J�����g�f�B���N�g���� tmp �f�B���N�g���ɕύX
	Set-Location ..

	Write-Host "����"
	Write-Host -NoNewline "`r`nifheif�̍ŐV�ŏ����擾���Ă��܂�..."

	# ifheif�̍ŐV�ł̃_�E�����[�hURL���擾
	$ifheifGithubApi = GithubLatestRelease "Mr-Ojii/ifheif"
	$ifheifUrl = $ifheifGithubApi.assets.browser_download_url

	# $aisJsonHash �̃o�[�W��������GitHub����擾�����f�[�^�ōŐV�̂��̂ɍX�V
	$aisJsonHash["packages"]["Mr-Ojii/ifheif"]["version"] = $ifheifGithubApi.tag_name

	Write-Host "����"
	Write-Host -NoNewline "ifheif���_�E�����[�h���Ă��܂�..."

	# ifheif��zip�t�@�C�����_�E�����[�h (�ҋ@)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $ifheifUrl" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "����"
	Write-Host -NoNewline "ifheif���C���X�g�[�����Ă��܂�..."

	# AviUtl\license\ifheif ���� Licenses �f�B���N�g��������΍폜���� (�G���[�̖h�~)
	if (Test-Path "${Path}\license\ifheif\Licenses") {
		Remove-Item "${Path}\license\ifheif\Licenses" -Recurse
	}

	# ifheif��zip�t�@�C����W�J (�ҋ@)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path ifheif.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# �J�����g�f�B���N�g����ifheif��zip�t�@�C����W�J�����f�B���N�g���ɕύX
	Set-Location "ifheif"

	# AviUtl\readme, AviUtl\license ���� ifheif �f�B���N�g�����쐬 (�ҋ@)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\readme\ifheif`", `"${Path}\license\ifheif`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl �f�B���N�g������ ifheif.spi ���AAviUtl\license\ifheif ���� LICENSE �� Licenses �f�B���N�g�����A
	# AviUtl\readme\ifheif ���� Readme.md �����ꂼ��ړ�
	Move-Item ifheif.spi $Path -Force
	Move-Item "LICENS*" "${Path}\license\ifheif" -Force
	Move-Item Readme.md "${Path}\readme\ifheif" -Force

	# �J�����g�f�B���N�g���� tmp �f�B���N�g���ɕύX
	Set-Location ..

	Write-Host "����"
	Write-Host -NoNewline "`r`n�uAviUtl�X�N���v�g�ꎮ�v���_�E�����[�h���Ă��܂�..."

	# �uAviUtl�X�N���v�g�ꎮ�v��zip�t�@�C�����_�E�����[�h (�ҋ@)
	Start-Process -FilePath curl.exe -ArgumentList "-OL https://ss1.xrea.com/menkuri.s270.xrea.com/aviutl-installer-script/scripts/script_20160828.zip" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "����"
	Write-Host -NoNewline "�uAviUtl�X�N���v�g�ꎮ�v���C���X�g�[�����Ă��܂�..."

	# AviUtl\script ���� ���� �f�B���N�g��������΍폜���� (�G���[�̖h�~)
	if (Test-Path "${Path}\script\����") {
		Remove-Item "${Path}\script\����" -Recurse
	}

	# AviUtl\script ���� ANM_ssd �f�B���N�g��������΍폜���� (�G���[�̖h�~)
	if (Test-Path "${Path}\script\ANM_ssd") {
		Remove-Item "${Path}\script\ANM_ssd" -Recurse
	}

	# AviUtl\script ���� TA_ssd �f�B���N�g��������΍폜���� (�G���[�̖h�~)
	if (Test-Path "${Path}\script\TA_ssd") {
		Remove-Item "${Path}\script\TA_ssd" -Recurse
	}

	# �uAviUtl�X�N���v�g�ꎮ�v��zip�t�@�C����W�J (�ҋ@)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path script_20160828.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# �J�����g�f�B���N�g���� script_20160828\script_20160828 �f�B���N�g���ɕύX
	Set-Location script_20160828\script_20160828

	# AviUtl\script ���� ���� �f�B���N�g�����AAviUtl\readme ���� AviUtl�X�N���v�g�ꎮ �f�B���N�g�����쐬 (�ҋ@)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\script\����`", `"${Path}\readme\AviUtl�X�N���v�g�ꎮ`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl\script ���� ANM_ssd �� TA_ssd ���AAviUtl\readme\AviUtl�X�N���v�g�ꎮ ���� readme.txt �� �g����.txt �� (�ҋ@) �A
	# AviUtl\script\���� ���ɂ��̑��̃t�@�C�������ꂼ��ړ�
	Start-Process powershell -ArgumentList "-command Move-Item ANM_ssd `"${Path}\script`" -Force; Move-Item TA_ssd `"${Path}\script`" -Force; Move-Item *.txt `"${Path}\readme\AviUtl�X�N���v�g�ꎮ`" -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait
	Move-Item * "${Path}\script\����" -Force

	# �J�����g�f�B���N�g���� tmp �f�B���N�g���ɕύX
	Set-Location ..\..

	Write-Host "����"
	Write-Host -NoNewline "`r`n�u�l�Ő}�`�v���_�E�����[�h���Ă��܂�..."

	# �l�Ő}�`.obj ���_�E�����[�h (�ҋ@)
	Start-Process -FilePath curl.exe -ArgumentList "-OL `"https://ss1.xrea.com/menkuri.s270.xrea.com/aviutl-installer-script/scripts/�l�Ő}�`.obj`"" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "����"
	Write-Host -NoNewline "�u�l�Ő}�`�v���C���X�g�[�����Ă��܂�..."

	# AviUtl\script ���� Nagomiku �f�B���N�g�����쐬 (�ҋ@)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\script\Nagomiku`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl\script\Nagomiku ���� �l�Ő}�`.obj ���ړ�
	Move-Item "�l�Ő}�`.obj" "${Path}\script\Nagomiku" -Force

	Write-Host "����"
	Write-Host -NoNewline "`r`n�����X�N���v�g���_�E�����[�h���Ă��܂�..."

	# �����X�N���v�g��zip�t�@�C�����_�E�����[�h (�ҋ@)
	Start-Process -FilePath curl.exe -ArgumentList "-OL `"https://ss1.xrea.com/menkuri.s270.xrea.com/aviutl-installer-script/scripts/�����X�N���v�g.zip`"" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "����"
	Write-Host -NoNewline "�����X�N���v�g���C���X�g�[�����Ă��܂�..."

	# �����X�N���v�g��zip�t�@�C����W�J (�ҋ@)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path `"�����X�N���v�g.zip`" -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# �J�����g�f�B���N�g���� �����X�N���v�g �f�B���N�g���ɕύX
	Set-Location "�����X�N���v�g"

	# AviUtl\script ���� �����ڂ� �f�B���N�g�����AAviUtl\readme, AviUtl\license ���� �����X�N���v�g �f�B���N�g�����쐬 (�ҋ@)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\script\�����ڂ�`", `"${Path}\readme\�����X�N���v�g`", `"${Path}\license\�����X�N���v�g`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl\script\�����ڂ� ���� ����.obj ���AAviUtl\license\�����X�N���v�g ���� LICENSE.txt �� (�ҋ@) �A
	# AviUtl\readme\�����X�N���v�g ���ɂ��̑��̃t�@�C�������ꂼ��ړ�
	Start-Process powershell -ArgumentList "-command Move-Item `"����.obj`" `"${Path}\script\�����ڂ�`" -Force; Move-Item LICENSE.txt `"${Path}\license\�����X�N���v�g`" -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait
	Move-Item * "${Path}\readme\�����X�N���v�g" -Force

	# �J�����g�f�B���N�g���� tmp �f�B���N�g���ɕύX
	Set-Location ..

	Write-Host "����"


	# LuaJIT�̃C���X�g�[�� by Yu-yu0202 (20250109)
		# �s�������Ȃ��������ߍĎ��� by menndouyukkuri (20250110)

	Write-Host -NoNewline "`r`nLuaJIT�̍ŐV�ŏ����擾���Ă��܂�..."

	# LuaJIT�̍ŐV�ł̃_�E�����[�hURL���擾
	$luaJitGithubApi = GithubLatestRelease "Per-Terra/LuaJIT-Auto-Builds"
	$luaJitAllUrl = $luaJitGithubApi.assets.browser_download_url

	# �������钆����AviUtl�p�̂��̂̂ݎc��
	$luaJitUrl = $luaJitAllUrl | Where-Object {$_ -like "*LuaJIT_2.1_Win_x86.zip"}

	# $aisJsonHash �̃o�[�W��������GitHub����擾�����f�[�^�ōŐV�̂��̂ɍX�V
		# yyyy/mm/dd ������K�v�����邽�� tag_name �𕪊����ăr���h���̂ݎ��o���Ďg�p
	$luaJitTagNameSplitArray = ($luaJitGithubApi.tag_name) -split "-"
	$luaJitBuildDate = $luaJitTagNameSplitArray[1] + "/" + $luaJitTagNameSplitArray[2] + "/" + $luaJitTagNameSplitArray[3]
	$aisJsonHash["packages"]["Per-Terra/LuaJIT"]["version"] = $luaJitBuildDate

	Write-Host "����"
	Write-Host -NoNewline "LuaJIT���_�E�����[�h���Ă��܂�..."

	# LuaJIT��zip�t�@�C�����_�E�����[�h (�ҋ@)
	Start-Process -FilePath curl.exe -ArgumentList "-OL $luaJitUrl" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	Write-Host "����"
	Write-Host -NoNewline "LuaJIT���C���X�g�[�����Ă��܂�..."

	# ���� exedit_lua51.dll �����݂���ꍇ�͈ȉ��̏������X�L�b�v���� (�G���[�̖h�~)
	if (!(Test-Path "${Path}\exedit_lua51.dll")) {
		# AviUtl �f�B���N�g���Ɋ��ɂ��� lua51.dll (�g���ҏWPlugin�̂���) �����l�[�����ăo�b�N�A�b�v����
		Rename-Item "${Path}\lua51.dll" "exedit_lua51.dll" -Force
	}

	# AviUtl\readme\LuaJIT ���� doc �f�B���N�g��������΍폜���� (�G���[�̖h�~)
	if (Test-Path "${Path}\readme\LuaJIT\doc") {
		Remove-Item "${Path}\readme\LuaJIT\doc" -Recurse
	}

	# LuaJIT��zip�t�@�C����W�J (�ҋ@)
	Start-Process powershell -ArgumentList "-command Expand-Archive -Path `"LuaJIT_2.1_Win_x86.zip`" -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# �J�����g�f�B���N�g����LuaJIT��zip�t�@�C����W�J�����f�B���N�g���ɕύX
	Set-Location "LuaJIT_2.1_Win_x86"

	# AviUtl\readme, AviUtl\license ���� LuaJIT �f�B���N�g�����쐬 (�ҋ@)
	Start-Process powershell -ArgumentList "-command New-Item `"${Path}\readme\LuaJIT`", `"${Path}\license\LuaJIT`" -ItemType Directory -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

	# AviUtl �f�B���N�g������ lua51.dll ���AAviUtl\readme\LuaJIT ���� README �� doc ���AAviUtl\license\LuaJIT ����
	# COPYRIGHT �� About-This-Build.txt �����ꂼ��ړ�
	Move-Item "lua51.dll" $Path -Force
	Move-Item README "${Path}\readme\LuaJIT" -Force
	Move-Item doc "${Path}\readme\LuaJIT" -Force
	Move-Item COPYRIGHT "${Path}\license\LuaJIT" -Force
	Move-Item "About-This-Build.txt" "${Path}\license\LuaJIT" -Force

	# �J�����g�f�B���N�g���� tmp �f�B���N�g���ɕύX
	Set-Location ..

	Write-Host "����"


	# HW�G���R�[�f�B���O�̎g�p�ۂ��`�F�b�N���A�\�ł���Ώo�̓v���O�C�����C���X�g�[�� by Yu-yu0202 (20250107)

	Write-Host "`r`n�n�[�h�E�F�A�G���R�[�h (NVEnc / QSVEnc / VCEEnc) ���g�p�ł��邩�`�F�b�N���܂��B"
	Write-Host -NoNewline "�K�v�ȃt�@�C�����_�E�����[�h���Ă��܂� (����������ꍇ������܂�) "

	# apm.json �����p�Ƀ^�O����ۑ�����n�b�V���e�[�u�����쐬
	$hwEncodersTagName = @{
		"NVEnc"  = "xxx"
		"QSVEnc" = "xxx"
		"VCEEnc" = "xxx"
	}

	$hwEncoderRepos = @("rigaya/NVEnc", "rigaya/QSVEnc", "rigaya/VCEEnc")
	foreach ($hwRepo in $hwEncoderRepos) {
		# ���ƂŎg���̂Ń��|�W�g����������Ă���
		$repoName = ($hwRepo -split "/")[-1]

		# �ŐV�ł̃_�E�����[�hURL���擾
		$hwEncoderGithubApi = GithubLatestRelease $hwRepo
		$downloadAllUrl = $hwEncoderGithubApi.assets.browser_download_url

		# �������钆����AviUtl�p�̂��̂̂ݎc��
		$downloadUrl = $downloadAllUrl | Where-Object {$_ -like "*Aviutl*"}

		# apm.json �����p�� $hwEncodersTagName �Ƀ^�O����ۑ�
		$hwEncodersTagName.$repoName = $hwEncoderGithubApi.tag_name

		Write-Host -NoNewline "."

		# zip�t�@�C�����_�E�����[�h (�ҋ@)
		Start-Process -FilePath curl.exe -ArgumentList "-OL $downloadUrl" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

		Write-Host -NoNewline "."

		# zip�t�@�C����W�J (�ҋ@)
		Start-Process powershell -ArgumentList "-command Expand-Archive -Path Aviutl_${repoName}_*.zip -Force" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait
	}

	Write-Host " ����"
	Write-Host "�G���R�[�_�[�̃`�F�b�N�A����юg�p�\�ȏo�̓v���O�C���̃C���X�g�[�����s���܂��B"

	$hwEncoders = [ordered]@{
		"NVEnc"  = "NVEncC.exe"
		"QSVEnc" = "QSVEncC.exe"
		"VCEEnc" = "VCEEncC.exe"
	}

	# �掿�̂悢NVEnc���珇��QSVEnc�AVCEEnc�ƃ`�F�b�N���Ă����A�ŏ��Ɏg�p�\�Ȃ��̂��m�F�������_�ł���𓱓�����foreach�𗣒E
	foreach ($hwEncoder in $hwEncoders.GetEnumerator()) {
		# �G���R�[�_�[�̎��s�t�@�C���̃p�X���i�[
		Set-Location "Aviutl_$($hwEncoder.Key)_*"
		$extdir = ${TempPath}
		$encoderPath = Join-Path -Path $extdir -ChildPath "exe_files\$($hwEncoder.Key)C\x86\$($hwEncoder.Value)"
		Set-Location ..

		# �G���R�[�_�[�̎��s�t�@�C���̗L�����m�F
		if (Test-Path $encoderPath) {
			# �n�[�h�E�F�A�G���R�[�h�ł��邩�`�F�b�N
			$process = Start-Process -FilePath $encoderPath -ArgumentList "--check-hw" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait -PassThru

			# ExitCode �� 0 = �g�p�\�ȏꍇ�̓C���X�g�[��
			if ($process.ExitCode -eq 0) {
				# AviUtl\exe_files ���� $($hwEncoder.Key)C �f�B���N�g��������΍폜���� (�G���[�̖h�~)
				if (Test-Path "${Path}\exe_files\$($hwEncoder.Key)C") {
					Remove-Item "${Path}\exe_files\$($hwEncoder.Key)C" -Recurse
				}

				# AviUtl\plugins ���� $($hwEncoder.Key)_stg �f�B���N�g��������΍폜���� (�G���[�̖h�~)
				if (Test-Path "${Path}\plugins\$($hwEncoder.Key)_stg") {
					Remove-Item "${Path}\plugins\$($hwEncoder.Key)_stg" -Recurse
				}

				Write-Host -NoNewline "$($hwEncoder.Key)���g�p�\�ł��B$($hwEncoder.Key)���C���X�g�[�����Ă��܂�..."

				# readme �f�B���N�g�����쐬
				New-Item -ItemType Directory -Path "${Path}\readme\$($hwEncoder.Key)" -Force | Out-Null

				# �W�J��̂��ꂼ��̃t�@�C�����ړ�
				Move-Item -Path "$extdir\exe_files\*" -Destination "${Path}\exe_files" -Force
				Move-Item -Path "$extdir\plugins\*" -Destination "${Path}\plugins" -Force
				Move-Item -Path "$extdir\*.bat" -Destination $Path -Force
				Move-Item -Path "$extdir\*_readme.txt" -Destination "${Path}\readme\$($hwEncoder.Key)" -Force

				# apm.json �� rigaya/$($hwEncoder.Key) ���o�^����Ă��Ȃ��ꍇ�̓L�[���쐬����id��o�^
				if (!($apmJsonHash.packages.Contains("rigaya/$($hwEncoder.Key)"))) {
					$apmJsonHash["packages"]["rigaya/$($hwEncoder.Key)"] = [ordered]@{}
					$apmJsonHash["packages"]["rigaya/$($hwEncoder.Key)"]["id"] = "rigaya/$($hwEncoder.Key)"
				}

				# apm.json �� rigaya/$($hwEncoder.Key) �̃o�[�W�������X�V
				$apmJsonHash["packages"]["rigaya/$($hwEncoder.Key)"]["version"] = $hwEncodersTagName.$($hwEncoder.Key)

				Write-Host "����"

				# �ꉞ�A�o�̓v���O�C�����������Ȃ��悤break��foreach�𔲂���
				break

			# �Ō��VCEEnc���g�p�s�������ꍇ�A�n�[�h�E�F�A�G���R�[�h���g�p�ł��Ȃ��|�̃��b�Z�[�W��\��
			} elseif ($($hwEncoder.Key) -eq "VCEEnc") {
				Write-Host "���̊��ł̓n�[�h�E�F�A�G���R�[�h�͎g�p�ł��܂���B"
			}

		# �G���R�[�_�[�̎��s�t�@�C�����m�F�ł��Ȃ��ꍇ�A�G���[���b�Z�[�W��\������
		} else {
			Write-Host "���������G���[: �G���R�[�_�[�̃`�F�b�N�Ɏ��s���܂����B`r`n�G���[�̌����@: $($hwEncoder.Key)�̎��s�t�@�C�����m�F�ł��܂���B"
		}
	}


	Write-Host -NoNewline "`r`nVisual C++ �ĔЕz�\�p�b�P�[�W���m�F���Ă��܂�..."

	# ���W�X�g������f�X�N�g�b�v�A�v���̈ꗗ���擾����
	$installedApps = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
									  "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
									  "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
	Where-Object { $_.DisplayName -and $_.UninstallString -and -not $_.SystemComponent -and ($_.ReleaseType -notin "Update","Hotfix") -and -not $_.ParentKeyName } |
	Select-Object DisplayName

	# Microsoft Visual C++ 2015-20xx Redistributable (x86) ���C���X�g�[������Ă��邩�m�F����
		# Visual C++ �ĔЕz�\�p�b�P�[�W��2020��2021�͂Ȃ��̂ŁA20[2-9][0-9] �Ƃ��Ă�����2022�ȍ~���w��ł���
	$Vc2015App = $installedApps.DisplayName -match "Microsoft Visual C\+\+ 2015-20[2-9][0-9] Redistributable \(x86\)"

	# Microsoft Visual C++ 2008 Redistributable - x86 ���C���X�g�[������Ă��邩�m�F����
	$Vc2008App = $installedApps.DisplayName -match "Microsoft Visual C\+\+ 2008 Redistributable - x86"

	Write-Host "����"

	# $Vc2015App �� $Vc2008App �̌��ʂŏ����𕪊򂷂�

	# �����C���X�g�[������Ă���ꍇ�A���b�Z�[�W�����\��
	if ($Vc2015App -and $Vc2008App) {
		Write-Host "Microsoft Visual C++ 2015-20xx Redistributable (x86) �̓C���X�g�[���ς݂ł��B"
		Write-Host "Microsoft Visual C++ 2008 Redistributable - x86 �̓C���X�g�[���ς݂ł��B"

	# 2008�̂݃C���X�g�[������Ă���ꍇ�A2015�������C���X�g�[��
	} elseif ($Vc2008App) {
		Write-Host "Microsoft Visual C++ 2015-20xx Redistributable (x86) �̓C���X�g�[������Ă��܂���B"
		Write-Host "���̃p�b�P�[�W�� patch.aul �ȂǏd�v�ȃv���O�C���̓���ɕK�v�ł��B�C���X�g�[���ɂ͊Ǘ��Ҍ������K�v�ł��B`r`n"
		Write-Host -NoNewline "Microsoft Visual C++ 2015-20xx Redistributable (x86) �̃C���X�g�[���[���_�E�����[�h���Ă��܂�..."

		# Visual C++ 2015-20xx Redistributable (x86) �̃C���X�g�[���[���_�E�����[�h (�ҋ@)
		Start-Process -FilePath curl.exe -ArgumentList "-OL https://aka.ms/vs/17/release/vc_redist.x86.exe" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

		Write-Host "����"
		Write-Host "Microsoft Visual C++ 2015-20xx Redistributable (x86) �̃C���X�g�[�����s���܂��B"
		Write-Host "�f�o�C�X�ւ̕ύX���K�v�ɂȂ�܂��B���[�U�[�A�J�E���g����̃|�b�v�A�b�v���o���� [�͂�] �������ċ����Ă��������B`r`n"

		# Visual C++ 2015-20xx Redistributable (x86) �̃C���X�g�[���[�����s (�ҋ@)
			# �����C���X�g�[���I�v�V������ǉ� by Atolycs (20250106)
		Start-Process -FilePath vc_redist.x86.exe -ArgumentList "/install /passive" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

		Write-Host "�C���X�g�[���[���I�����܂����B"
		Write-Host "`r`nMicrosoft Visual C++ 2008 Redistributable - x86 �̓C���X�g�[���ς݂ł��B"

	# 2015�̂݃C���X�g�[������Ă���ꍇ�A2008�̃C���X�g�[�������[�U�[�ɑI��������
	} elseif ($Vc2015App) {
		Write-Host "Microsoft Visual C++ 2008 Redistributable - x86 �̓C���X�g�[������Ă��܂���B"

		# �I����������

		$choiceTitle = "Microsoft Visual C++ 2008 Redistributable - x86 ���C���X�g�[�����܂����H"
		$choiceMessage = "���̃p�b�P�[�W�͈ꕔ�̃X�N���v�g�̓���ɕK�v�ł��B�C���X�g�[���ɂ͊Ǘ��Ҍ������K�v�ł��B"

		$tChoiceDescription = "System.Management.Automation.Host.ChoiceDescription"
		$choiceOptions = @(
			New-Object $tChoiceDescription ("�͂�(&Y)",  "�C���X�g�[�������s���܂��B")
			New-Object $tChoiceDescription ("������(&N)", "�C���X�g�[���������A�X�L�b�v���Ď��̏����ɐi�݂܂��B")
		)

		$result = $host.ui.PromptForChoice($choiceTitle, $choiceMessage, $choiceOptions, 0)
		switch ($result) {
			0 {
				Write-Host -NoNewline "`r`nMicrosoft Visual C++ 2008 Redistributable - x86 �̃C���X�g�[���[���_�E�����[�h���Ă��܂�..."

				# Visual C++ 2008 Redistributable - x86 �̃C���X�g�[���[���_�E�����[�h (�ҋ@)
				Start-Process -FilePath curl.exe -ArgumentList "-OL https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

				Write-Host "����"
				Write-Host "Microsoft Visual C++ 2008 Redistributable - x86 �̃C���X�g�[�����s���܂��B"
				Write-Host "�f�o�C�X�ւ̕ύX���K�v�ɂȂ�܂��B���[�U�[�A�J�E���g����̃|�b�v�A�b�v���o���� [�͂�] �������ċ����Ă��������B`r`n"

				# Visual C++ 2008 Redistributable - x86 �̃C���X�g�[���[�����s (�ҋ@)
					# �����C���X�g�[���I�v�V������ǉ� by Atolycs (20250106)
				Start-Process -FilePath vcredist_x86.exe -ArgumentList "/qb" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

				Write-Host "�C���X�g�[���[���I�����܂����B"
				break
			}
			1 {
				Write-Host "`r`nMicrosoft Visual C++ 2008 Redistributable - x86 �̃C���X�g�[�����X�L�b�v���܂����B"
				break
			}
		}

		# �I�������܂�

	# �����C���X�g�[������Ă��Ȃ��ꍇ�A2008�̃C���X�g�[�������[�U�[�ɑI�������A2008���C���X�g�[������ꍇ�͗����C���X�g�[�����A
	# 2008���C���X�g�[�����Ȃ��ꍇ��2015�̂ݎ����C���X�g�[��
	} else  {
		Write-Host "Microsoft Visual C++ 2015-20xx Redistributable (x86) �̓C���X�g�[������Ă��܂���B"
		Write-Host "���̃p�b�P�[�W�� patch.aul �ȂǏd�v�ȃv���O�C���̓���ɕK�v�ł��B�C���X�g�[���ɂ͊Ǘ��Ҍ������K�v�ł��B`r`n"
		Write-Host -NoNewline "Microsoft Visual C++ 2015-20xx Redistributable (x86) �̃C���X�g�[���[���_�E�����[�h���Ă��܂�..."

		# Visual C++ 2015-20xx Redistributable (x86) �̃C���X�g�[���[���_�E�����[�h (�ҋ@)
		Start-Process -FilePath curl.exe -ArgumentList "-OL https://aka.ms/vs/17/release/vc_redist.x86.exe" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

		Write-Host "����"
		Write-Host "`r`nMicrosoft Visual C++ 2008 Redistributable - x86 �̓C���X�g�[������Ă��܂���B"

		# �I����������

		$choiceTitle = "Microsoft Visual C++ 2008 Redistributable - x86 ���C���X�g�[�����܂����H"
		$choiceMessage = "���̃p�b�P�[�W�͈ꕔ�̃X�N���v�g�̓���ɕK�v�ł��B�C���X�g�[���ɂ͊Ǘ��Ҍ������K�v�ł��B"

		$tChoiceDescription = "System.Management.Automation.Host.ChoiceDescription"
		$choiceOptions = @(
			New-Object $tChoiceDescription ("�͂�(&Y)",  "�C���X�g�[�������s���܂��B")
			New-Object $tChoiceDescription ("������(&N)", "�C���X�g�[���������A�X�L�b�v���Ď��̏����ɐi�݂܂��B")
		)

		$result = $host.ui.PromptForChoice($choiceTitle, $choiceMessage, $choiceOptions, 0)
		switch ($result) {
			0 {
				Write-Host -NoNewline "`r`nMicrosoft Visual C++ 2008 Redistributable - x86 �̃C���X�g�[���[���_�E�����[�h���Ă��܂�..."

				# Visual C++ 2008 Redistributable - x86 �̃C���X�g�[���[���_�E�����[�h (�ҋ@)
				Start-Process -FilePath curl.exe -ArgumentList "-OL https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

				Write-Host "����"
				Write-Host "`r`nMicrosoft Visual C++ 2015-20xx Redistributable (x86) ��`r`nMicrosoft Visual C++ 2008 Redistributable - x86 �̃C���X�g�[�����s���܂��B"
				Write-Host "�f�o�C�X�ւ̕ύX���K�v�ɂȂ�܂��B���[�U�[�A�J�E���g����̃|�b�v�A�b�v���o���� [�͂�] �������ċ����Ă��������B`r`n"

				# VCruntimeInstall2015and2008.cmd ���Ǘ��Ҍ����Ŏ��s (�ҋ@)
				Start-Process -FilePath cmd.exe -ArgumentList "/C cd $scriptFilesDirectoryPath & call VCruntimeInstall2015and2008.cmd $scriptFileRoot & exit" -Verb RunAs -WindowStyle Hidden -Wait

				Write-Host "�C���X�g�[���[���I�����܂����B"
				break
			}
			1 {
				Write-Host "Microsoft Visual C++ 2015-20xx Redistributable (x86) �̃C���X�g�[�����s���܂��B"
				Write-Host "�f�o�C�X�ւ̕ύX���K�v�ɂȂ�܂��B���[�U�[�A�J�E���g����̃|�b�v�A�b�v���o���� [�͂�] �������ċ����Ă��������B`r`n"

				# Visual C++ 2015-20xx Redistributable (x86) �̃C���X�g�[���[�����s (�ҋ@)
					# �����C���X�g�[���I�v�V������ǉ� by Atolycs (20250106)
				Start-Process -FilePath vc_redist.x86.exe -ArgumentList "/install /passive" -WorkingDirectory ${TempPath} -WindowStyle Hidden -Wait

				Write-Host "�C���X�g�[���[���I�����܂����B"
				Write-Host "`r`nMicrosoft Visual C++ 2008 Redistributable - x86 �̃C���X�g�[�����X�L�b�v���܂����B"
				break
			}
		}

		# �I�������܂�
	}

	Write-Host -NoNewline "`r`n�ݒ�t�@�C�����R�s�[���Ă��܂�..."

	# AviUtl\plugins ���� lsmash.ini �� MFVideoReaderConfig.ini ���R�s�[
	Copy-Item "${settingsDirectoryPath}\lsmash.ini", "${settingsDirectoryPath}\MFVideoReaderConfig.ini" "${Path}\plugins"

	# AviUtl �f�B���N�g������ aviutl.ini, exedit.ini �� �f�t�H���g.cfg ���R�s�[
	Copy-Item "${settingsDirectoryPath}\aviutl.ini", "${settingsDirectoryPath}\exedit.ini", "${settingsDirectoryPath}\�f�t�H���g.cfg" $Path

	# AviUtl �f�B���N�g�����̑S�t�@�C���̃u���b�N������ (�Z�L�����e�B�@�\�̕s�v�Ȕ������\�Ȕ͈͂Ŗh������)
	Get-ChildItem -Path $Path -Recurse | Unblock-File

	Write-Host "����"
	Write-Host -NoNewline "`r`napm.json ���쐬���Ă��܂�..."

	# $apmJsonHash ��JSON�`���ɕϊ����Aapm.json �Ƃ��ďo�͂���
	ConvertTo-Json $apmJsonHash -Depth 8 -Compress | ForEach-Object { $_ + "`n" } | ForEach-Object { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Encoding Byte -Path "${Path}\apm.json"

	Write-Host "����"
	Write-Host -NoNewline "`r`nais.json ���쐬���Ă��܂�..."

	# $aisJsonHash ��JSON�`���ɕϊ����Aais.json �Ƃ��ďo�͂���
	ConvertTo-Json $aisJsonHash -Depth 8 -Compress | ForEach-Object { $_ + "`n" } | ForEach-Object { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Encoding Byte -Path "${Path}\ais.json"

	Write-Host "����"
	Write-Host -NoNewline "`r`n�f�X�N�g�b�v�ɃV���[�g�J�b�g�t�@�C�����쐬���Ă��܂�..."

	# WSH��p���ăf�X�N�g�b�v��AviUtl�̃V���[�g�J�b�g���쐬����
	$DesktopShortcutFolder = [Environment]::GetFolderPath("Desktop")
	$DesktopShortcutFile = Join-Path -Path $DesktopShortcutFolder -ChildPath "AviUtl.lnk"
	$DesktopWshShell = New-Object -comObject WScript.Shell
	$DesktopShortcut = $DesktopWshShell.CreateShortcut($DesktopShortcutFile)
	$DesktopShortcut.TargetPath = "${Path}\aviutl.exe"
	$DesktopShortcut.IconLocation = "${Path}\aviutl.exe,0"
	$DesktopShortcut.WorkingDirectory = $Path
	$DesktopShortcut.Save()

	Write-Host "����"
	Write-Host -NoNewline "�X�^�[�g���j���[�ɃV���[�g�J�b�g�t�@�C�����쐬���Ă��܂�..."

	# WSH��p���ăX�^�[�g���j���[��AviUtl�̃V���[�g�J�b�g���쐬����
	$ProgramsShortcutFolder = [Environment]::GetFolderPath("Programs")
	$ProgramsShortcutFile = Join-Path -Path $ProgramsShortcutFolder -ChildPath "AviUtl.lnk"
	$ProgramsWshShell = New-Object -comObject WScript.Shell
	$ProgramsShortcut = $ProgramsWshShell.CreateShortcut($ProgramsShortcutFile)
	$ProgramsShortcut.TargetPath = "${Path}\aviutl.exe"
	$ProgramsShortcut.IconLocation = "${Path}\aviutl.exe,0"
	$ProgramsShortcut.WorkingDirectory = $Path
	$ProgramsShortcut.Save()

	Write-Host "����"
	Write-Host -NoNewline "`r`n�C���X�g�[���Ɏg�p�����s�v�ȃt�@�C�����폜���Ă��܂�..."

	# �J�����g�f�B���N�g�����X�N���v�g�t�@�C���̂���f�B���N�g���ɕύX
	Set-Location ${Path}

	# tmp �f�B���N�g�����폜 (By 20250307 Atolycs)
  # UserProfile�ɍ쐬�����ꎞ�t�H���_���폜
	Remove-Item ${TempPath} -Recurse

	Write-Host "����"

	if (Test-Path "script_files\�K�{�v���O�C���E�X�N���v�g���X�V����.cmd") {
		# �K�{�v���O�C���E�X�N���v�g���X�V����.cmd ���J�����g�f�B���N�g���Ɉړ�
		Move-Item "script_files\�K�{�v���O�C���E�X�N���v�g���X�V����.cmd" . -Force

		# aviutl-installer.cmd �̏ꏊ���m�F
		if (Test-Path "newver\aviutl-installer_${VerNum}\aviutl-installer.cmd") {
			# aviutl-installer.cmd �� script_files �f�B���N�g���Ɉړ�
			Move-Item "newver\aviutl-installer_${VerNum}\aviutl-installer.cmd" script_files -Force

			# newver �f�B���N�g�����폜
			Remove-Item newver -Recurse
		} else {
			# aviutl-installer.cmd �� script_files �f�B���N�g���Ɉړ�
			Move-Item aviutl-installer.cmd script_files -Force
		}
	} else {
		# aviutl-installer.cmd �̏ꏊ���m�F
		if (Test-Path "newver\aviutl-installer_${VerNum}\aviutl-installer.cmd") {
			# aviutl-installer.cmd ���J�����g�f�B���N�g���Ɉړ�
			Move-Item "newver\aviutl-installer_${VerNum}\aviutl-installer.cmd" . -Force

			# newver �f�B���N�g�����폜
			Remove-Item newver -Recurse
		}
	}

	# ���[�U�[�̑����҂��ďI��
	Write-Host -NoNewline "`r`n`r`n`r`n�C���X�g�[�����������܂����I`r`n`r`n`r`nreadme �t�H���_���J����"
	Pause

	# �I������ readme �f�B���N�g����\��
	Invoke-Item "${Path}\readme"
}
