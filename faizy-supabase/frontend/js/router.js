/* Hash router */
/* ===== ROUTER ===== */
function route(){var h=location.hash||'#/',p=h.slice(2).split('?')[0].split('/'),app=$('#app'),c='';
document.querySelectorAll('nav a').forEach(function(a){a.classList.toggle('on',a.dataset.c===(p[0]==='shop'?(p[1]||'all'):p[0]===''?'':'x'))});
$('#nav').classList.remove('open');
if(p[0]==='shop')app.innerHTML=shop(p[1]);else if(p[0]==='search')app.innerHTML=searchView(decodeURIComponent(p[1]||''));else if(p[0]==='cart')app.innerHTML=cartView();else if(p[0]==='order'){var b=h.indexOf('buy=1')>-1;app.innerHTML=orderView(b);bindOrder(b)}else app.innerHTML=home();
window.scrollTo(0,0)}
window.addEventListener('hashchange',route);$('#bg').onclick=function(){$('#nav').classList.toggle('open')};

