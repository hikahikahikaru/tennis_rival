ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY users_select_self_or_group_members
ON public.users
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid()
  OR EXISTS (
    SELECT 1
    FROM public.group_members AS viewer_membership
    INNER JOIN public.group_members AS profile_membership
      ON profile_membership.group_id = viewer_membership.group_id
    WHERE viewer_membership.user_id = auth.uid()
      AND profile_membership.user_id = public.users.user_id
  )
);

REVOKE ALL ON public.users FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.users TO authenticated;
