<#!
 #  MIT License
 #
 #  Copyright (c) 2025 menndouyukkuri
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

# GitHubリポジトリの最新版リリースの情報を取得する
function GithubLatestRelease ($repo) {
	# GitHubのAPIから最新版リリースの情報を取得する
	$api = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest"

	if ($api -eq $null) {
		# null の場合、メッセージを表示して終了
		Write-Host "`r`n`r`nエラー: GitHub APIからのデータの取得に失敗しました。`r`n`r`nGitHub APIでは同一IPからのアクセスが1時間あたり60回までに制限されています。しばらく時間を空けて再度お試しください。`r`nそれでも失敗する場合は、スクリプトにバグがあるか、GitHubに何らかの障害が発生している可能性があります。`r`n`r`n"
		Pause
		exit
	} else {
		# 最新版リリースの情報を返す
		return($api)
	}
}
