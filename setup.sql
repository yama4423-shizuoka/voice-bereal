-- コエリアル データベース初期設定
-- Supabase の SQL Editor に貼り付けて Run してください(1回だけ)

-- プロフィール(ユーザーごとに1行)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null check (char_length(username) between 1 and 20),
  bio text not null default '' check (char_length(bio) <= 200),
  updated_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
create policy "profiles: 本人のみ参照" on public.profiles for select using (auth.uid() = id);
create policy "profiles: 本人のみ作成" on public.profiles for insert with check (auth.uid() = id);
create policy "profiles: 本人のみ更新" on public.profiles for update using (auth.uid() = id);

-- 音声投稿(1日1回制限は unique 制約で強制)
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  audio_path text not null,
  caption text not null default '' check (char_length(caption) <= 100),
  duration_sec int check (duration_sec between 1 and 60),
  post_date date not null,
  created_at timestamptz not null default now(),
  unique (user_id, post_date)
);
alter table public.posts enable row level security;
create policy "posts: 本人のみ参照" on public.posts for select using (auth.uid() = user_id);
create policy "posts: 本人のみ作成" on public.posts for insert with check (auth.uid() = user_id);
create policy "posts: 本人のみ削除" on public.posts for delete using (auth.uid() = user_id);

-- 音声ファイル用の非公開バケット
insert into storage.buckets (id, name, public) values ('voices', 'voices', false)
on conflict (id) do nothing;

-- ストレージのアクセス制御(自分のフォルダのみ読み書き可)
create policy "voices: 本人のみ参照" on storage.objects for select
  using (bucket_id = 'voices' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "voices: 本人のみ作成" on storage.objects for insert
  with check (bucket_id = 'voices' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "voices: 本人のみ削除" on storage.objects for delete
  using (bucket_id = 'voices' and auth.uid()::text = (storage.foldername(name))[1]);
