-- フレンドを解除するRPC(user_a/user_b 双方向で削除)
create or replace function remove_friend(target_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not_authenticated';
  end if;
  if uid = target_id then
    raise exception 'cannot_remove_self';
  end if;
  delete from friendships
  where (user_a = uid and user_b = target_id)
     or (user_a = target_id and user_b = uid);
end;
$$;

grant execute on function remove_friend(uuid) to authenticated;
