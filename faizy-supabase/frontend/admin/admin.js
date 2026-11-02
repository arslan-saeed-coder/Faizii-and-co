var ST=['pending','confirmed','shipped','delivered','cancelled'],CATS=['tshirts','watches','lockets','combos'],ARTS=['tee','watch','locket','chain','combo'];
var sb=(SB.url&&SB.anonKey)?supabase.createClient(SB.url,SB.anonKey):null;
var PL=[],OF='',EDIT=null,F=document.querySelector('#pf');
function $(s){return document.querySelector(s)}
function esc(s){return String(s==null?'':s).replace(/[&<>"']/g,function(c){return{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]})}
function money(n){return 'Rs. '+Number(n).toLocaleString('en-PK')}
function msg(e){return(e&&e.message)||'Something went wrong.'}
function check(r){if(r.error)throw r.error;return r.data}
function toggle(on){$('#login').classList.toggle('hide',on);$('#main').classList.toggle('hide',!on);$('#out').classList.toggle('hide',!on);if(on){loadProducts();loadOrders()}}
function boot(){if(!sb){$('#lerr').textContent='Set SB.url and SB.anonKey in js/supabase-config.js';return}
sb.auth.getSession().then(function(r){if(!r.data.session)return toggle(false);
return sb.rpc('am_i_admin').then(function(a){if(a.data===true)return toggle(true);return sb.auth.signOut().then(function(){$('#lerr').textContent='This account is not an admin.';toggle(false)})})})}
$('#out').onclick=function(){sb.auth.signOut().then(function(){toggle(false)})};
$('#login').onsubmit=function(e){e.preventDefault();$('#lerr').textContent='';if(!sb)return boot();
sb.auth.signInWithPassword({email:$('#em').value.trim(),password:$('#pw').value}).then(function(r){if(r.error)throw r.error;$('#pw').value='';boot()}).catch(function(x){$('#lerr').textContent=msg(x)})};
document.querySelectorAll('.tabs button').forEach(function(b){b.onclick=function(){document.querySelectorAll('.tabs button').forEach(function(x){x.classList.toggle('on',x===b)});$('#t-products').classList.toggle('hide',b.dataset.t!=='products');$('#t-orders').classList.toggle('hide',b.dataset.t!=='orders')}});

/* ---------- products ---------- */
function thumb(p){return p.images&&p.images[0]?'<img src="'+esc(p.images[0])+'" alt="">':'<svg viewBox="0 0 120 120"><rect x="30" y="30" width="60" height="60" rx="8" fill="'+esc(p.color)+'" stroke="#c9ced6"/></svg>'}
function loadProducts(){sb.from('products').select('*').order('created_at').then(check).then(function(l){PL=l;
$('#ptb').innerHTML=PL.map(function(p,i){return '<tr><td><div class="th">'+thumb(p)+'</div></td><td><b>'+esc(p.name)+'</b><div class="cat-l">'+esc(p.category)+(p.sizes.length?' · '+esc(p.sizes.join('/')):'')+'</div></td><td><input type="number" min="0" value="'+p.price+'" onchange="quick('+i+',\'price\',this.value)"></td><td><input type="number" min="0" value="'+p.stock+'" onchange="quick('+i+',\'stock\',this.value)">'+(p.stock<=0?' <span class="st-cancelled">sold out</span>':'')+'</td><td><input type="checkbox" '+(p.active?'checked':'')+' onchange="quick('+i+',\'active\',this.checked)"></td><td><input type="checkbox" '+(p.featured?'checked':'')+' onchange="quick('+i+',\'featured\',this.checked)"></td><td><button class="mini" onclick="edit('+i+')">Edit</button><button class="mini d" onclick="del('+i+')">Delete</button></td></tr>'}).join('')||'<tr><td colspan="7">No products yet.</td></tr>'}).catch(function(e){alert(msg(e))})}
function quick(i,k,v){var u={};u[k]=(k==='price'||k==='stock')?Math.max(0,parseInt(v||'0',10)||0):v;
sb.from('products').update(u).eq('id',PL[i].id).then(check).then(loadProducts).catch(function(e){alert(msg(e));loadProducts()})}
function del(i){if(confirm('Delete "'+PL[i].name+'" permanently? (Untick Visible instead if unsure.)'))sb.from('products').delete().eq('id',PL[i].id).then(check).then(loadProducts).catch(function(e){alert(msg(e))})}
function openForm(p){EDIT=p?p.id:null;$('#pft').textContent=p?'Edit product':'Add product';$('#perr').textContent='';var d=p||{name:'',category:'tshirts',description:'',price:'',stock:'',sizes:[],images:[],featured:false,active:true,art:'tee',color:'#15181d'};
['name','category','description','price','stock','art','color'].forEach(function(k){F.elements[k].value=d[k]});F.elements.sizes.value=d.sizes.join(', ');F.elements.images.value=d.images.join('\n');F.elements.featured.checked=d.featured;F.elements.active.checked=d.active;F.classList.remove('hide');F.scrollIntoView({behavior:'smooth'})}
function edit(i){openForm(PL[i])}
$('#add').onclick=function(){openForm(null)};$('#cancel').onclick=function(){F.classList.add('hide')};
F.onsubmit=function(e){e.preventDefault();var er=$('#perr'),f=F.elements;er.textContent='';
var p={name:f.name.value.trim(),category:f.category.value,description:f.description.value.trim().slice(0,1000),price:parseInt(f.price.value,10),stock:parseInt(f.stock.value,10),sizes:f.sizes.value.split(',').map(function(s){return s.trim().slice(0,6)}).filter(Boolean).slice(0,10),images:f.images.value.split('\n').map(function(s){return s.trim()}).filter(Boolean).slice(0,8),featured:f.featured.checked,active:f.active.checked,art:f.art.value,color:f.color.value};
if(!p.name||isNaN(p.price)||isNaN(p.stock)||p.price<0||p.stock<0){er.textContent='Name, price and stock are required (no negatives).';return}
if(CATS.indexOf(p.category)<0||ARTS.indexOf(p.art)<0){er.textContent='Invalid category.';return}
if(p.images.some(function(u){return !/^https:\/\/[^\s'"<>]+$/.test(u)})){er.textContent='Photo links must start with https://';return}
(EDIT?sb.from('products').update(p).eq('id',EDIT):sb.from('products').insert(p)).then(check).then(function(){F.classList.add('hide');loadProducts()}).catch(function(x){er.textContent=msg(x)})};
$('#up').onchange=function(){var fs=Array.prototype.slice.call(this.files),inp=this,er=$('#perr');er.textContent='Uploading…';
fs.reduce(function(pr,f){return pr.then(function(){if(!/^image\/(jpeg|png|webp)$/.test(f.type)||f.size>3000000)throw new Error('Only JPG/PNG/WEBP up to 3 MB.');
var ext={'image/jpeg':'.jpg','image/png':'.png','image/webp':'.webp'}[f.type],name=Date.now().toString(36)+Math.random().toString(36).slice(2,8)+ext;
return sb.storage.from(SB.bucket).upload(name,f,{contentType:f.type,upsert:false}).then(function(r){if(r.error)throw r.error;var u=sb.storage.from(SB.bucket).getPublicUrl(name).data.publicUrl;F.elements.images.value=(F.elements.images.value.trim()?F.elements.images.value.trim()+'\n':'')+u})})},Promise.resolve()).then(function(){er.textContent='';inp.value=''}).catch(function(x){er.textContent=msg(x)})};

/* ---------- orders ---------- */
function wa(phone){var d=String(phone).replace(/\D/g,'');if(d.charAt(0)==='0')d='92'+d.slice(1);return d}
function loadOrders(){sb.from('orders').select('*').order('created_at',{ascending:false}).limit(200).then(check).then(function(all){
var n=all.filter(function(o){return o.status==='pending'}).length;$('#pend').textContent=n?'('+n+' pending)':'';
$('#of').innerHTML=[['','All']].concat(ST.map(function(s){return[s,s]})).map(function(a){return '<button class="f'+(OF===a[0]?' on':'')+'" onclick="OF=\''+a[0]+'\';loadOrders()">'+a[1]+'</button>'}).join('');
var l=OF?all.filter(function(o){return o.status===OF}):all;
$('#ol').innerHTML=l.map(function(o){var it=o.items||[];
return '<div class="oc"><div class="h"><div><b>'+esc(o.ref)+'</b> <span class="cat-l">'+new Date(o.created_at).toLocaleString()+'</span></div><select onchange="setSt(\''+esc(o.ref)+'\',this.value)">'+ST.map(function(s){return '<option'+(s===o.status?' selected':'')+'>'+s+'</option>'}).join('')+'</select></div>'
+'<div><b>'+esc(o.name)+'</b> · '+esc(o.phone)+' · '+esc(o.city)+'</div><div class="cat-l">'+esc(o.address)+(o.notes?' — Notes: '+esc(o.notes):'')+'</div>'
+'<div style="margin:8px 0">'+it.map(function(x){return esc(x.name)+(x.size?' ('+esc(x.size)+')':'')+' × '+x.qty+' = '+money(x.sub)}).join('<br>')+'</div>'
+'<div><b>Total '+money(o.total)+'</b> <span class="cat-l">(incl. delivery '+money(o.delivery)+')</span> · <a href="https://wa.me/'+wa(o.phone)+'" target="_blank" rel="noopener" style="text-decoration:underline">WhatsApp customer</a></div></div>'}).join('')||'<p class="cat-l">No orders yet.</p>'}).catch(function(e){alert(msg(e))})}
function setSt(ref,s){sb.rpc('set_order_status',{p_ref:ref,p_status:s}).then(check).then(function(){loadOrders();loadProducts()}).catch(function(e){alert(msg(e));loadOrders()})}
boot();
