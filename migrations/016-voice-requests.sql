-- voice_requests: フレンドへの声リクエスト
create table if not exists voice_requests (
  id uuid primary key default gen_random_uuid(),
  from_user_id uuid references profiles(id) on delete cascade not null,
  to_user_id   uuid references profiles(id) on delete cascade not null,
  created_at   timestamptz default now() not null,
  unique(from_user_id, to_user_id)
);

alter table voice_requests enable row level security;

-- 自分が送った/受け取ったリクエストのみ参照可
create policy "voice_requests_select" on voice_requests
  for select using (auth.uid() = from_user_id or auth.uid() = to_user_id);

-- フレンドへのリクエスト送信(from_user_idが自分)
create policy "voice_requests_insert" on voice_requests
  for insert with check (
    auth.uid() = from_user_id
    and exists (
      select 1 from friendships
      where user_id = auth.uid() and friend_id = to_user_id
    )
  );

-- 送信者のみ削除可
create policy "voice_requests_delete" on voice_requests
  for delete using (auth.uid() = from_user_id);
