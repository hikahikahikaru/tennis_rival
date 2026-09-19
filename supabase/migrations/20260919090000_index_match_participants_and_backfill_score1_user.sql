-- match_participantsの主キーはmatch_id始まりのため、参加者から試合を探す取得を補助する。
CREATE INDEX IF NOT EXISTS match_participants_participant_id_match_id_idx
  ON public.match_participants (participant_id, match_id);

-- seed由来の2試合だけを対象に、登録者側のユーザーと参加関係を確認して補完する。
-- 既存の非NULL値や、対象ユーザーが存在しない環境のデータは変更しない。
UPDATE public.matches AS matches
SET score1_user_id = '11111111-1111-1111-1111-111111111111'
WHERE matches.match_id IN (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
  )
  AND matches.score1_user_id IS NULL
  AND EXISTS (
    SELECT 1
    FROM public.users AS users
    WHERE users.user_id = '11111111-1111-1111-1111-111111111111'
  )
  AND EXISTS (
    SELECT 1
    FROM public.match_participants AS participants
    WHERE participants.match_id = matches.match_id
      AND participants.participant_id =
        '11111111-1111-1111-1111-111111111111'
  );
