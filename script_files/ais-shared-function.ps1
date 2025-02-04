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
	# try-catch で Invoke-RestMethod のエラーを捉えられるようにする
	$ErrorActionPreference = "Stop"

	try {
		# GitHubのAPIから最新版リリースの情報を取得する
		$api = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest"
	} catch {
		# $Error[0] が JSON 形式なので PSObject に変換する
		$ErrorJsonObject = ConvertFrom-Json $Error[0]

		# エラー表示の共通部分を表示
		Write-Host "`r`n`r`nエラー: GitHub APIからのデータの取得に失敗しました。"

		# API rate limit とそれ以外に分ける
		if ($ErrorJsonObject.message.Contains("API rate limit")){
			# API rate limit のエラーメッセージからIPアドレスを取り出す
			$ApiRateLimitMessageIpAddress = ((($ErrorJsonObject.message) -split " ")[5]).Trim(".")

			# API rate limit のエラーメッセージを日本語に直したものを表示
			Write-Host "内容　: $ApiRateLimitMessageIpAddress に対するAPIレート制限を超えました (しかし良いニュースがあります: 認証されたリクエストにはより高いレート制限が適用されます。詳細についてはドキュメントをご覧ください) 。"
			Write-Host "　　　  Ctrl キーを押しながらクリックするとリンク先が表示できます。`r`n　　　  https://docs.github.com/rest/using-the-rest-api/rate-limits-for-the-rest-api`r`n"

			# ユーザーに向けて対処法を表示
			Write-Host "対処法: GitHub APIでは同一IPからのアクセスが1時間あたり60回までに制限されています。`r`n　　　  しばらく時間を空けて再度実行すれば、問題なく実行できます。`r`n"

		} else {
			# エラーメッセージの表示
			Write-Host "内容　: $($ErrorJsonObject.message)"

			# ドキュメントのURLがある場合、それも表示する
			if ($ErrorJsonObject.PSObject.Properties["documentation_url"]) {
				Write-Host "　　　  詳細は下記のドキュメントをご覧ください。Ctrl キーを押しながらクリックするとリンク先が表示できます。`r`n　　　  $($ErrorJsonObject.documentation_url)"
			}

			Write-Host ""
		}

		# ユーザーの反応を待って終了
		Pause
		exit 1
	}

	# 最新版リリースの情報を返す
	return($api)
}
