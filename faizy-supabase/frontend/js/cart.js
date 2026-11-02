/* Cart + Buy Now state (cart is saved in localStorage) */
/* ===== CART (persisted) ===== */
var cart=[];try{cart=JSON.parse(localStorage.getItem('zq_cart')||'[]')}catch(e){}
var buyNow=null,sel={},submitting=false;
function save(){try{localStorage.setItem('zq_cart',JSON.stringify(cart))}catch(e){}$('#cc').textContent=cart.reduce(function(a,i){return a+i.qty},0)}
function toast(m){var t=document.createElement('div');t.className='toast';t.textContent=m;document.body.appendChild(t);setTimeout(function(){t.remove()},1600)}
function pick(id){var p=byId(id);if(p.sizes.length&&!sel[id]){toast('Please select a size');return null}return{id:id,size:sel[id]||'',qty:1}}
function addCart(id){var it=pick(id);if(!it)return;var f=cart.filter(function(c){return c.id===id&&c.size===it.size})[0];if(f)f.qty++;else cart.push(it);save();toast('Added to cart');location.hash='#/cart'}
function buy(id){var it=pick(id);if(!it)return;buyNow=[it];location.hash='#/order?buy=1'}
function setSize(id,s){sel[id]=s;route()}
function qty(i,d){cart[i].qty=Math.max(1,cart[i].qty+d);save();route()}
function rm(i){cart.splice(i,1);save();route()}

