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

// Une courte piste silencieuse, jouée au clic, "débloque" l'audio pour la fiche produit
const SILENT = "data:audio/wav;base64,UklGRsQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YaAAAACAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA";
function audioBox(p, au) {
  if (!p.audio_url) return el("p", {text: p.description || ""});
  au.preload = "auto"; au.src = p.audio_url;
  const PLAY = '<svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>', PAUSE = '<svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M7 5h4v14H7zM13 5h4v14h-4z"/></svg>';
  const b = el("button", {class:"play", type:"button", "aria-label":"Écouter la présentation du produit"}); b.innerHTML = PLAY;
  const lab = el("span", {class:"lab", text:"Écouter la présentation"}), bar = el("i"), track = el("span", {class:"bar"}, bar);
  b.onclick = () => au.paused ? au.play() : au.pause();
  au.onplay = () => { b.innerHTML = PAUSE; lab.textContent = "Pause"; b.classList.remove("pulse"); };
  au.onpause = () => { b.innerHTML = PLAY; lab.textContent = au.currentTime ? "Reprendre" : "Écouter la présentation"; };
  au.ontimeupdate = () => { bar.style.width = (au.duration ? au.currentTime / au.duration * 100 : 0) + "%"; };
  au.onended = () => { b.innerHTML = PLAY; lab.textContent = "Réécouter"; bar.style.width = "0"; };
  // lecture automatique ; si le navigateur la bloque, elle démarre au premier toucher
  const EV = ["pointerup", "keydown", "click"];
  const unlock = ev => { if (b.contains(ev.target)) return; au.play().catch(() => {}); };
  au.addEventListener("play", () => EV.forEach(e => removeEventListener(e, unlock, true)));
  au.play().catch(() => {
    lab.textContent = "Touchez pour écouter"; b.classList.add("pulse");
    EV.forEach(e => addEventListener(e, unlock, true));
  });
  document.addEventListener("visibilitychange", () => { if (document.hidden) au.pause(); });
  addEventListener("pagehide", () => au.pause());
  return el("div", {class:"player"}, b, el("div", {class:"pl"}, lab, track));
}
function renderProduct(p, box, au) {
  box.replaceChildren();
  document.title = p.name + " · Zayta Cosmétique";
  const f = el("form", {class:"order", id:"order"});
  f.innerHTML = '<h2 style="font-size:32px;margin:0">Commander</h2>'
    + '<label>Nom complet<input name="customer_name" required autocomplete="name"></label>'
    + '<label>Téléphone<input name="phone" required inputmode="tel" autocomplete="tel" pattern="0[5-7][0-9]{8}" placeholder="0612345678"></label>'
    + '<label>Ville<input name="city" required autocomplete="address-level2"></label>'
    + '<label>Adresse de livraison<textarea name="address" required rows="2"></textarea></label>'
    + '<label>Quantité<input name="quantity" type="number" min="1" max="20" value="1" required></label>'
    + '<input class="hp" name="site" tabindex="-1" autocomplete="off" aria-hidden="true">'
    + '<button class="btn" type="submit">Commander · paiement à la livraison</button>'
    + '<p class="note">Vous payez en espèces à la réception. Nous vous appelons pour confirmer.</p><div id="out" role="status"></div>';
  f.onsubmit = async e => {
    e.preventDefault();
    const d = Object.fromEntries(new FormData(f)), out = f.querySelector("#out"), b = f.querySelector("button");
    if (d.site) return;
    b.disabled = true;
    const {error} = await sb.from("orders").insert({product_id:p.id, customer_name:d.customer_name.trim(), phone:d.phone, city:d.city.trim(), address:d.address.trim(), quantity:+d.quantity});
    if (error) { b.disabled = false; out.className = "msg err"; out.textContent = "La commande n'a pas été envoyée. Vérifiez vos informations et réessayez."; return; }
    f.replaceChildren(el("div", {class:"msg", text:"Merci ! Votre commande est enregistrée. Nous vous appelons très vite pour la confirmer."}));
  };
  box.append(el("div", {class:"ph"}, el("img", {src:imgFor(p), alt:p.name})),
    el("div", {}, el("h1", {text:p.name}), el("div", {class:"price", text:mad(p.price)}), audioBox(p, au), f));
  document.querySelectorAll(".sticky").forEach(x => x.remove());
  document.body.append(el("a", {class:"sticky", href:"#order"}, el("span", {text:"Commander"}), el("b", {text:mad(p.price)})));
}
