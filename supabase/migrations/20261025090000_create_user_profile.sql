ALTER TABLE public.users
DROP CONSTRAINT users_user_name_key;

CREATE SCHEMA IF NOT EXISTS private;

REVOKE ALL ON SCHEMA private FROM PUBLIC;
REVOKE ALL ON SCHEMA private FROM anon;
REVOKE ALL ON SCHEMA private FROM authenticated;

CREATE OR REPLACE FUNCTION private.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  whitespace_pattern CONSTANT TEXT :=
    U&'^[[:space:]\00A0\1680\2000-\200A\2028\2029\202F\205F\3000\FEFF]+'
    ||
    U&'|[[:space:]\00A0\1680\2000-\200A\2028\2029\202F\205F\3000\FEFF]+$';
  display_name TEXT := nullif(
    regexp_replace(
      NEW.raw_user_meta_data ->> 'user_name',
      whitespace_pattern,
      '',
      'g'
    ),
    ''
  );
BEGIN
  -- 表示名のない認証ユーザーと不完全なプロフィールが分離して残るのを防ぐ。
  IF display_name IS NULL THEN
    RAISE EXCEPTION 'user_name is required in raw_user_meta_data'
      USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.users (user_id, user_name)
  VALUES (NEW.id, display_name);

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.handle_new_auth_user() FROM PUBLIC;
REVOKE ALL ON FUNCTION private.handle_new_auth_user() FROM anon;
REVOKE ALL ON FUNCTION private.handle_new_auth_user() FROM authenticated;

CREATE TRIGGER create_user_profile_after_auth_signup
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION private.handle_new_auth_user();
