/* Brand / photo slots / social links / categories */
/* ===== PHOTO SLOTS — paste image URLs (or data URIs) to fill the empty photo spots ===== */
var HERO_IMG='',BAN_IMG={tshirts:'',acc:''};
/* ===== SOCIAL LINKS — paste your profile URLs; empty = shown but not clickable ===== */
var SOCIAL={tiktok:'',instagram:'',facebook:'',youtube:''};
function slot(u,l,c){return u?'<div class="'+c+'" style="background:url(\''+esc(u)+'\') center/cover"></div>':'<div class="'+c+' ph-slot"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="9" cy="11" r="2"/><path d="M21 16l-5-5-8 8"/></svg><span>'+l+'</span></div>'}
var CATS={tshirts:'T-Shirts',watches:'Watches',lockets:'Lockets & Chains',combos:'Combos'};
var WA='923241995778',DELIVERY=250; /* WA and DELIVERY are loaded from the Supabase `settings` table at startup (these are only fallbacks) */

