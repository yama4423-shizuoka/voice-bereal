-- postsテーブルにreply_to列追加(返声機能)
-- Supabase SQL Editor に貼り付けて実行(1回だけ)

ALTER TABLE public.posts
  ADD COLUMN IF NOT EXISTS reply_to UUID REFERENCES public.posts(id) ON DELETE SET NULL;

-- friend_feed ビューを再作成(reply_to列を含める)
CREATE OR REPLACE VIEW public.friend_feed AS
SELECT
  p.id,
  p.user_id,
  p.post_date,
  p.created_at,
  p.caption,
  p.tag,
  p.title,
  p.reply_to,
  pr.username,
  pr.bio,
  EXISTS(
    SELECT 1 FROM public.reactions r
    WHERE r.post_id = p.id AND r.user_id = auth.uid()
  ) AS reacted_by_me
FROM public.posts p
JOIN public.profiles pr ON pr.id = p.user_id
WHERE p.user_id <> auth.uid();
