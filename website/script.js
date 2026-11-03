(function () {
  var S = window.SITE || {};
  var PRICE = S.pricePerGuest || 3000;
  var MIN = S.minGuests || 10;
  var fmt = function (n) { return n.toLocaleString("en-US"); };

  // mobile nav
  var toggle = document.getElementById("navToggle");
  var links = document.getElementById("navLinks");
  if (toggle && links) {
    toggle.addEventListener("click", function () {
      var open = links.classList.toggle("open");
      toggle.setAttribute("aria-expanded", open);
    });
    links.addEventListener("click", function (e) {
      if (e.target.tagName === "A") { links.classList.remove("open"); toggle.setAttribute("aria-expanded", "false"); }
    });
  }

  // price calculator
  var range = document.getElementById("guests");
  var num = document.getElementById("guestsNum");
  var total = document.getElementById("total");
  var note = document.getElementById("calcNote");
  var ctaN = document.getElementById("ctaN");
  var presets = document.querySelectorAll(".presets button");
  function setGuests(n, from) {
    n = Math.round(Number(n) || 0);
    var shown = Math.max(MIN, n);
    if (from !== "num") num.value = shown;
    if (from !== "range") range.value = Math.min(shown, Number(range.max));
    total.textContent = "TSh " + fmt(shown * PRICE);
    note.textContent = n < MIN
      ? "Kiwango cha chini ni wageni " + MIN + " (TSh " + fmt(MIN * PRICE) + ")"
      : "Wageni " + fmt(shown) + " × TSh " + fmt(PRICE);
    ctaN.textContent = fmt(shown);
    presets.forEach(function (b) { b.classList.toggle("on", Number(b.dataset.n) === shown); });
  }
  if (range && num) {
    range.addEventListener("input", function () { setGuests(range.value, "range"); });
    num.addEventListener("input", function () { setGuests(num.value, "num"); });
    num.addEventListener("blur", function () { setGuests(num.value); });
    presets.forEach(function (b) { b.addEventListener("click", function () { setGuests(b.dataset.n); }); });
    setGuests(range.value);
  }

  // links from config
  var hrefs = {
    whatsapp: S.whatsapp ? "https://wa.me/" + S.whatsapp + "?text=" + encodeURIComponent("Habari, nataka kujua zaidi kuhusu U'r Invente.") : "",
    email: S.email ? "mailto:" + S.email + "?subject=" + encodeURIComponent("U'r Invente") : "",
    android: S.android || "",
    ios: S.ios || ""
  };
  document.querySelectorAll("[data-link]").forEach(function (a) {
    var h = hrefs[a.dataset.link];
    if (h) {
      a.href = h;
      if (/^https?:/.test(h)) { a.target = "_blank"; a.rel = "noopener"; }
      var soon = a.querySelector("[data-soon]");
      if (soon) soon.textContent = a.dataset.link === "ios" ? "Pakua kwenye" : "Ipate kwenye";
    } else {
      a.href = "#anza";
    }
  });

  // reveal on scroll
  var els = document.querySelectorAll(".reveal");
  if ("IntersectionObserver" in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) { if (en.isIntersecting) { en.target.classList.add("in"); io.unobserve(en.target); } });
    }, { threshold: 0.12, rootMargin: "0px 0px -40px 0px" });
    els.forEach(function (el) { io.observe(el); });
  } else {
    els.forEach(function (el) { el.classList.add("in"); });
  }

  var y = document.getElementById("year");
  if (y) y.textContent = new Date().getFullYear();
})();
