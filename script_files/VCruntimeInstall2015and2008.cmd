@powershell -NoProfile -ExecutionPolicy Unrestricted "$s=[scriptblock]::create((gc \"%~f0\"|?{$_.readcount -gt 1})-join\"`n\");&$s" %*&goto:eof

# Visual C++ 2015-20xx Redistributable (x86) と Visual C++ 2008 Redistributable - x86 の
# インストーラーを順番に実行していくだけのスクリプトです
# 他のスクリプトから管理者権限で呼び出されることが想定されています

<#!
 #  MIT License
 #
 #  Copyright (c) 2025 menndouyukkuri, atolycs
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

# カレントディレクトリのパスを $scriptFileRoot に保存 (起動方法のせいで $PSScriptRoot が使用できないため)
$scriptFileRoot = (Get-Location).Path

# tmp ディレクトリの場所を確認してカレントディレクトリとする
if (Test-Path ..\tmp) {
	Set-Location ..\tmp
} else {
	Set-Location tmp
}

# Visual C++ 2015-20xx Redistributable (x86) のインストーラーを実行 (待機)
	# 自動インストールオプションを追加 by Atolycs (20250106)
Start-Process -FilePath vc_redist.x86.exe -ArgumentList "/install /passive" -Wait

# Visual C++ 2008 Redistributable - x86 のインストーラーを実行 (待機)
	# 自動インストールオプションを追加 by Atolycs (20250106)
Start-Process -FilePath vcredist_x86.exe -ArgumentList "/qb" -Wait
