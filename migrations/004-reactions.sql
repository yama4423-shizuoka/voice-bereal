-- リアクション機能(聴いたよ)
-- Supabase SQL Editor に貼り付けて実行(1回だけ)
-- 前提: migrations/003-friend-feed.sql が適用済みであること

create table if not exists public.reactions (
  id         bigserial primary key,
  post_id    uuid not null references public.posts(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (post_id, user_id)
);

alter table public.reactions enable row level security;

-- 自分のリアクション・自分の投稿へのリアクション・フレンド投稿へのリアクションを参照可
create policy "reactions: 参照可"
  on public.reactions for select
  using (
    user_id = auth.uid()
    or exists (
      select 1 from public.posts p
      where p.id = reactions.post_id
        and (
          p.user_id = auth.uid()
          or exists (
            select 1 from public.friendships f
            where (f.user_a = auth.uid() and f.user_b = p.user_id)
               or (f.user_b = auth.uid() and f.user_a = p.user_id)
          )
        )
    )
  );

-- フレンドの投稿にのみリアクション可
create policy "reactions: フレンド投稿のみ追加可"
  on public.reactions for insert
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.posts p
      join public.friendships f on (
        (f.user_a = auth.uid() and f.user_b = p.user_id)
        or (f.user_b = auth.uid() and f.user_a = p.user_id)
      )
      where p.id = reactions.post_id
    )
  );

-- 自分のリアクションのみ削除可
create policy "reactions: 自分のみ削除可"
  on public.reactions for delete
  using (user_id = auth.uid());

create index if not exists reactions_post_id_idx on public.reactions (post_id);
create index if not exists reactions_user_id_idx on public.reactions (user_id);
