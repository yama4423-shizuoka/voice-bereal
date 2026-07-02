-- Allow users to update their own profile row (username, bio, etc.)
CREATE POLICY "users can update own profile"
  ON profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);
