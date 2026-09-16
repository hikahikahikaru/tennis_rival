-- 1. 認証システム (auth.users) にダミーIDを作成
INSERT INTO auth.users (id) VALUES
  ('11111111-1111-1111-1111-111111111111'), -- たけし用
  ('22222222-2222-2222-2222-222222222222'), -- 西やん用
  ('33333333-3333-3333-3333-333333333333'); -- ピンちゃん用

-- ▼▼▼ 新規追加: グループとメンバーの登録 ▼▼▼
-- 2. グループを作成
INSERT INTO public.groups (group_id, group_name, group_password) VALUES
  ('99999999-9999-9999-9999-999999999999', '週末テニスサークル', 'secret123'),
  ('88888888-8888-8888-8888-888888888888', '平日ナイターサークル', 'secret123');

-- 3. アプリ用ユーザー情報を登録 (group_id を削除)
INSERT INTO public.users (user_id, user_name) VALUES
  ('11111111-1111-1111-1111-111111111111', 'たけし'),
  ('22222222-2222-2222-2222-222222222222', '西やん'),
  ('33333333-3333-3333-3333-333333333333', 'ピンちゃん');

-- 4. ユーザーをグループに所属させる (group_members)
INSERT INTO public.group_members (group_id, user_id, role) VALUES
  ('99999999-9999-9999-9999-999999999999', '11111111-1111-1111-1111-111111111111', 2), -- たけしは管理者(2)
  ('99999999-9999-9999-9999-999999999999', '22222222-2222-2222-2222-222222222222', 1),
  ('99999999-9999-9999-9999-999999999999', '33333333-3333-3333-3333-333333333333', 1),
  -- ▼ 重複所属テスト用: たけしと西やんを2つ目のグループにも所属させる
  ('88888888-8888-8888-8888-888888888888', '11111111-1111-1111-1111-111111111111', 1),
  ('88888888-8888-8888-8888-888888888888', '22222222-2222-2222-2222-222222222222', 1);
-- ▲▲▲ ここまで ▲▲▲

-- 5. 試合の大枠 (matches) を登録
INSERT INTO public.matches (match_id, dt_match, match_type, total_set_amount, winner) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '2026-08-24 10:00:00+09', 1, 3, '11111111-1111-1111-1111-111111111111'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '2026-08-18 14:00:00+09', 1, 3, '11111111-1111-1111-1111-111111111111');

-- 6. 試合参加者 (match_participants) を紐付け
INSERT INTO public.match_participants (match_id, participant_id) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333');

-- 7. セットごとのスコア (set_scores) を登録
INSERT INTO public.set_scores (match_id, set_no, score1, score2, set_winner) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 6, 4, '11111111-1111-1111-1111-111111111111'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 2, 6, 3, '11111111-1111-1111-1111-111111111111'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 1, 4, 6, '33333333-3333-3333-3333-333333333333'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 2, 7, 5, '11111111-1111-1111-1111-111111111111'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 3, 10, 8, '11111111-1111-1111-1111-111111111111');
  