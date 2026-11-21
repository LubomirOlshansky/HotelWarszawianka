// The site's own forms (F 2026-11-21, instead of Formspree's 50 a month): the beta signup and the
// feedback (the website's and the game's) arrive here, are stored in D1 (binding DB, table
// submissions, migrations/0001_init.sql) and mailed to the game's inbox (send_email binding EMAIL,
// Cloudflare Email Routing; best effort: the row is kept either way).
//
//   POST /api/signup    email, platform (iPhone | Android), lang, source
//   POST /api/feedback  message, email (optional), topic, platform, build, device, where, language, source
//   GET  /api/admin/submissions?kind=signup|feedback&limit=100&format=csv   Bearer ADMIN_TOKEN (secret)
//
// A form post (no JavaScript) gets a redirect back to the page; a fetch with Accept: application/json
// (the site, the game) gets {"ok":true}. Privacy: the IP is never stored, only a salted hash for the rate
// limit (5 an hour, 30 a day per hash, 400 an hour in all); the signup email is used only for the one
// beta email (the privacy page says so).

const FROM = "notify@aroundwarsaw.app";
const TO = "aroundwarsaw@gmail.com";
const ORIGINS = ["https://aroundwarsaw.app", "https://www.aroundwarsaw.app"];
const PLATFORMS = ["iPhone", "Android", "—"];
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const json = (obj, status = 200) => new Response(JSON.stringify(obj), {
  status, headers: { "content-type": "application/json", "cache-control": "no-store" },
});
const clip = (v, n) => String(v ?? "").replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f]/g, "").trim().slice(0, n);

async function sha(text) {
  const d = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return [...new Uint8Array(d)].map((b) => b.toString(16).padStart(2, "0")).join("").slice(0, 32);
}

async function fields(request) {
  const type = request.headers.get("content-type") || "";
  if (type.includes("application/json")) {
    const o = await request.json();
    return o && typeof o === "object" ? o : {};
  }
  const f = await request.formData();
  const o = {};
  for (const [k, v] of f.entries()) if (typeof v === "string") o[k] = v;
  return o;
}

export async function handleForm(request, env, ctx, url, EmailMessage) {
  if (request.method !== "POST") return new Response("POST only", { status: 405, headers: { allow: "POST" } });
  const origin = request.headers.get("origin");
  if (origin && !ORIGINS.includes(origin)) return json({ ok: false, error: "origin" }, 403);
  const wantsJson = (request.headers.get("accept") || "").includes("application/json");
  const kind = url.pathname === "/api/signup" ? "signup" : "feedback";

  let o;
  try { o = await fields(request); } catch (_) { return json({ ok: false, error: "body" }, 400); }

  const done = (status = 200) => {
    if (wantsJson) return json({ ok: status < 400 }, status);
    let back = "/";
    try { back = new URL(request.headers.get("referer") || "").pathname; } catch (_) { /* home */ }
    return new Response(null, { status: 303, headers: { location: `${back}?sent=${kind}#${kind === "signup" ? "beta" : "join"}`, "cache-control": "no-store" } });
  };

  if (clip(o._gotcha, 50) !== "") return done();  // the bots' honeypot: say yes, store nothing

  const email = clip(o.email, 200);
  const message = clip(o.message, 2000);
  const platform = PLATFORMS.includes(clip(o.platform, 10)) ? clip(o.platform, 10) : "—";
  if (email && !EMAIL.test(email)) return json({ ok: false, error: "email" }, 422);
  if (kind === "signup" && !email) return json({ ok: false, error: "email" }, 422);
  if (kind === "feedback" && message.length < 3) return json({ ok: false, error: "message" }, 422);

  const ip = request.headers.get("cf-connecting-ip") || "";
  const ipHash = await sha(ip + (env.IP_SALT || "aw"));
  const rate = await env.DB.prepare(
    `SELECT (SELECT COUNT(*) FROM submissions WHERE ip_hash = ?1 AND created_at > strftime('%Y-%m-%dT%H:%M:%SZ','now','-1 hour')) AS hour,
            (SELECT COUNT(*) FROM submissions WHERE ip_hash = ?1 AND created_at > strftime('%Y-%m-%dT%H:%M:%SZ','now','-1 day')) AS day,
            (SELECT COUNT(*) FROM submissions WHERE created_at > strftime('%Y-%m-%dT%H:%M:%SZ','now','-1 hour')) AS total`,
  ).bind(ipHash).first();
  if (rate && (rate.hour >= 5 || rate.day >= 30 || rate.total >= 400)) return json({ ok: false, error: "slow down" }, 429);

  const meta = {};
  for (const k of ["source", "build", "device", "where", "language"]) if (o[k] !== undefined) meta[k] = clip(o[k], 300);
  const lang = clip(o.lang || o.language, 10);
  const country = request.cf?.country || "";
  const topic = clip(o.topic, 40);

  const row = await env.DB.prepare(
    `INSERT INTO submissions (kind, email, platform, lang, message, topic, meta, country, ip_hash) VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9)`,
  ).bind(kind, email, platform, lang, message, topic, JSON.stringify(meta), country, ipHash).run();
  console.log(JSON.stringify({ event: "form", kind, platform, lang, country }));

  if (env.EMAIL) ctx.waitUntil(notify(env, EmailMessage, row.meta?.last_row_id, { kind, email, platform, lang, message, topic, meta, country }));
  return done();
}

