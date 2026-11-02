\set ON_ERROR_STOP on
\set QUIET on
create or replace function pg_temp.fails(sql text, expect text) returns void language plpgsql as $$
begin
  begin execute sql; exception when others then
    if sqlerrm like '%'||expect||'%' then return; end if;
    raise exception 'wrong error for [%]: got [%] expected [%]', sql, sqlerrm, expect; end;
  raise exception 'should have failed: %', sql;
end $$;
grant execute on function pg_temp.fails(text,text) to public;
insert into products(id,name,category,price,stock,sizes,active) values ('hid-1','Hidden','watches',10,5,'{}',false);
insert into auth.users(id,email) values ('00000000-0000-0000-0000-0000000000aa','admin@x.com'),('00000000-0000-0000-0000-0000000000bb','rando@x.com');
insert into admins values ('00000000-0000-0000-0000-0000000000aa');

-- ===== anonymous visitor =====
set role anon; select set_config('request.jwt.claim.sub','',false);
do $$ begin
  assert (select count(*) from products) = 9, 'anon should see 9 active products (hidden one excluded)';
  assert (select count(*) from orders) = 0, 'anon sees no orders';
  assert (select count(*) from settings) = 1;
  assert not am_i_admin();
end $$;
select pg_temp.fails($$insert into products(name,category,price) values ('x','tshirts',1)$$, 'row-level security');
select pg_temp.fails($$update products set price=1$$, 'Nothing') where false;   -- (update just affects 0 rows under RLS; checked below)
do $$ declare n int; begin update products set price=1; get diagnostics n = row_count; assert n=0, 'anon update must touch 0 rows'; end $$;
select pg_temp.fails($$insert into orders(ref,name,phone,city,address,items,subtotal,delivery,total) values ('X','a','b','c','d','[]',1,1,1)$$, 'row-level security');
select pg_temp.fails($$select * from admins$$, 'permission denied');
select pg_temp.fails($$select set_order_status('x','shipped')$$, 'permission denied');

-- ===== placing orders =====
do $$ declare r jsonb; begin
  r := place_order('{"name":"Ali Khan","phone":"0324 1995778","city":"Lahore","address":"House 1, Street 2, Lahore","items":[{"id":"tee-001","size":"M","qty":2},{"id":"wat-001","qty":1}]}');
  assert (r->>'subtotal')::int = 1499*2+1799, 'subtotal'; assert (r->>'total')::int = 1499*2+1799+250, 'total incl delivery';
  assert (r->>'ref') like 'FC-%';
  assert jsonb_array_length(r->'lines') = 2;
end $$;
reset role;
do $$ begin
  assert (select stock from products where id='tee-001') = 23, 'tee stock decremented';
  assert (select stock from products where id='wat-001') = 11, 'watch stock decremented';
  assert (select status from orders) = 'pending';
end $$;
set role anon;
select pg_temp.fails($$select place_order('{"name":"Ali Khan","phone":"0324 1995778","city":"L","address":"House 1, Street 2","items":[{"id":"tee-001","qty":1}]}')$$, 'choose a size');
select pg_temp.fails($$select place_order('{"name":"Ali Khan","phone":"0324 1995778","city":"L","address":"House 1, Street 2","items":[{"id":"hid-1","qty":1}]}')$$, 'no longer available');
select pg_temp.fails($$select place_order('{"name":"Ali Khan","phone":"0324 1995778","city":"L","address":"House 1, Street 2","items":[{"id":"nope","qty":1}]}')$$, 'no longer available');
select pg_temp.fails($$select place_order('{"name":"Ali Khan","phone":"0324 1995778","city":"L","address":"House 1, Street 2","items":[{"id":"wat-001","qty":99}]}')$$, 'Invalid item');
select pg_temp.fails($$select place_order('{"name":"Ali Khan","phone":"0324 1995778","city":"L","address":"House 1, Street 2","items":[{"id":"wat-001","qty":-1}]}')$$, 'Invalid item');
select pg_temp.fails($$select place_order('{"name":"Ali Khan","phone":"0324 1995778","city":"L","address":"House 1, Street 2","items":[{"id":"wat-001","qty":"3"}]}')$$, 'Invalid item');
select pg_temp.fails($$select place_order('{"name":"Ali Khan","phone":"123","city":"L","address":"House 1, Street 2","items":[{"id":"wat-001","qty":1}]}')$$, 'valid Pakistani');
select pg_temp.fails($$select place_order('{"name":"A","phone":"0324 1995778","city":"L","address":"House 1, Street 2","items":[{"id":"wat-001","qty":1}]}')$$, 'full name');
select pg_temp.fails($$select place_order('{"name":"Ali Khan","phone":"0324 1995778","city":"L","address":"short","items":[{"id":"wat-001","qty":1}]}')$$, 'complete delivery address');
select pg_temp.fails($$select place_order('{"name":"Ali Khan","phone":"0324 1995778","city":"L","address":"House 1, Street 2","items":[]}')$$, 'cart is empty');
select pg_temp.fails($$select place_order('{"name":"Ali Khan","phone":"0324 1995778","city":"L","address":"House 1, Street 2"}')$$, 'cart is empty');
select pg_temp.fails($$select place_order('{"name":"Ali Khan","phone":"0324 1995778","city":"L","address":"House 1, Street 2","items":[{"id":"tee-001","size":"S","qty":20},{"id":"tee-001","size":"M","qty":20}]}')$$, 'only');
-- atomic rollback: first item fine, second fails => first item's stock must be untouched
select pg_temp.fails($$select place_order('{"name":"Sara","phone":"0300 1234567","city":"Lahore","address":"House 9, Street 9","items":[{"id":"lck-001","qty":1},{"id":"wat-001","qty":15}]}')$$, 'only');
reset role;
do $$ begin assert (select stock from products where id='lck-001') = 40, 'rollback left lck-001 untouched'; assert (select count(*) from orders)=1; end $$;
-- same product twice is counted together; price comes from the database
set role anon;
do $$ declare r jsonb; begin
  r := place_order('{"name":"Sara","phone":"0300 1234567","city":"Lahore","address":"House 9, Street 9","items":[{"id":"wat-002","qty":4,"price":1},{"id":"wat-002","qty":4}]}');
  assert (r->'lines'->0->>'price')::int = 1999, 'price from db'; end $$;
