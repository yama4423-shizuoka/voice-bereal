-- migrations/020-voice-comments.sql
-- フレンドの投稿に15秒以内の音声クリップを残す機能
-- ストレージ: voice-posts バケット内の vc/{user_id}/{post_id}/{timestamp}.webm
-- オーナー作業: 1) このSQLをSupabaseで実行 2) voice-postsバケットのストレージポリシーに
--   vc/ プレフィックスへの insert/select/delete を認証ユーザーに付与
--   (既存ポリシーが全パスを許可している場合は追加不要)

create table if not exists public.voice_comments (
  id          uuid        primary key default gen_random_uuid(),
  post_id     uuid        not null references public.posts(id) on delete cascade,
  user_id     uuid        not null references public.profiles(id) on delete cascade,
  audio_path  text        not null,
  created_at  timestamptz not null default now()
);

alter table public.voice_comments enable row level security;

-- 自分のコメントのみ投稿可
create policy "vc_insert" on public.voice_comments
  for insert with check (auth.uid() = user_id);

-- 自分のコメント、または投稿者が自分/フレンドの場合に参照可
create policy "vc_select" on public.voice_comments
  for select using (
    auth.uid() = user_id
    or exists (
      select 1 from public.posts p
      where p.id = post_id
        and (
          p.user_id = auth.uid()
          or exists (
            select 1 from public.friendships f
            where (f.user_id = auth.uid() and f.friend_id = p.user_id)
               or (f.friend_id = auth.uid() and f.user_id = p.user_id)
          )
        )
    )
  );

-- 自分のコメントのみ削除可
create policy "vc_delete" on public.voice_comments
  for delete using (auth.uid() = user_id);
