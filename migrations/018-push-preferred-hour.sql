-- push_subscriptions に通知希望時刻(JST)を追加
-- NULL = 毎日変わるランダム時刻(従来の動作を維持)
-- 11~21 = ユーザーが指定した JST 時台に通知

ALTER TABLE public.push_subscriptions
  ADD COLUMN IF NOT EXISTS pref_hour_jst smallint
  CHECK (pref_hour_jst BETWEEN 11 AND 21);
