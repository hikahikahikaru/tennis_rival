CREATE TABLE public.match_memos (
  match_id UUID NOT NULL,
  user_id UUID NOT NULL,
  memo TEXT,
  dt_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
  dt_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
  PRIMARY KEY (match_id, user_id),
  CONSTRAINT match_memos_match_participant_fkey
    FOREIGN KEY (match_id, user_id)
    REFERENCES public.match_participants (match_id, participant_id)
    ON DELETE CASCADE
);

COMMENT ON TABLE public.match_memos IS
  '試合参加者本人だけが利用する個人メモ。1試合・1ユーザーにつき1件を保持する。';

-- TODO(auth): 認証導入後にRLSを有効化し、SELECTとINSERT/UPDATE/DELETEを
-- user_id = auth.uid() の本人行へ限定する。複合外部キーは試合参加者であることだけを保証し、
-- 現在のクライアント側user_id絞り込みはアクセス制御にはならない。
