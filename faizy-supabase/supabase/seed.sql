-- Optional: sample products (placeholders). Run once in the SQL Editor.
insert into public.products (id, name, category, description, price, stock, sizes, featured, color, art) values
 ('tee-001','Brooklyn Oversized Tee','tshirts','Oversized black graphic tee (sample).',1499,25,'{S,M,L,XL}',true,'#15181d','tee'),
 ('tee-002','Essentials Plain Tee','tshirts','Plain off-white tee (sample).',1299,30,'{S,M,L,XL}',true,'#e9e6df','tee'),
 ('tee-003','Sand Oversized Tee','tshirts','Sand-tone oversized tee (sample).',1399,18,'{M,L,XL}',false,'#cdb590','tee'),
 ('wat-001','Classic Black Watch','watches','Black dial watch (sample).',1799,12,'{}',true,'#111111','watch'),
 ('wat-002','Blue Dial Watch','watches','Blue dial leather strap (sample).',1999,10,'{}',true,'#1f3b73','watch'),
 ('lck-001','Minimal Locket','lockets','Silver-tone oval locket (sample).',699,40,'{}',true,'#c9ced6','locket'),
 ('lck-002','Cuban Chain','lockets','Silver-tone chain (sample).',899,22,'{}',false,'#b7bcc4','chain'),
 ('cmb-001','Tee + Watch Combo','combos','Tee with Classic Black Watch (sample bundle).',2999,8,'{S,M,L,XL}',true,'#15181d','combo'),
 ('cmb-002','Locket + Chain Combo','combos','Minimal Locket with Cuban Chain (sample bundle).',1399,15,'{}',false,'#c9ced6','locket')
on conflict (id) do nothing;
