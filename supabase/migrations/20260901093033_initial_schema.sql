CREATE TABLE public.groups (
  group_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_name TEXT NOT NULL,
  group_password TEXT NOT NULL,
  dt_created TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
  dt_updated TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

CREATE TABLE public.users (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  user_name TEXT NOT NULL UNIQUE,
  group_id UUID REFERENCES public.groups(group_id),
  others TEXT,
  dt_created TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
  dt_updated TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

CREATE TABLE public.matches (
  match_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dt_match TIMESTAMP WITH TIME ZONE NOT NULL,
  match_type SMALLINT NOT NULL,
  total_set_amount SMALLINT,
  winner UUID REFERENCES public.users(user_id),
  dt_created TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
  dt_updated TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

CREATE TABLE public.match_participants (
  match_id UUID REFERENCES public.matches(match_id) ON DELETE CASCADE,
  participant_id UUID REFERENCES public.users(user_id),
  pair_id UUID REFERENCES public.users(user_id),
  dt_created TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
  dt_updated TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
  PRIMARY KEY (match_id, participant_id)
);

CREATE TABLE public.set_scores (
  match_id UUID REFERENCES public.matches(match_id) ON DELETE CASCADE,
  set_no SMALLINT NOT NULL,
  score1 SMALLINT NOT NULL,
  score2 SMALLINT NOT NULL,
  t_score1 SMALLINT,
  t_score2 SMALLINT,
  set_winner UUID REFERENCES public.users(user_id),
  dt_created TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
  dt_updated TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
  PRIMARY KEY (match_id, set_no)
);
