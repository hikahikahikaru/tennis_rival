-- match_participantsの主キーはmatch_id始まりのため、参加者から試合を探す取得を補助する。
CREATE INDEX IF NOT EXISTS match_participants_participant_id_match_id_idx
  ON public.match_participants (participant_id, match_id);

-- seed由来の試合とscore1側ユーザーの対応を明示し、既存データを補完する。
-- 既存の非NULL値や、対象ユーザー・参加関係が存在しないデータは変更しない。
WITH target_matches(match_id, score1_user_id) AS (
  VALUES
    (
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
      '11111111-1111-1111-1111-111111111111'::UUID
    ),
    (
      'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::UUID,
      '11111111-1111-1111-1111-111111111111'::UUID
    )
)
UPDATE public.matches AS matches
SET score1_user_id = target_matches.score1_user_id
FROM target_matches
WHERE matches.match_id = target_matches.match_id
  AND matches.score1_user_id IS NULL
  AND EXISTS (
    SELECT 1
    FROM public.users AS users
    WHERE users.user_id = target_matches.score1_user_id
  )
  AND EXISTS (
    SELECT 1
    FROM public.match_participants AS participants
    WHERE participants.match_id = matches.match_id
      AND participants.participant_id = target_matches.score1_user_id
  );
