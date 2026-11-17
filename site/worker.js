// Counts clicks on the store buttons, then redirects. Everything else is the static site.
//
//   /go/ios      -> IOS_URL     (App Store / TestFlight link, set in wrangler.jsonc)
//   /go/android  -> ANDROID_URL (Google Play link)
//
// Until a store URL is set, the link falls back to the page's own card for that platform, still counted
// and keeping the language: /go/android -> /#android (/pl/#android from the Polish page), /go/ios -> /#beta.
// Privacy: nothing about the visitor is stored. The count has the button name, the page
// language the click came from and the country (Cloudflare's country code), no IP, no cookie.
// Where to read it: dashboard -> Workers & Pages -> aroundwarsaw -> Logs (one line per click)
// and the Analytics Engine dataset "aroundwarsaw_clicks" (see site/README.md).

const TARGETS = { ios: "IOS_URL", android: "ANDROID_URL" };

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const m = url.pathname.match(/^\/go\/(ios|android)\/?$/);
    if (!m) return env.ASSETS.fetch(request);

    const button = m[1];
    const referer = request.headers.get("referer") || "";
    let path = "";
    try { path = new URL(referer).pathname; } catch (_) { /* no or odd referer: English */ }
    const lang = path.startsWith("/pl/") ? "pl" : "en";
    const country = request.cf?.country || "??";
    const dest = (env[TARGETS[button]] || "").trim();
    const base = lang === "pl" ? "/pl/" : "/";
    const target = dest || base + (button === "android" ? "#android" : "#beta");

    console.log(JSON.stringify({ event: "store_click", button, lang, country, live: !!dest }));
    try {
      env.CLICKS?.writeDataPoint({
        blobs: [button, lang, country, dest ? "live" : "beta"],
        doubles: [1],
        indexes: [button],
      });
    } catch (_) { /* counting must never break the redirect */ }

    return new Response(null, {
      status: 302,
      headers: { location: target, "cache-control": "no-store" },
    });
  },
};
