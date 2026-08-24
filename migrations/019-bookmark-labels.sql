-- 019-bookmark-labels.sql
-- フレンドの投稿にプライベートラベル(面白い/感動/あとで聴く)を付ける機能
CREATE TABLE IF NOT EXISTS bookmark_labels (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid        REFERENCES auth.users NOT NULL,
  post_id    uuid        REFERENCES posts(id) ON DELETE CASCADE NOT NULL,
  label      text        NOT NULL CHECK (label IN ('面白い', '感動', 'あとで聴く')),
  created_at timestamptz DEFAULT now() NOT NULL,
  UNIQUE(user_id, post_id)
);
ALTER TABLE bookmark_labels ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users can manage own bookmark labels" ON bookmark_labels
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
