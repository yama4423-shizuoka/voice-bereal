-- 008-muted-friends.sql
-- profilesテーブルにmuted_friends列(jsonb)を追加

alter table profiles
  add column if not exists muted_friends jsonb not null default '[]'::jsonb;
