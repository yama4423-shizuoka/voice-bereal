-- 自分の投稿のキャプション編集を許可するUPDATE RLSポリシー
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users can update own post caption" ON posts
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
