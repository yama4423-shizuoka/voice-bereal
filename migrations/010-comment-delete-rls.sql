-- 自分のコメントの削除権限
CREATE POLICY "users can delete own comments" ON comments
  FOR DELETE USING (auth.uid() = user_id);
