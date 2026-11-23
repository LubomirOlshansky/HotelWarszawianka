// Around Warsaw: pick the page's language before it draws. A Polish browser opening an English page
// (/ or /beta/) goes to its Polish twin; everyone else stays in English. A choice made with the
// EN / PL switch (or ?lang=en|pl in a link) is remembered on this device and always wins.
(function () {
  "use strict";
  var PAIRS = { "/": "/pl/", "/beta/": "/pl/beta/" };
  var KEY = "aw-lang";
  function get() { try { return localStorage.getItem(KEY); } catch (e) { return null; } }
  function set(v) { try { localStorage.setItem(KEY, v); } catch (e) { /* private mode: no memory */ } }

  var path = location.pathname.replace(/\/index\.html$/, "/");
  var params = new URLSearchParams(location.search);
  var asked = params.get("lang");
  if (asked === "en" || asked === "pl") set(asked);
  var choice = asked || get();

  var en = null, pl = null;
  for (var k in PAIRS) { if (path === k) en = k; if (path === PAIRS[k]) pl = PAIRS[k]; }
  var target = null;
  if (en) {
    var browser = (navigator.languages && navigator.languages[0]) || navigator.language || "";
    if (choice === "pl" || (!choice && /^pl\b/i.test(browser))) target = PAIRS[en];
  } else if (pl && choice === "en") {
    for (var j in PAIRS) if (PAIRS[j] === pl) target = j;
  }
  if (target) {
    params.delete("lang");
    var q = params.toString();
    location.replace(target + (q ? "?" + q : "") + location.hash);
    return;
  }

  // The switch in the top bar (and the footer's language link): remember what was picked.
  document.addEventListener("click", function (ev) {
    var a = ev.target.closest && ev.target.closest("a[hreflang]");
    if (a && (a.hreflang === "pl" || a.hreflang === "en")) set(a.hreflang);
  }, true);
})();
