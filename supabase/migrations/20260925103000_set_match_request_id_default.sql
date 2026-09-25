ALTER TABLE public.matches
  ALTER COLUMN client_request_id SET DEFAULT gen_random_uuid();
