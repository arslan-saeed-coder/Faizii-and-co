/* Small helpers + product artwork placeholder */
function art(p){if(p.images&&p.images[0])return '<img src="'+esc(p.images[0])+'" alt="" style="width:100%;height:100%;object-fit:cover">';var c=p.color,s='#c9ced6';
var t={tee:'<path d="M30 20l22-8c4 8 20 8 24 0l22 8 14 24-18 8v62H34V52L16 44z" fill="'+c+'" stroke="'+s+'" stroke-width="1.5"/>',
watch:'<rect x="46" y="4" width="28" height="40" rx="6" fill="#222"/><rect x="46" y="76" width="28" height="40" rx="6" fill="#222"/><circle cx="60" cy="60" r="28" fill="'+c+'" stroke="'+s+'" stroke-width="3"/><path d="M60 60V42M60 60l12 6" stroke="#fff" stroke-width="2.5" stroke-linecap="round"/>',
locket:'<path d="M20 6c10 50 30 60 40 60S90 56 100 6" fill="none" stroke="'+s+'" stroke-width="2"/><ellipse cx="60" cy="86" rx="22" ry="30" fill="'+c+'" stroke="#fff" stroke-width="1.5"/><ellipse cx="60" cy="86" rx="14" ry="21" fill="none" stroke="#888"/>',
chain:'<g fill="none" stroke="'+s+'" stroke-width="5">'+[0,1,2,3,4].map(function(i){return '<ellipse cx="'+(24+i*18)+'" cy="'+(40+Math.sin(i*1.3)*16+i*4)+'" rx="12" ry="7" transform="rotate('+(i%2?30:-30)+' '+(24+i*18)+' '+(40+Math.sin(i*1.3)*16+i*4)+')"/>'}).join('')+'</g>'};
if(p.art==='combo')return '<svg viewBox="0 0 120 120"><g transform="scale(.6) translate(-8 20)">'+t.tee+'</g><g transform="translate(58 50) scale(.5)">'+t.watch+'</g></svg>';
return '<svg viewBox="0 0 120 120">'+t[p.art]+'</svg>'}
function money(n){return 'Rs. '+n.toLocaleString('en-PK')}
function $(s,e){return(e||document).querySelector(s)}
function esc(s){return String(s).replace(/[&<>"]/g,function(c){return{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]})}
function byId(id){return PRODUCTS.filter(function(p){return p.id===id})[0]}

