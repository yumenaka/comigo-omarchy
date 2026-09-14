<div align="center">

# comigo-omarchy

[English](README.md) | [中文](README_ZH.md) | [日本語](README_JP.md)

</div>

![Comigo Omarchy プラグインのプレビュー](https://www.yumenaka.net/wp-content/uploads/2026/09/screenshot-comigo-omarchy-plugin.png)

漫画・画像リーダー [Comigo](https://github.com/yumenaka/comigo) の Omarchy ステータスバープラグインです。日本語・英語・中国語に対応しています。

## プラグインのインストール

```bash
omarchy plugin add https://github.com/yumenaka/comigo-omarchy --enable
```

インストール後、ステータスバーの Comigo アイコンをクリックしてパネルを開きます。

## アンインストール

```bash
omarchy plugin remove yumenaka.comigo
```

## 使い方と必要環境

Shell プラグイン対応の Omarchy、curl 8.4 以降、および `/api/info` を提供する Comigo v1.3.7 以降の稼働中サービスが必要です。curl 経由で REST に接続し、プラグイン側に `comi` は不要です。HTTP リダイレクトには追従しないため、BasePath を含む最終的なサービス URL を指定してください。リクエストのタイムアウトは 15 秒、レスポンス上限は 1 MiB です。パスワードとトークンは標準入力で渡し、プロセス引数や一時ファイルには保存しません。

1. プラグインの外で Comigo をインストールして起動します：[GitHub](https://github.com/yumenaka/comigo) または [comigo.xyz](https://comigo.xyz/)（中国本土に推奨）。
2. 「設定」に完全なサービス URL を入力します。例：`http://127.0.0.1:1234/`、`https://reader.example/books/`。
3. パスワード保護が有効ならプラグイン内でログインし、「概要」のリンクや QR コードから読み始めます。トークンはメモリ内にのみ保持し、サービス URL ごとに分離します。

サービスに接続できない場合、パネルは設定ページで開きます。プラグインの設定は Omarchy ホストが保存します。

## 機能

- 概要・状態・サービス・設定の 4 ページ。閲覧リンク、QR コード、サーバー IP 切替、バージョン、書籍・接続数、転送速度と累計を表示します。
- 外部アクセスのスイッチは、保存済み接続 URL のホストが `127.0.0.1` または `localhost` の場合のみ表示します。リモートから無効にして復旧できなくなることを防ぎます。読み取り専用モードではサービス設定を変更できません。設定ファイル情報は表示のみで、詳細設定は Comigo の Web 画面を使用します。
- 「サービス」には GitHub と comigo.xyz（中国本土に推奨）のリンクを表示します。バイナリのインストール、Comigo プロセス・systemd・ファイアウォールの管理、更新確認は行いません。
- 自動起動は Comigo の Web 設定の「サーバー管理」または CLI で管理します。初期状態はオフで、Linux では systemd ユーザーサービスによりログイン後に起動します。停止中のサービスはプラグインの外で起動してください。
- サイドバーで中英日を切り替えます。`1`–`4` でページ選択、`r` で更新、`Esc` で閉じます。

プラグインを閉じたり削除したりしても、Comigo は停止せず書庫も削除しません。接続できない場合はサービスの稼働状態、完全な URL、認証情報を確認してください。

## マニュアル

詳しくは [Comigo マニュアル](https://comigo.xyz/manual/comigo-omarchy)をご覧ください。

## ライセンスと謝辞

MIT ライセンスです。[LICENSE](LICENSE) を参照してください。UI は [omarchy-mihomo-plugin](https://github.com/lijiawei0305-pixel/omarchy-mihomo-plugin) を参考にしています。
