/* Talks to Supabase: products/settings are read from the database, orders go through the place_order() SQL function. */
var PRODUCTS=[];
var sb=(SB.url&&SB.anonKey)?supabase.createClient(SB.url,SB.anonKey):null;
function rowToProduct(r){return{id:r.id,name:r.name,category:r.category,description:r.description||'',price:r.price,stock:r.stock,images:r.images||[],sizes:r.sizes||[],featured:!!r.featured,active:r.active!==false,color:r.color||'#15181d',art:r.art||'tee'}}
/* views.js calls api('/api/orders',...) — keep that shape, route it to Supabase */
function api(path,opt){if(path!=='/api/orders')return Promise.reject(new Error('Unsupported'));
if(!sb)return Promise.reject(new Error('Supabase is not configured'));
return sb.rpc('place_order',{p:opt.body}).then(function(r){if(r.error){var e=new Error(r.error.message);e.status=(r.error.code==='P0001')?422:500;throw e}return r.data},function(x){x.status=500;throw x})}
function loadAll(){if(!sb)return Promise.reject(new Error('Set SB.url and SB.anonKey in js/supabase-config.js'));
return Promise.all([sb.from('settings').select('delivery_charge,whatsapp').eq('id',1).single(),sb.from('products').select('*').eq('active',true).order('created_at')]).then(function(r){
if(r[0].error)throw r[0].error;if(r[1].error)throw r[1].error;
WA=String(r[0].data.whatsapp).replace(/\D/g,'');DELIVERY=r[0].data.delivery_charge;PRODUCTS=r[1].data.map(rowToProduct);cart=cart.filter(function(i){return byId(i.id)});save()})}
