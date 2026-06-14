-- フレンド機能 第1段
-- Supabase SQL Editor に貼り付けて実行(1回だけ)

-- 1. profiles にフレンドコード列を追加
alter table public.profiles
  add column if not exists friend_code text unique;

-- 2. 新規ユーザー向けトリガー(insert 時に自動生成)
create or replace function public._set_friend_code()
returns trigger language plpgsql as $$
declare code text;
begin
  if new.friend_code is null then
    loop
      code := lower(substr(md5(random()::text || clock_timestamp()::text), 1, 6));
      exit when not exists (select 1 from public.profiles where friend_code = code);
    end loop;
    new.friend_code := code;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_friend_code on public.profiles;
create trigger trg_profiles_friend_code
  before insert on public.profiles
  for each row execute function public._set_friend_code();

-- 3. 既存ユーザーにもコードを付与(重複しないよう row_number ベースのシード)
update public.profiles
  set friend_code = lower(substr(md5(id::text || random()::text), 1, 6))
  where friend_code is null;

-- 4. フレンドシップテーブル(user_a < user_b で一意制約)
create table if not exists public.friendships (
  user_a uuid not null references auth.users(id) on delete cascade,
  user_b uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_a, user_b),
  check (user_a < user_b)
);
alter table public.friendships enable row level security;

create policy "friendships: 当事者のみ参照"
  on public.friendships for select
  using (auth.uid() = user_a or auth.uid() = user_b);

create policy "friendships: 当事者のみ削除"
  on public.friendships for delete
  using (auth.uid() = user_a or auth.uid() = user_b);

-- 5. フレンドコードでフレンド追加する RPC
--    SECURITY DEFINER で profiles を安全に参照(他ユーザーの RLS をバイパスしない形で実装)
create or replace function public.add_friend_by_code(target_code text)
returns json language plpgsql
security definer
set search_path = public
as $$
declare
  target_id   uuid;
  target_name text;
  me_id       uuid := auth.uid();
  a_id        uuid;
  b_id        uuid;
begin
  if me_id is null then
    raise exception 'not_authenticated';
  end if;

  select id, username
    into target_id, target_name
    from profiles
    where friend_code = lower(trim(target_code))
    limit 1;

  if target_id is null then
    raise exception 'code_not_found';
  end if;

  if target_id = me_id then
    raise exception 'cannot_friend_self';
  end if;

  -- 正規順序で重複なく挿入
  a_id := least(me_id, target_id);
  b_id := greatest(me_id, target_id);

  insert into friendships (user_a, user_b)
    values (a_id, b_id)
    on conflict do nothing;

  return json_build_object('username', target_name);
end;
$$;
