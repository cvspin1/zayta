const sb = supabase.createClient(CFG.url, CFG.key);
const mad = n => new Intl.NumberFormat("fr-MA", {style:"currency", currency:"MAD", maximumFractionDigits:0}).format(n);
const $ = s => document.querySelector(s);
function el(tag, attrs = {}, ...kids) {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) k === "text" ? e.textContent = v : e.setAttribute(k, v);
  kids.forEach(k => e.append(k));
  return e;
}

/* ---------- Suivi des visiteurs (léger, sans cookies) ---------- */
const sid = (() => {
  try { let s = localStorage.getItem("zsid"); if (!s) { s = (crypto.randomUUID ? crypto.randomUUID() : Date.now() + "-" + Math.random().toString(36).slice(2)); localStorage.setItem("zsid", s); } return s; }
  catch { return "x" + Math.random().toString(36).slice(2); }
})();
function track(type, product_id) {
  try {
    sb.from("events").insert({session_id: sid, type, product_id: product_id || null,
      page: location.pathname.split("/").pop() || "index.html",
      device: innerWidth < 760 ? "mobile" : "desktop"}).then(() => {}, () => {});
  } catch {}
}

/* ---------- WhatsApp ---------- */
const waLink = msg => "https://wa.me/" + CFG.wa + (msg ? "?text=" + encodeURIComponent(msg) : "");
function addWhatsApp(msg) {
  const a = el("a", {class:"wa", href:waLink(msg), target:"_blank", rel:"noopener", "aria-label":"Écrire sur WhatsApp"});
  a.innerHTML = '<svg viewBox="0 0 32 32" width="26" height="26" aria-hidden="true"><path fill="#fff" d="M16 3a13 13 0 0 0-11 19.900L3 29l6.300-1.900A13 13 0 1 0 16 3zm-4.200 7c.3 0 .6 0 .8.600l1 2.300c.1.300 0 .6-.2.800l-.7.900c-.2.200-.2.500 0 .8a9 9 0 0 0 4 3.400c.3.100.6.100.8-.1l.9-1.100c.2-.3.500-.3.800-.2l2.400 1.100c.3.100.4.400.4.700-.1 1.200-1.200 2.100-2.400 2.200-3.400.2-9-3.400-10-8.200-.2-1.300.7-2.500 2-3.200z"/></svg><span>WhatsApp</span>';
  a.onclick = () => track("whatsapp_click");
  document.body.append(a);
}

/* ---------- Effet 3D (inclinaison qui suit le doigt / la souris) ---------- */
function tilt(node, max = 12) {
  if (matchMedia("(prefers-reduced-motion: reduce)").matches) return;
  node.classList.add("t3d");
  let raf;
  const move = e => {
    const r = node.getBoundingClientRect();
    const x = (e.clientX - r.left) / r.width, y = (e.clientY - r.top) / r.height;
    cancelAnimationFrame(raf);
    raf = requestAnimationFrame(() => {
      node.style.setProperty("--ry", ((x - .5) * max * 2).toFixed(2) + "deg");
      node.style.setProperty("--rx", ((.5 - y) * max * 2).toFixed(2) + "deg");
      node.style.setProperty("--mx", (x * 100).toFixed(0) + "%");
      node.style.setProperty("--my", (y * 100).toFixed(0) + "%");
    });
  };
  const reset = () => { cancelAnimationFrame(raf); node.classList.remove("on"); node.style.setProperty("--rx", "0deg"); node.style.setProperty("--ry", "0deg"); };
  node.addEventListener("pointerenter", () => node.classList.add("on"));
  node.addEventListener("pointermove", move);
  node.addEventListener("pointerleave", reset);
  node.addEventListener("pointercancel", reset);
}
