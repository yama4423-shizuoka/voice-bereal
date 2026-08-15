-- friend_stamps: フレンドへの一言スタンプ(1日1回)
create table if not exists friend_stamps (
  id            uuid primary key default gen_random_uuid(),
  from_user_id  uuid references profiles(id) on delete cascade not null,
  to_user_id    uuid references profiles(id) on delete cascade not null,
  stamp_type    text not null check (stamp_type in ('がんばれ', 'ありがとう', 'すごい')),
  created_at    timestamptz default now() not null
);

-- 同じ日(JST)に同じ送信者→受信者のスタンプを1件のみ許可
create unique index if not exists friend_stamps_daily_uniq
  on friend_stamps (from_user_id, to_user_id, ((created_at at time zone 'Asia/Tokyo')::date));

alter table friend_stamps enable row level security;

-- 送信者と受信者のみ参照可
create policy "friend_stamps_select" on friend_stamps
  for select using (auth.uid() = from_user_id or auth.uid() = to_user_id);

-- フレンドへのスタンプ送信(from_user_idが自分、かつ相互フレンド)
create policy "friend_stamps_insert" on friend_stamps
  for insert with check (
    auth.uid() = from_user_id
    and exists (
      select 1 from friendships
      where user_id = auth.uid() and friend_id = to_user_id
    )
  );
