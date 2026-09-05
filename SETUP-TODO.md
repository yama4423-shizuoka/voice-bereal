# セットアップ手順(オーナー作業)

## ブックマークラベル機能 (2026-09-05 実装)

### Supabase でのマイグレーション実行

Supabase SQL Editor で以下を実行してください:

```
migrations/019-bookmark-labels.sql
```

これにより `bookmark_labels` テーブルが作成されます。
未実行の場合でも、ブックマーク機能自体は正常に動作します(ラベル設定時のみエラートースト表示)。

---

## パスワードリセット (2026-06-13 実装)

### Supabase の Redirect URL 設定

リセットメール内のリンクをクリックしたとき、アプリに戻れるようにするため、
Supabase ダッシュボードで本番 URL を許可リストに追加する必要があります。

1. Supabase ダッシュボード > Authentication > URL Configuration を開く
2. **Redirect URLs** に以下を追加して保存する:

```
https://voice-bereal.vercel.app/
```

3. 動作確認:
   - ログイン画面の「パスワードを忘れた場合」をタップ
   - 登録済みのメールアドレスを入力して「再設定メールを送る」
   - 受信したメールのリンクをタップ → アプリが「新しいパスワードを設定」画面で開く
   - 新しいパスワードを入力して「パスワードを更新する」
   - ログイン画面に戻るので、新しいパスワードでログイン

---

## Web Push通知 (2026-06-13 実装)

### 1. データベース
Supabase SQL Editorで以下を実行:

```
migrations/001-push-subscriptions.sql
```

### 2. VAPIDキー生成
Node.jsが使える端末で以下を実行:

```
npx web-push generate-vapid-keys
```

`Public Key` と `Private Key` が出力されます。

### 3. Vercel 環境変数
Vercel ダッシュボード > Settings > Environment Variables に追加:

| 変数名 | 値 | 備考 |
|---|---|---|
| `VAPID_PUBLIC_KEY` | 生成した Public Key | フロントへ渡す公開鍵(秘密でない) |
| `VAPID_PRIVATE_KEY` | 生成した Private Key | 絶対に公開しない |
| `VAPID_SUBJECT` | `mailto:あなたのメール` | プッシュサービスへの連絡先 |
| `SUPABASE_URL` | `https://xxx.supabase.co` | プロジェクトURL |
| `SUPABASE_SERVICE_ROLE_KEY` | service_role キー | 絶対に公開しない |
| `CRON_SECRET` | 任意のランダム文字列(32文字以上推奨) | Cronエンドポイント保護用 |

### 4. Vercel Cron について
`vercel.json` に `"0 2-12 * * *"` のCronを設定済みです。
これは UTC 2:00-12:00 (JST 11:00-21:00) の毎時0分に `/api/push-notify` を呼び出します。
関数側で日付をシードにした決定論的な時刻と照合するため、通知は1日1回だけ送られます。

**注意**: Vercel Cronはカスタムスケジュールに Proプラン以上が必要です。
Hobbyプランの場合は以下の代替案を使ってください:
- Supabase Edge Functions のスケジューラ
- GitHub Actions の `schedule` トリガー
- その他の外部CronサービスでPOSTリクエストを送る

いずれの場合も `POST /api/push-notify` に `Authorization: Bearer <CRON_SECRET>` ヘッダを付けて呼び出してください。

### 5. 動作確認
設定・デプロイ後にアプリのプロフィール画面を開くと「通知」カードが表示されます。
「通知をオンにする」をタップして購読し、翌日の指定時刻に通知が届くことを確認してください。
