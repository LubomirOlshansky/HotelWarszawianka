// Around Warsaw: forms, day/night slider, hero loop, phone sticky bar. Without JavaScript the page
// still reads and the forms still post to Formspree; the loop and the sticky bar only exist with it.
(function () {
  "use strict";
  var d = document, de = d.documentElement, $ = function (s, r) { return (r || d).querySelector(s); };
  var all = function (s, r) { return [].slice.call((r || d).querySelectorAll(s)); };
  var mq = function (q) { return window.matchMedia && matchMedia(q).matches; };

  // The visitor's phone: data-os on <html> picks the sticky bar's button (an iPad says "Macintosh").
  var ua = navigator.userAgent;
  de.dataset.os = /iPhone|iPad|iPod/.test(ua) || (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1) ? "ios"
    : /Android/.test(ua) ? "android" : "other";

  // Forms: #form (feedback) and #notify (the Android "tell me when" email), both to Formspree.
  var EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  all("form[data-need]").forEach(function (f) {
    if (!window.fetch) return;
    var st = $(".status", f), email = f.elements.email, msg = f.elements.message, subj = f.elements._subject;
    var need = f.dataset.need, send = $(".send", f);
    function say(t, k) { st.textContent = t || ""; st.className = "status" + (k ? " " + k : ""); }
    function mark(el, t) {
      if (!el) return;
      $("#" + el.id + "-err").textContent = t || "";
      if (t) el.setAttribute("aria-invalid", "true"); else el.removeAttribute("aria-invalid");
    }
    function topic() { var t = $("input[name=topic]:checked", f); return t ? t.value : "Feedback"; }
    function check() {
      var ok = true, v = email.value.trim();
      mark(email); mark(msg);
      if (need === "email" && !v) { mark(email, st.dataset.needEmail); ok = false; }
      else if (v && !EMAIL.test(v)) { mark(email, st.dataset.badEmail); ok = false; }
      if (need === "message" && msg.value.trim().length < 2) { mark(msg, st.dataset.needMsg); ok = false; }
      return ok;
    }
    f.addEventListener("change", function (e) {
      if (e.target.name === "topic") subj.value = "Around Warsaw: " + topic();
    });
    f.addEventListener("submit", function (e) {
      e.preventDefault();
      if (!check()) { ($("[aria-invalid=true]", f) || email).focus(); return; }
      send.disabled = true;
      say(st.dataset.sending);
      fetch(f.action, { method: "POST", body: new FormData(f), headers: { Accept: "application/json" } })
        .then(function (r) {
          if (!r.ok) throw 0;
          var s = subj.value; f.reset(); subj.value = s;
          say(st.dataset.ok, "ok");
        })
        .catch(function () { say(st.dataset.fail, "bad"); })
        .then(function () { send.disabled = false; });
    });
  });

  // Day/night: the range input moves the wipe (--p on the stage; the CSP forbids inline style).
  var stage = $(".dn-stage"), range = stage && $(".dn-range", stage);
  if (range) {
    var move = function () { stage.style.setProperty("--p", range.value + "%"); };
    range.addEventListener("input", move);
    move();
  }

  // Video: the hero loop (phone or desktop file) and the chapters' optional clips (desktop only).
  // Starts only without reduced motion, Save-Data or a 2g link; pauses off screen, in a hidden tab,
  // and on the visitor's pause button (WCAG 2.2.2). Without files there is no <video>: the poster stays.
  var nc = navigator.connection || {};
  var calm = mq("(prefers-reduced-motion: reduce)") || nc.saveData || /2g/.test(nc.effectiveType || "");
  var phone = mq("(max-width: 700px)");
  var vids = all("video").filter(function (v) { return v.hasAttribute("data-hero") || !phone; });
  var btn = $(".vctl"), held = false;
  function start(v) {
    if (!v.dataset.ready) {
      all("source", v).forEach(function (s) {
        if (s.dataset.set === (phone ? "phone" : "desktop") || !$("source[data-set=" + (phone ? "phone" : "desktop") + "]", v)) s.src = s.dataset.src;
        else s.remove();
      });
      v.dataset.ready = "1";
      v.load();
    }
    var p = v.play();
    if (p && p.then) p.then(function () { v.classList.add("on"); }, function () {});
  }
  function tell() {
    btn.classList.toggle("paused", held);
    btn.setAttribute("aria-label", btn.dataset[held ? "play" : "pause"]);
  }
  if (window.IntersectionObserver && vids.length) {
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) {
        var v = e.target;
        v.want = e.isIntersecting;
        if (e.isIntersecting && !calm && !(held && v.hasAttribute("data-hero")) && !d.hidden) start(v); else v.pause();
      });
    }, { threshold: 0.4 });
    vids.forEach(function (v) { io.observe(v); });
    d.addEventListener("visibilitychange", function () {
      vids.forEach(function (v) {
        if (d.hidden) v.pause(); else if (v.want && !calm && !(held && v.hasAttribute("data-hero"))) start(v);
      });
    });
  }
  var hero = $("[data-hero]");
  if (btn && hero) {
    btn.hidden = false;
    held = calm; tell();
    btn.addEventListener("click", function () {
      held = !held; tell();
      if (held) hero.pause(); else { calm = false; start(hero); }
    });
  }

  // The radio ticker: its tag is a pause button (WCAG 2.2.2; hover alone does nothing on a phone).
  var rt = $(".radio-tag");
  if (rt) rt.addEventListener("click", function () {
    var on = rt.getAttribute("aria-pressed") !== "true";
    rt.setAttribute("aria-pressed", on); rt.parentNode.classList.toggle("held", on);
  });

  // Sticky bar (phones): after the hero is gone, until the join section is on screen.
  var stk = $(".stk"), heroEl = $(".hero"), join = $("#beta");
  if (stk && heroEl && join && window.IntersectionObserver) {
    var seen = { h: true, j: false };
    var so = new IntersectionObserver(function (es) {
      es.forEach(function (e) { seen[e.target === heroEl ? "h" : "j"] = e.isIntersecting; });
      stk.classList.toggle("on", !seen.h && !seen.j);
    });
    stk.hidden = false;
    so.observe(heroEl); so.observe(join);
  }
})();
