-- フレンドのフィード用 RLS 追加
-- Supabase SQL Editor に貼り付けて実行(1回だけ)
-- 前提: migrations/002-friendships.sql が適用済みであること

-- posts: フレンドの投稿を参照可
create policy "posts: フレンドは参照可"
  on public.posts for select
  using (
    exists (
      select 1 from public.friendships f
      where (f.user_a = auth.uid() and f.user_b = posts.user_id)
         or (f.user_b = auth.uid() and f.user_a = posts.user_id)
    )
  );

-- profiles: フレンドの username を参照可
create policy "profiles: フレンドは参照可"
  on public.profiles for select
  using (
    exists (
      select 1 from public.friendships f
      where (f.user_a = auth.uid() and f.user_b = profiles.id)
         or (f.user_b = auth.uid() and f.user_a = profiles.id)
    )
  );

-- storage: フレンドの音声ファイルの signed URL 生成を許可
create policy "voices: フレンドは参照可"
  on storage.objects for select
  using (
    bucket_id = 'voices'
    and exists (
      select 1 from public.friendships f
      where (f.user_a = auth.uid() and f.user_b::text = (storage.foldername(name))[1])
         or (f.user_b = auth.uid() and f.user_a::text = (storage.foldername(name))[1])
    )
  );

-- friendships の user_b 検索を高速化
create index if not exists friendships_user_b_idx on public.friendships (user_b);
