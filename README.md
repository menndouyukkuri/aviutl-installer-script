## AviUtl Installer Scriptについて
AviUtl本体とAviUtlで動画編集をするなら必須と言っていいレベルのいくつかのプラグインを導入して初期設定する、初心者には複雑で難解な作業を1つのファイルを実行するだけで済ませようという目的で作られているスクリプトの詰め合わせです。

多くの環境で実行しやすくするために .cmd (バッチファイル) となっていますが、中身はほとんどPowerShellのスクリプトです。

### 動作環境
Windows 10 April 2018 Update (バージョン 1803) 以降\
(つまり、2025年現在サポートされている全ての家庭用Windowsで動作します)

### 使用方法
[releases/latest](https://github.com/menndouyukkuri/aviutl-installer-script/releases/latest) の  Assets から 
aviutl-installer_X.X.X.zip をダウンロードし、展開してください。

あとは aviutl-installer.cmd をダブルクリックするだけで、AviUtlと必須プラグイン (具体的に何が導入されるかは [releases/latest](https://github.com/menndouyukkuri/aviutl-installer-script/releases/latest) に記載があります) のインストールが始まります。

もし以下のような画面が出てきた場合は、詳細情報 をクリックして

![ss001 - NoTitle](https://github.com/user-attachments/assets/0ce06df2-acce-4782-9d90-5aa4e9ca7d91)

出てきた [実行] をクリックすればスクリプトを実行することができます。

![ss002 - NoTitle](https://github.com/user-attachments/assets/129cd65b-8c40-4b34-bfd3-4e96ca36e39a)

動作中の様子:
![ss001 - C：￥WINDOWS￥system32￥cmd exe](https://github.com/user-attachments/assets/0028f0cf-a45a-4ee3-864c-697360e5145c)

YouTubeの紹介動画:
[![紹介動画](https://github.com/user-attachments/assets/c0dbb594-0c99-4ac0-96e1-fc51f924ba78)](https://youtu.be/fJYp_nV-yrg)

### ライセンス
[MIT License](https://github.com/menndouyukkuri/aviutl-installer-script/blob/main/LICENSE)です。

大雑把に言えば
* このライセンスがついたソフトは誰でも無償で無制限、どんな用途にでも使えます。
* 改変の有無にかかわらず、再配布する時は著作権表示とMIT Licenseをソフトウェアの全ての実質的な部分に含まれる必要があります。
* 提供者側は一切いかなる責任も負いません。利用は自己責任です。

といった感じのライセンスです。\
この説明は法的に正しい文章ではないので、これ大丈夫かな？と思ったら[MIT Licenseの本文](https://github.com/menndouyukkuri/aviutl-installer-script/blob/main/LICENSE)を読んでください。

### 不具合を見つけた・こんな機能が欲しい
[Issues](https://github.com/menndouyukkuri/aviutl-installer-script/issues)に書き込んでください。

ただし、**書き込んだからといって必ずすぐにどうにかなるわけではありません**し、**開発者も同じ人間であり礼儀を払う必要がある**ということを覚えておいてください。\
あまりに攻撃的なIssueは内容を確認せずクローズする方針なので、解決したいという気持ちがあるなら丁寧に書いてください。

## About AviUtl Installer Script
This is a collection of scripts created with the purpose of simplifying the complex and difficult task for beginners of setting up several essential plugins for AviUtl and the AviUtl main body for video editing, so that it can be done by executing just one file.

To make it easier to run in many environments, it is in .cmd (batchfile) format, but the contents are mostly PowerShell scripts.

### Operating Environment
Windows 10 April 2018 Update (version 1803) or later\
(In other words, it works on all supported consumer Windows as of 2025)

### How to Use
Download aviutl-installer_X.X.X.zip from the Assets of [releases/latest](https://github.com/menndouyukkuri/aviutl-installer-script/releases/latest) and extract it.

After that, simply double-click on aviutl-installer.cmd to start the installation of AviUtl and the required plugins (specific details on what will be installed can be found in [releases/latest](https://github.com/menndouyukkuri/aviutl-installer-script/releases/latest)).

If a screen saying "Windows protected your PC" appears, you can click More info and then click [Run anyway] to execute the script.

State of operation:
![ss001 - C：￥WINDOWS￥system32￥cmd exe](https://github.com/user-attachments/assets/0028f0cf-a45a-4ee3-864c-697360e5145c)

YouTube introduction video (Japanese language only):
[![紹介動画](https://github.com/user-attachments/assets/c0dbb594-0c99-4ac0-96e1-fc51f924ba78)](https://youtu.be/fJYp_nV-yrg)

### License
The license for this software is the [MIT License](https://github.com/menndouyukkuri/aviutl-installer-script/blob/main/LICENSE).

In general terms:
* Software with this license can be used by anyone for free and without limitation, for any purpose.
* Regardless of whether modifications are made, when redistributing, the copyright notice and the MIT License must be included in all substantial parts of the software.
* The provider assumes no responsibility whatsoever. Use is at your own risk.

This is the general idea of the license.\
This explanation is not a legally accurate statement, so if you have any doubts, please read the [full text of the MIT License](https://github.com/menndouyukkuri/aviutl-installer-script/blob/main/LICENSE).

### I found a bug / I want this feature
Please write it in the [Issues](https://github.com/menndouyukkuri/aviutl-installer-script/issues).

However, please remember that just because **you write it does not mean it will be resolved immediately, and that the developers are also human and deserve respect**.\
Aggressive issues will be closed without review, so if you want to resolve it, please write politely.
