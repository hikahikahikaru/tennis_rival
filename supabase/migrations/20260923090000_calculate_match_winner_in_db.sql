DROP FUNCTION public.create_singles_match(
  TIMESTAMP WITH TIME ZONE,
  SMALLINT,
  UUID,
  UUID,
  UUID,
  JSONB
);

CREATE FUNCTION public.create_singles_match(
  p_dt_match TIMESTAMP WITH TIME ZONE,
  p_total_set_amount SMALLINT,
  p_score1_user_id UUID,
  p_score2_user_id UUID,
  p_set_scores JSONB
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  new_match_id UUID := gen_random_uuid();
  score JSONB;
  set_number SMALLINT := 0;
  score1_won_set_count SMALLINT;
  score2_won_set_count SMALLINT;
  match_winner UUID;
BEGIN
  -- 同一ユーザーを両者として登録すると、参加者の複合主キーに違反するため事前に拒否する。
  IF p_score1_user_id = p_score2_user_id THEN
    RAISE EXCEPTION 'score1_user_id and score2_user_id must differ';
  END IF;

  IF jsonb_array_length(p_set_scores) = 0
    OR jsonb_array_length(p_set_scores) > p_total_set_amount THEN
    RAISE EXCEPTION 'set_scores must contain between 1 and total_set_amount rows';
  END IF;

  -- クライアントから勝者を受け取らず、各セットの得点から試合単位の勝者を決定する。
  SELECT
    COUNT(*) FILTER (WHERE (value ->> 'score1')::SMALLINT > (value ->> 'score2')::SMALLINT),
    COUNT(*) FILTER (WHERE (value ->> 'score1')::SMALLINT < (value ->> 'score2')::SMALLINT)
  INTO score1_won_set_count, score2_won_set_count
  FROM jsonb_array_elements(p_set_scores);

  match_winner := CASE
    WHEN score1_won_set_count > score2_won_set_count THEN p_score1_user_id
    WHEN score1_won_set_count < score2_won_set_count THEN p_score2_user_id
    ELSE NULL
  END;

  INSERT INTO public.matches (
    match_id,
    dt_match,
    match_type,
    total_set_amount,
    winner,
    score1_user_id
  )
  VALUES (
    new_match_id,
    p_dt_match,
    1,
    p_total_set_amount,
    match_winner,
    p_score1_user_id
  );

  -- 試合履歴はmatch_participantsを起点に取得するため、両参加者を必ず作成する。
  INSERT INTO public.match_participants (match_id, participant_id)
  VALUES
    (new_match_id, p_score1_user_id),
    (new_match_id, p_score2_user_id);

  FOR score IN SELECT value FROM jsonb_array_elements(p_set_scores)
  LOOP
    set_number := set_number + 1;

    -- score1側を登録者に固定し、セット勝者は各セットの得点から決定する。
    INSERT INTO public.set_scores (
      match_id,
      set_no,
      score1,
      score2,
      t_score1,
      t_score2,
      set_winner
    )
    VALUES (
      new_match_id,
      set_number,
      (score ->> 'score1')::SMALLINT,
      (score ->> 'score2')::SMALLINT,
      (score ->> 'tScore1')::SMALLINT,
      (score ->> 'tScore2')::SMALLINT,
      CASE
        WHEN (score ->> 'score1')::SMALLINT > (score ->> 'score2')::SMALLINT
          THEN p_score1_user_id
        WHEN (score ->> 'score1')::SMALLINT < (score ->> 'score2')::SMALLINT
          THEN p_score2_user_id
        ELSE NULL
      END
    );
  END LOOP;

  RETURN new_match_id;
END;
$$;