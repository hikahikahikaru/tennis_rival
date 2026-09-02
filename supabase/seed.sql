-- 1. 認証システム (auth.users) にダミーIDを作成
INSERT INTO auth.users (id) VALUES
  ('11111111-1111-1111-1111-111111111111'), -- たけし用
  ('22222222-2222-2222-2222-222222222222'), -- 西やん用
  ('33333333-3333-3333-3333-333333333333'); -- ピンちゃん用

-- 2. アプリ用ユーザー情報 (public.users) を登録
INSERT INTO public.users (user_id, user_name) VALUES
  ('11111111-1111-1111-1111-111111111111', 'たけし'),
  ('22222222-2222-2222-2222-222222222222', '西やん'),
  ('33333333-3333-3333-3333-333333333333', 'ピンちゃん');

-- 3. 試合の大枠 (matches) を登録（match_type: 1=シングルス, total_set_amount: 3=3セット）
INSERT INTO public.matches (match_id, dt_match, match_type, total_set_amount, winner) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '2026-08-24 10:00:00+09', 1, 3, '11111111-1111-1111-1111-111111111111'), -- 8/24 vs 西やん
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '2026-08-18 14:00:00+09', 1, 3, '11111111-1111-1111-1111-111111111111'); -- 8/18 vs ピンちゃん

-- 4. 試合参加者 (match_participants) を紐付け
INSERT INTO public.match_participants (match_id, participant_id) VALUES
  -- 1試合目 (たけし vs 西やん)
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222'),
  -- 2試合目 (たけし vs ピンちゃん)
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333');

-- 5. セットごとのスコア (set_scores) を登録
INSERT INTO public.set_scores (match_id, set_no, score1, score2, set_winner) VALUES
  -- 1試合目 (6-4, 6-3) ※score1をたけし側として登録
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 6, 4, '11111111-1111-1111-1111-111111111111'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 2, 6, 3, '11111111-1111-1111-1111-111111111111'),
  -- 2試合目 (4-6, 7-5, 10-8) 
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 1, 4, 6, '33333333-3333-3333-3333-333333333333'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 2, 7, 5, '11111111-1111-1111-1111-111111111111'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 3, 10, 8, '11111111-1111-1111-1111-111111111111');
  