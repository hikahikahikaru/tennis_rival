-- Existing duplicate invite codes must be resolved before enforcing uniqueness.
WITH ranked_group_codes AS (
  SELECT
    group_id,
    row_number() OVER (
      PARTITION BY lower(group_password)
      ORDER BY dt_created, group_id
    ) AS duplicate_number
  FROM public.groups
)
UPDATE public.groups AS groups
SET
  group_password = upper(encode(extensions.gen_random_bytes(16), 'hex')),
  dt_updated = timezone('utc', now())
FROM ranked_group_codes
WHERE groups.group_id = ranked_group_codes.group_id
  AND ranked_group_codes.duplicate_number > 1;

CREATE UNIQUE INDEX groups_group_password_lower_uidx
ON public.groups (lower(group_password));

-- RLS policies use this definer function to avoid recursive group_members checks.
CREATE OR REPLACE FUNCTION public.is_group_member(p_group_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.group_members
    WHERE group_id = p_group_id
      AND user_id = auth.uid()
  );
$$;

REVOKE ALL ON FUNCTION public.is_group_member(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_group_member(UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.is_group_member(UUID) TO authenticated;

ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY groups_select_for_members
ON public.groups
FOR SELECT
TO authenticated
USING (public.is_group_member(group_id));

CREATE POLICY group_members_select_for_members
ON public.group_members
FOR SELECT
TO authenticated
USING (public.is_group_member(group_id));

REVOKE ALL ON public.groups FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.group_members FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.groups TO authenticated;
GRANT SELECT ON public.group_members TO authenticated;

CREATE OR REPLACE FUNCTION public.create_group(
  p_group_name TEXT,
  p_group_description TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  creator_id UUID := auth.uid();
  new_group_id UUID;
  invite_code TEXT;
BEGIN
  IF creator_id IS NULL THEN
    RAISE EXCEPTION 'authentication required' USING ERRCODE = '42501';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.users WHERE user_id = creator_id
  ) THEN
    RAISE EXCEPTION 'authenticated user profile not found'
      USING ERRCODE = '23503';
  END IF;

  IF nullif(trim(p_group_name), '') IS NULL THEN
    RAISE EXCEPTION 'group name is required' USING ERRCODE = '22023';
  END IF;

  LOOP
    invite_code := upper(encode(extensions.gen_random_bytes(16), 'hex'));

    BEGIN
      INSERT INTO public.groups (
        group_name,
        group_password,
        group_description
      )
      VALUES (
        trim(p_group_name),
        invite_code,
        nullif(trim(p_group_description), '')
      )
      RETURNING group_id INTO new_group_id;

      EXIT;
    EXCEPTION
      WHEN unique_violation THEN
        -- A collision retries inside the same RPC without exposing a partial row.
    END;
  END LOOP;

  INSERT INTO public.group_members (group_id, user_id, role)
  VALUES (new_group_id, creator_id, 2);

  RETURN new_group_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_group(TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_group(TEXT, TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION public.create_group(TEXT, TEXT) TO authenticated;
