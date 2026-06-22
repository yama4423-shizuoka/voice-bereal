-- postsテーブルにtag列を追加(投稿時の気分タグ機能)
ALTER TABLE posts ADD COLUMN IF NOT EXISTS tag text;
