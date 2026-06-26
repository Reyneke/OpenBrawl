projectID: "rcjxeoaqvvamxkflplrx"
publishable key: "default" : "sb_publishable_Mk9873X6VE6O9AsdbLZq8g_-eiA9SIQ"

create table public.profiles (
  id uuid not null,
  updated_at timestamp with time zone null,
  username text null,
  full_name text null,
  avatar_url text null,
  website text null,
  "isEnabled" boolean null default false,
  soullight bigint null default '0'::bigint,
  constraint profiles_pkey primary key (id),
  constraint profiles_username_key unique (username),
  constraint profiles_id_fkey foreign KEY (id) references auth.users (id),
  constraint username_length check ((char_length(username) >= 3))
) TABLESPACE pg_default;

1. create a provider called "provider_server" in the "provider" folder.
2. use "provider_server" to set up Supabase for this project.
3. build a login page with two buttons: One button allows an existing user to log in, the other calls the "signUp" method to create an user in table public.profiles. Label the buttons clearly.
4. when a user logs in, check if the variable "isEnabled" in his profile has been set to true. if not, the user is logged back out and warned that his account has not been enabled yet.
5. When the username is empty, direct the user to a screen, where he can edit and update his profile. Create this screen too.
6. place the login screen at the top of the screens shown after app start.