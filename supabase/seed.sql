-- 1. 認証システム (auth.users) にダミーユーザーを作成
-- raw_user_meta_dataのuser_nameからTriggerがpublic.usersを自動作成する。
INSERT INTO auth.users (id, raw_user_meta_data) VALUES
  (
    '11111111-1111-1111-1111-111111111111',
    '{"user_name":"たけし"}'::jsonb
  ),
  (
    '22222222-2222-2222-2222-222222222222',
    '{"user_name":"西やん"}'::jsonb
  ),
  (
    '33333333-3333-3333-3333-333333333333',
    '{"user_name":"ピンちゃん"}'::jsonb
  );

-- ▼▼▼ 新規追加: グループとメンバーの登録 ▼▼▼
-- 2. グループを作成
INSERT INTO public.groups (group_id, group_name, group_password) VALUES
  ('99999999-9999-9999-9999-999999999999', '週末テニスサークル', 'secret123'),
  ('88888888-8888-8888-8888-888888888888', '平日ナイターサークル', 'night456');

-- 3. ユーザーをグループに所属させる (group_members)
INSERT INTO public.group_members (group_id, user_id, role) VALUES
  ('99999999-9999-9999-9999-999999999999', '11111111-1111-1111-1111-111111111111', 2), -- たけしは管理者(2)
  ('99999999-9999-9999-9999-999999999999', '22222222-2222-2222-2222-222222222222', 1),
  ('99999999-9999-9999-9999-999999999999', '33333333-3333-3333-3333-333333333333', 1),
  -- ▼ 重複所属テスト用: たけしと西やんを2つ目のグループにも所属させる
  ('88888888-8888-8888-8888-888888888888', '11111111-1111-1111-1111-111111111111', 1),
  ('88888888-8888-8888-8888-888888888888', '22222222-2222-2222-2222-222222222222', 1);
-- ▲▲▲ ここまで ▲▲▲

-- 4. 試合の大枠 (matches) を登録
INSERT INTO public.matches (match_id, dt_match, match_type, total_set_amount, winner, score1_user_id) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '2026-08-24 10:00:00+09', 1, 3, '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '2026-08-18 14:00:00+09', 1, 3, '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111');

-- 5. 試合参加者 (match_participants) を紐付け
INSERT INTO public.match_participants (match_id, participant_id) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333');

-- 6. セットごとのスコア (set_scores) を登録
INSERT INTO public.set_scores (match_id, set_no, score1, score2, set_winner) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 6, 4, '11111111-1111-1111-1111-111111111111'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 2, 6, 3, '11111111-1111-1111-1111-111111111111'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 1, 4, 6, '33333333-3333-3333-3333-333333333333'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 2, 7, 5, '11111111-1111-1111-1111-111111111111'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 3, 10, 8, '11111111-1111-1111-1111-111111111111');
