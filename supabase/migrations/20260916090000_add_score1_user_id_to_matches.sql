ALTER TABLE public.matches
  ADD COLUMN score1_user_id UUID REFERENCES public.users(user_id);

COMMENT ON COLUMN public.matches.score1_user_id IS
  'score1/score2の左右対応を保存するためのユーザーID。既存データは対応不明のためNULLを許容する。Issue #12の登録処理では登録者IDを必ず保存する。';
