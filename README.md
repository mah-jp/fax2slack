# fax2slack.pl - Fax incoming Notifier for Slack

## What is this?

FUJI XEROXの複合機 (動作確認はDocuCentre-IV C2263Nで行いました) のウェブ管理画面にある「ジョブ履歴」の内容を実行時にチェックし、新しいFAX受信があれば、受信時刻と枚数をSlackに通知します。

## USAGE

数分間隔で定期実行されることを前提に作成しました。必要となるPerlモジュールは、動作環境にcpanmなどでインストールしておいてください。

- INIファイルを指定して本番実行: fax2slack.pl -i fax2slack_yours.ini
- テスト実行: fax2slack.pl -n

実行前には、あらかじめ、INIファイル内に、Slackのwebhook URLや、複合機のIPアドレスなどの設定を記述しておく必要があります。

## AUTHOR

大久保 正彦 (Masahiko OHKUBO) <[mah@remoteroom.jp](mailto:mah@remoteroom.jp)> <[https://twitter.com/mah_jp](https://twitter.com/mah_jp)>

## COPYRIGHT and LICENSE

This software is copyright (c) 2017 by Masahiko OHKUBO.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
