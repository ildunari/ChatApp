// Lightweight Tool Card renderer appended to the #artifacts container.
// Safe to include alongside existing app.bundle.js
(function(){
  const root = document.getElementById('artifacts');
  if (!root) return;
  function esc(s){return String(s==null?'':s).replace(/[&<>]/g, c=>({"&":"&amp;","<":"&lt;",">":"&gt;"}[c]))}
  function pane(title, body){
    const p = document.createElement('div');
    p.className = 'pane';
    p.innerHTML = `<div style="font:12px -apple-system; color:var(--text2); margin-bottom:6px">${esc(title)}</div><pre>${esc(body||'')}</pre>`;
    return p;
  }
  function ensureStyles(){
    if (document.getElementById('toolcard-styles')) return;
    const css = document.createElement('style');
    css.id = 'toolcard-styles';
    css.textContent = `:root{--bg:#F7F4EF;--surface:rgba(255,255,255,0.86);--surfaceHi:#FFFFFF;--text:rgba(0,0,0,0.90);--text2:rgba(0,0,0,0.60);--borderSoft:rgba(0,0,0,0.06);--accent:#DA7756;--codeBg:rgba(0,0,0,0.03);--radiusS:10px;--radiusM:14px;--radiusL:20px}
      .toolcard{border-radius:var(--radiusL);box-shadow:0 1px 3px rgba(0,0,0,.1);overflow:hidden;border:1px solid var(--borderSoft);background:var(--surface);margin:12px}
      .toolhead{display:flex;align-items:center;gap:12px;padding:12px 14px;cursor:pointer}
      .status{width:8px;height:8px;border-radius:50%;background:var(--text2)}
      .status.running{background:var(--accent)}.status.success{background:#00B35F}.status.error{background:#D7263D}
      .chev{margin-left:auto;color:var(--text2)}
      .divider{height:1px;background:var(--borderSoft)}
      .toolbody{display:none;background:var(--surfaceHi)}
      .toolbody.open{display:flex}
      .pane{flex:1;min-height:80px;max-height:260px;overflow:auto;padding:10px 12px}
      .pane pre{background:var(--codeBg);border-radius:var(--radiusS);padding:12px;font:13px/1.4 ui-monospace,SFMono-Regular,Menlo,Monaco,monospace}`;
    document.head.appendChild(css);
  }
  function appendToolCard({title, subtitle, status, request, response, open}){
    ensureStyles();
    const card = document.createElement('div'); card.className='toolcard';
    const head = document.createElement('div'); head.className='toolhead';
    const dot = document.createElement('div'); dot.className='status ' + (status||'idle'); head.appendChild(dot);
    const titleEl = document.createElement('div');
    titleEl.innerHTML = `<span style="font-weight:600">${esc(title||'tool')}</span>` + (subtitle?`&nbsp;<span style="color:var(--text2)">${esc(subtitle)}</span>`:'');
    head.appendChild(titleEl);
    const chev = document.createElement('div'); chev.className='chev'; chev.textContent='▾'; head.appendChild(chev);
    card.appendChild(head);
    const divider = document.createElement('div'); divider.className='divider'; card.appendChild(divider);
    const body = document.createElement('div'); body.className='toolbody'; card.appendChild(body);
    if (request!=null) body.appendChild(pane('Request', request));
    if (response!=null) body.appendChild(pane('Response', response));
    head.addEventListener('click', ()=>{ const isOpen = body.classList.toggle('open'); chev.textContent = isOpen ? '▴' : '▾';});
    if (open) { body.classList.add('open'); chev.textContent='▴'; }
    root.appendChild(card);
    window.scrollTo(0, document.body.scrollHeight);
  }
  window.ToolCard = { append: appendToolCard };
})();