function b64(text) {
  const bytes = new TextEncoder().encode(text);
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/(.{76})/g, "$1\r\n");
}

async function notify(env, EmailMessage, id, s) {
  try {
    const subject = s.kind === "signup"
      ? `Around Warsaw: beta signup (${s.platform})`
      : `Around Warsaw: feedback${s.topic ? " · " + s.topic : ""}`;
    const lines = [
      `kind: ${s.kind}`, `email: ${s.email || "-"}`, `platform: ${s.platform}`, `language: ${s.lang || "-"}`, `country: ${s.country || "-"}`,
      ...Object.entries(s.meta).map(([k, v]) => `${k}: ${v}`), "", s.message,
    ];
    const replyTo = s.email && EMAIL.test(s.email) ? `Reply-To: ${s.email.replace(/[\r\n<>]/g, "")}\r\n` : "";
    const raw =
      `From: Around Warsaw <${FROM}>\r\nTo: ${TO}\r\n${replyTo}Subject: =?UTF-8?B?${btoa(String.fromCharCode(...new TextEncoder().encode(subject)))}?=\r\n` +
      `Message-ID: <${crypto.randomUUID()}@aroundwarsaw.app>\r\nDate: ${new Date().toUTCString()}\r\nMIME-Version: 1.0\r\n` +
      `Content-Type: text/plain; charset=utf-8\r\nContent-Transfer-Encoding: base64\r\n\r\n${b64(lines.join("\n"))}\r\n`;
    await env.EMAIL.send(new EmailMessage(FROM, TO, raw));
    if (id) await env.DB.prepare("UPDATE submissions SET notified = 1 WHERE id = ?1").bind(id).run();
  } catch (e) {
    console.log(JSON.stringify({ event: "notify_failed", error: String(e).slice(0, 200) }));
  }
}

function same(a, b) {
  if (a.length !== b.length) return false;
  let d = 0;
  for (let i = 0; i < a.length; i++) d |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return d === 0;
}

export async function handleAdmin(request, env, url) {
  const token = env.ADMIN_TOKEN || "";
  const given = (request.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
  if (!token || !same(given, token)) return new Response("Not found", { status: 404 });
  const kind = url.searchParams.get("kind");
  const limit = Math.min(1000, Math.max(1, Number(url.searchParams.get("limit")) || 100));
  const { results } = await env.DB.prepare(
    `SELECT id, kind, created_at, email, platform, lang, topic, message, meta, country, notified FROM submissions
     WHERE (?1 IS NULL OR kind = ?1) ORDER BY id DESC LIMIT ?2`,
  ).bind(kind, limit).all();
  if (url.searchParams.get("format") === "csv") {
    const cols = ["id", "kind", "created_at", "email", "platform", "lang", "topic", "message", "meta", "country", "notified"];
    const q = (v) => `"${String(v ?? "").replace(/"/g, '""')}"`;
    const csv = [cols.join(","), ...results.map((r) => cols.map((c) => q(r[c])).join(","))].join("\n");
    return new Response(csv, { headers: { "content-type": "text/csv; charset=utf-8", "cache-control": "no-store" } });
  }
  return json({ count: results.length, rows: results });
}
