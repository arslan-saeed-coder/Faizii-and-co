/* Start-up */
save();buildSoc();
$('#app').innerHTML='<div class="w page" style="color:var(--mut)">Loading…</div>';
loadAll().then(route).catch(function(){$('#app').innerHTML='<div class="w page"><h2>Store is temporarily unavailable</h2><p style="color:var(--mut);margin-top:8px">Please try again in a moment, or message us on WhatsApp.</p></div>'});
