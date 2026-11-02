-- After creating your admin user in Supabase → Authentication → Users → Add user (tick "Auto Confirm User"),
-- put that email below and run this in the SQL Editor.
insert into public.admins (user_id)
select id from auth.users where email = 'contact@gmail.com'
on conflict do nothing;