select pg_temp.fails($$select place_order('{"name":"Sara","phone":"0300 1234567","city":"Lahore","address":"House 9, Street 9","items":[{"id":"wat-002","qty":3}]}')$$, 'only 2 left');
-- per-phone rate limit (5/hour)
do $$ begin for i in 1..4 loop perform place_order('{"name":"Spam","phone":"0333 0000000","city":"X","address":"Somewhere 123","items":[{"id":"lck-002","qty":1}]}'); end loop; end $$;
do $$ begin perform place_order('{"name":"Spam","phone":"+92 333 0000000","city":"X","address":"Somewhere 123","items":[{"id":"lck-002","qty":1}]}'); end $$;
select pg_temp.fails($$select place_order('{"name":"Spam","phone":"03330000000","city":"X","address":"Somewhere 123","items":[{"id":"lck-002","qty":1}]}')$$, 'Too many orders');

-- ===== a logged-in non-admin =====
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-0000000000bb',false); set role authenticated;
do $$ begin assert not am_i_admin(); assert (select count(*) from orders)=0, 'non-admin cannot read orders'; end $$;
select pg_temp.fails($$select set_order_status('x','shipped')$$, 'Not allowed');
select pg_temp.fails($$insert into products(name,category,price) values ('x','tshirts',1)$$, 'row-level security');
do $$ declare n int; begin delete from products; get diagnostics n=row_count; assert n=0; end $$;

-- ===== admin =====
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-0000000000aa',false);
do $$ declare ref1 text; r jsonb; begin
  assert am_i_admin();
  assert (select count(*) from products)=10, 'admin sees hidden product too';
  assert (select count(*) from orders)>=7;
  select ref into ref1 from orders where name='Ali Khan';
  perform set_order_status(ref1,'confirmed'); perform set_order_status(ref1,'shipped');
  assert (select status from orders where ref=ref1)='shipped';
  perform set_order_status(ref1,'cancelled');
  assert (select stock from products where id='tee-001')=25 and (select stock from products where id='wat-001')=12, 'cancel restored stock';
  perform set_order_status(ref1,'cancelled');
  assert (select stock from products where id='tee-001')=25, 'double cancel does not restore twice';
  begin perform set_order_status(ref1,'pending'); assert false,'should not reopen'; exception when others then assert sqlerrm like '%reopened%', sqlerrm; end;
  begin perform set_order_status(ref1,'weird'); assert false; exception when others then assert sqlerrm like '%Invalid status%', sqlerrm; end;
  begin perform set_order_status('FC-NOPE','shipped'); assert false; exception when others then assert sqlerrm like '%not found%', sqlerrm; end;
  insert into products(name,category,price,stock,sizes,images) values ('Test','watches',500,3,'{}','{https://x.test/a.jpg}');
  update products set price=600 where name='Test'; assert (select price from products where name='Test')=600;
  delete from products where name='Test';
  update settings set delivery_charge=300; r := (select delivery_charge from settings); assert r::text::int=300;
end $$;
select pg_temp.fails($$insert into products(name,category,price,images) values ('Bad','watches',5,'{javascript:alert(1)}')$$, 'violates check');
select pg_temp.fails($$insert into products(name,category,price) values ('Bad','shoes',5)$$, 'violates check');
select pg_temp.fails($$insert into products(name,category,price,stock) values ('Bad','watches',5,-1)$$, 'violates check');
reset role;
\echo ALL SQL TESTS PASSED
