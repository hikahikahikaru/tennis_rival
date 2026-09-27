CREATE FUNCTION public.set_match_memo_dt_updated()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.dt_updated = timezone('utc', now());
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_match_memo_dt_updated
BEFORE UPDATE ON public.match_memos
FOR EACH ROW
EXECUTE FUNCTION public.set_match_memo_dt_updated();

-- TODO(auth): 認証導入後はmatch_memosのRLSを有効化し、すべての操作を
-- user_id = auth.uid() の本人行へ限定する。現在のMockDataによるID指定は
-- アクセス制御ではなく、複合外部キーも試合参加者であることだけを保証する。
