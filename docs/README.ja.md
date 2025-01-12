The English version of the README is [here](../README.md).

## AviUtl Installer Scriptについて
AviUtl本体とAviUtlで動画編集をするなら必須と言っていいレベルのいくつかのプラグインを導入して初期設定する、初心者には複雑で難解な作業を1つのファイルを実行するだけで済ませようという目的で作られているスクリプトの詰め合わせです。

多くの環境で実行しやすくするために .cmd (バッチファイル) となっていますが、中身はほとんど Windows PowerShell (5.x) のスクリプトです。

### 動作環境
Windows 10 April 2018 Update (バージョン 1803) 以降\
(つまり、2025年現在サポートされている全ての家庭用Windowsで動作します)

### 使用方法
[releases/latest](https://github.com/menndouyukkuri/aviutl-installer-script/releases/latest) の  Assets から 
aviutl-installer_X.X.X.zip をダウンロードし、展開してください。

あとは aviutl-installer.cmd をダブルクリックするだけで、AviUtlと必須プラグイン (具体的に何が導入されるかは [インストールされるもの](https://github.com/menndouyukkuri/aviutl-installer-script/wiki/AviUtl-Installer-Script%E3%81%AB%E3%82%88%E3%81%A3%E3%81%A6%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB%E3%81%95%E3%82%8C%E3%82%8B%E3%82%82%E3%81%AE) に記載があります) のインストールが始まります。

もし以下のような画面が出てきた場合は、詳細情報 をクリックして

![ss001 - NoTitle](https://github.com/user-attachments/assets/0ce06df2-acce-4782-9d90-5aa4e9ca7d91)

出てきた [実行] をクリックすればスクリプトを実行することができます。

![ss002 - NoTitle](https://github.com/user-attachments/assets/129cd65b-8c40-4b34-bfd3-4e96ca36e39a)

動作中の様子:
![ss001 - AviUtl Installer Script (Version 1 0 11_2025-01-12)](https://github.com/user-attachments/assets/a92f4681-1a93-4ed0-850b-8faba6b4bfbb)

YouTubeの紹介動画:
[![紹介動画](https://github.com/user-attachments/assets/c0dbb594-0c99-4ac0-96e1-fc51f924ba78)](https://youtu.be/fJYp_nV-yrg)

### ライセンス
[MIT License](../LICENSE)です。

大雑把に言えば
* このライセンスがついたソフトは誰でも無償で無制限、どんな用途にでも使えます。
* 改変の有無にかかわらず、再配布する時は著作権表示とMIT Licenseをソフトウェアの全ての実質的な部分に含まれる必要があります。
* 提供者側は一切いかなる責任も負いません。利用は自己責任です。

といった感じのライセンスです。\
この説明は法的に正しい文章ではないので、これ大丈夫かな？と思ったら[MIT Licenseの本文](../LICENSE)を読んでください。

### 不具合を見つけた・こんな機能が欲しい
[Issues](https://github.com/menndouyukkuri/aviutl-installer-script/issues)に書き込んでください。

ただし、**書き込んだからといって必ずすぐにどうにかなるわけではありません**し、**開発者も同じ人間であり礼儀を払う必要がある**ということを覚えておいてください。\
あまりに攻撃的なIssueは内容を確認せずクローズする方針なので、解決したいという気持ちがあるなら丁寧に書いてください。
