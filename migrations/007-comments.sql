-- 007-comments.sql
-- フレンドの投稿にテキストコメント(30文字以内)を残せるテーブル

create table if not exists comments (
  id         uuid        primary key default gen_random_uuid(),
  post_id    uuid        not null references posts(id) on delete cascade,
  user_id    uuid        not null references auth.users(id) on delete cascade,
  body       text        not null check (char_length(body) <= 30),
  created_at timestamptz not null default now()
);

create index if not exists comments_post_id_idx on comments(post_id);

alter table comments enable row level security;

-- SELECT: 自分の投稿またはフレンドの投稿のコメントのみ閲覧可
create policy "read comments on own or friend posts" on comments
  for select using (
    post_id in (select id from posts where user_id = auth.uid())
    or post_id in (select id from friend_feed)
  );

-- INSERT: フレンドの投稿にのみコメント可(自分の投稿へは不可)
create policy "insert comment on friend post" on comments
  for insert with check (
    auth.uid() = user_id
    and post_id in (select id from friend_feed)
  );

-- DELETE: 自分のコメントのみ削除可
create policy "delete own comments" on comments
  for delete using (auth.uid() = user_id);
