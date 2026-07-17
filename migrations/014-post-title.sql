-- postsテーブルに声のタイトル列を追加
alter table public.posts
  add column if not exists title text check (char_length(title) <= 15);

-- friend_feed ビューを再作成(title列を含める)
-- ※ビューの定義が下記と異なる場合はSupabaseダッシュボードの
--   Database > Views > friend_feed の定義を確認して調整してください
create or replace view public.friend_feed as
select
  p.id,
  p.user_id,
  p.post_date,
  p.created_at,
  p.caption,
  p.tag,
  p.title,
  pr.username,
  pr.bio,
  exists(
    select 1 from public.reactions r
    where r.post_id = p.id and r.user_id = auth.uid()
  ) as reacted_by_me
from public.posts p
join public.profiles pr on pr.id = p.user_id
where p.user_id <> auth.uid();
