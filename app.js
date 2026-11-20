const sb = supabase.createClient(CFG.url, CFG.key);
const mad = n => new Intl.NumberFormat("fr-MA", {style:"currency", currency:"MAD", maximumFractionDigits:0}).format(n);
const $ = s => document.querySelector(s);
function el(tag, attrs = {}, ...kids) {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) k === "text" ? e.textContent = v : e.setAttribute(k, v);
  kids.forEach(k => e.append(k));
  return e;
}
// Photo du produit : celle du dashboard, sinon une photo par défaut selon le nom
const imgFor = p => p.image_url || (/pack|duo|coffret/i.test(p.name) ? "pack.webp" : /huile/i.test(p.name) ? "assets/bottle.webp" : /beurre/i.test(p.name) ? "assets/jar.webp" : "assets/duo.jpg");
