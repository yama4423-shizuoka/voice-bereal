-- push_subscriptions に通知ON/OFFフラグを追加
-- Supabase SQL Editor で実行してください

ALTER TABLE public.push_subscriptions
  ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true;

-- UPDATEポリシー(本人のみ自分の購読を更新可)
CREATE POLICY "push_subscriptions: 本人のみ更新"
  ON public.push_subscriptions FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
