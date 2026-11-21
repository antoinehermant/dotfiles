// A search bar over Immich that reads queries as filters: "2025 christmas"
// is the photos taken in 2025 tagged christmas, nothing else. Immich's own
// search page shows the results: the bar only fills in its filters.
//
// nginx (immich-bar.nginx) serves Immich on port 2284 with this script added
// to its pages, and at /bar/?q=QUERY, for qutebrowser's "ph" search engine.
// It asks Immich's API with the login of the page, so each user completes
// their own tags and people.
//
// The words of a query, in any order, all of them to match:
//   2025          a year            2023-2025   years
//   2025-07       a month           july 2025   too (English, French, German)
//   2025-07-14    a day
//   a tag         its last part is enough: christmas for Holidays/Christmas;
//                 a tag finds its sub-tags too
//   a person, a country, a city   as Immich names them
//   video, photo, favorite
// A word that is none of these is said so, with a button to search it by
// meaning instead (Immich's "context" search), the filters kept.

(() => {
  "use strict";

  const MONTHS = [
    ["january", "jan", "janvier", "januar"], ["february", "feb", "février", "fevrier", "februar"],
    ["march", "mar", "mars", "märz", "maerz"], ["april", "apr", "avril"],
    ["may", "mai"], ["june", "jun", "juin", "juni"], ["july", "jul", "juillet", "juli"],
    ["august", "aug", "août", "aout"], ["september", "sep", "sept", "septembre"],
    ["october", "oct", "octobre", "oktober", "okt"], ["november", "nov", "novembre"],
    ["december", "dec", "décembre", "decembre", "dezember", "dez"],
  ];
  const WORDS = {
    video: { type: "VIDEO" }, videos: { type: "VIDEO" },
    photo: { type: "IMAGE" }, photos: { type: "IMAGE" },
    favorite: { isFavorite: true }, favorites: { isFavorite: true }, fav: { isFavorite: true },
  };

  // Tags, people and places, from Immich, as phrases to match
  let vocabulary = null;
  async function loadVocabulary() {
    if (vocabulary) return vocabulary;
    const get = (path) => fetch(path, { credentials: "same-origin" })
      .then((r) => (r.ok ? r.json() : []), () => []);
    const [tags, people, countries, cities] = await Promise.all([
      get("/api/tags"), get("/api/people?withHidden=false&size=1000"),
      get("/api/search/suggestions?type=country"), get("/api/search/suggestions?type=city"),
    ]);
    const entries = [];
    for (const t of tags) {
      entries.push({ phrase: t.value, kind: "tag", id: t.id, label: t.value });
      if (t.value.includes("/"))
        entries.push({ phrase: t.value.split("/").pop(), kind: "tag", id: t.id, label: t.value });
    }
    for (const p of people.people || [])
      if (p.name) entries.push({ phrase: p.name, kind: "person", id: p.id, label: p.name });
    for (const c of countries) if (c) entries.push({ phrase: c, kind: "country", value: c, label: c });
    for (const c of cities) if (c) entries.push({ phrase: c, kind: "city", value: c, label: c });
    for (const e of entries) e.words = e.phrase.toLowerCase().split(/\s+/);
    vocabulary = entries;
    return entries;
  }

  // The local start of a period, as Immich wants it
  const iso = (y, m = 0, d = 1) => new Date(y, m, d).toISOString();
  const before = (y, m = 0, d = 1) => new Date(new Date(y, m, d).getTime() - 1).toISOString();

  function monthOf(word) {
    const i = MONTHS.findIndex((names) => names.includes(word));
    return i < 0 ? null : i;
  }

  // QUERY as Immich's search filters, the words matched and those not
  function parse(query, entries) {
    const words = query.toLowerCase().trim().split(/\s+/).filter(Boolean);
    const filters = {}, matched = [], unknown = [], problems = [];
    const tagIds = [], personIds = [];
    let years = null, month = null, day = null;
    for (let i = 0; i < words.length; i++) {
      const w = words[i];
      let m;
      if ((m = w.match(/^(\d{4})$/))) years = [+m[1], +m[1]];
      else if ((m = w.match(/^(\d{4})(?:-|\.\.)(\d{4})$/))) years = [+m[1], +m[2]];
      else if ((m = w.match(/^(\d{4})-(\d{1,2})$/)) && +m[2] >= 1 && +m[2] <= 12) {
        years = [+m[1], +m[1]]; month = +m[2] - 1;
      } else if ((m = w.match(/^(\d{4})-(\d{1,2})-(\d{1,2})$/))) {
        years = [+m[1], +m[1]]; month = +m[2] - 1; day = +m[3];
      } else if (monthOf(w) !== null) month = monthOf(w);
      else if (WORDS[w]) Object.assign(filters, WORDS[w]);
      else {
        // The longest tag, person or place starting here
        let best = null;
        for (const e of entries)
          if (e.words.every((x, k) => words[i + k] === x) && (!best || e.words.length > best.words.length))
            best = e;
        if (!best) { unknown.push(w); continue; }
        i += best.words.length - 1;
        matched.push(best);
        if (best.kind === "tag") tagIds.includes(best.id) || tagIds.push(best.id);
        else if (best.kind === "person") personIds.includes(best.id) || personIds.push(best.id);
        else if (filters[best.kind] && filters[best.kind] !== best.value)
          problems.push(`Immich takes one ${best.kind}: ${filters[best.kind]} or ${best.value}?`);
        else filters[best.kind] = best.value;
        continue;
      }
      matched.push({ kind: "date", label: w });
    }
    if (month !== null && !years) problems.push("A month needs a year: july 2025, or 2025-07.");
    else if (years) {
      const [a, b] = years;
      if (day !== null) { filters.takenAfter = iso(a, month, day); filters.takenBefore = before(a, month, day + 1); }
      else if (month !== null) {
        if (a !== b) problems.push("A month needs a single year.");
        filters.takenAfter = iso(a, month); filters.takenBefore = before(a, month + 1);
      } else { filters.takenAfter = iso(a); filters.takenBefore = before(b + 1); }
    }
    if (tagIds.length) filters.tagIds = tagIds;
    if (personIds.length) filters.personIds = personIds;
    return { filters, matched, unknown, problems };
  }

  const searchUrl = (filters) => "/search?query=" + encodeURIComponent(JSON.stringify(filters));

  // The bar

  const STYLE = `
    #anthe-bar { position: fixed; top: 8px; left: 50%; transform: translateX(-50%);
      z-index: 100000; width: min(32em, 60vw); font: 14px sans-serif; }
    #anthe-bar input { box-sizing: border-box; width: 100%; padding: 6px 10px; border-radius: 8px;
      border: 1px solid #5f7e97; background: #011627; color: #d6deeb; outline: none; }
    #anthe-bar input:focus { border-color: #c792ea; }
    #anthe-bar ul { list-style: none; margin: 2px 0 0; padding: 0; background: #0b2942;
      border-radius: 6px; overflow: hidden; }
    #anthe-bar li { padding: 4px 10px; color: #d6deeb; cursor: pointer; }
    #anthe-bar li.on { background: #1d3b53; }
    #anthe-bar li small { color: #8a9ba8; margin-left: .6em; }
    #anthe-bar .note { margin-top: 2px; padding: 6px 10px; background: #0b2942; color: #ecc48d;
      border-radius: 6px; }
    #anthe-bar .note button { margin: 4px 6px 0 0; }
    body.anthe-bar-page #anthe-bar { top: 30vh; }
  `;

  function mount(standalone) {
    if (document.getElementById("anthe-bar")) return;
    const style = document.createElement("style");
    style.textContent = STYLE;
    document.head.appendChild(style);
    const bar = document.createElement("div");
    bar.id = "anthe-bar";
    bar.innerHTML = `<input type="search" placeholder="2025 christmas, july 2024 canada…"
      autocomplete="off" spellcheck="false"><ul></ul><div class="note" hidden></div>`;
    document.body.appendChild(bar);
    const input = bar.querySelector("input"), list = bar.querySelector("ul"),
      note = bar.querySelector(".note");
    let choices = [], chosen = 0;

    // The query of the results shown, back in the bar
    const shown = new URLSearchParams(location.search).get("bar");
    if (shown) input.value = shown;

    function complete() {
      const words = input.value.split(/\s+/), last = words[words.length - 1].toLowerCase();
      choices = !last || !vocabulary ? [] : vocabulary
        .filter((e) => e.phrase.toLowerCase().startsWith(last) && e.phrase.toLowerCase() !== last)
        .slice(0, 8);
      chosen = 0;
      list.innerHTML = "";
      choices.forEach((e, k) => {
        const li = document.createElement("li");
        li.textContent = e.phrase;
        li.insertAdjacentHTML("beforeend", `<small>${e.kind}${e.label !== e.phrase ? ": " + e.label : ""}</small>`);
        li.className = k === chosen ? "on" : "";
        li.onmousedown = (ev) => { ev.preventDefault(); accept(k); };
        list.appendChild(li);
      });
    }
    function accept(k) {
      const words = input.value.split(/\s+/);
      words[words.length - 1] = choices[k].phrase.toLowerCase();
      input.value = words.join(" ") + " ";
      complete();
      input.focus();
    }
    function show(message, buttons = []) {
      note.hidden = false;
      note.textContent = message;
      note.appendChild(document.createElement("br"));
      for (const [label, action] of buttons) {
        const b = document.createElement("button");
        b.textContent = label;
        b.onclick = action;
        note.appendChild(b);
      }
    }
    async function go() {
      const query = input.value.trim();
      if (!query) return;
      const { filters, unknown, problems } = parse(query, await loadVocabulary());
      const open = (f) => { location.href = searchUrl(f) + "&bar=" + encodeURIComponent(query); };
      if (problems.length) return show(problems.join(" "));
      if (unknown.length)
        return show(`Not a tag, person, place or date: ${unknown.join(" ")}`,
          [["Search it by meaning", () => open({ ...filters, query: unknown.join(" ") })],
           ["Without it", () => open(filters)]]);
      open(filters);
    }

    input.addEventListener("input", () => { note.hidden = true; complete(); });
    input.addEventListener("focus", () => loadVocabulary().then(complete));
    input.addEventListener("blur", () => { list.innerHTML = ""; });
    input.addEventListener("keydown", (ev) => {
      // Immich's own shortcuts stay out of the bar
      ev.stopPropagation();
      if (ev.key === "Tab" && choices.length) { ev.preventDefault(); accept(chosen); }
      else if ((ev.key === "ArrowDown" || ev.key === "ArrowUp") && choices.length) {
        ev.preventDefault();
        chosen = (chosen + (ev.key === "ArrowDown" ? 1 : choices.length - 1)) % choices.length;
        [...list.children].forEach((li, k) => { li.className = k === chosen ? "on" : ""; });
      } else if (ev.key === "Enter") { ev.preventDefault(); list.innerHTML = ""; go(); }
      else if (ev.key === "Escape") { list.innerHTML = ""; input.blur(); }
    });
    if (standalone) input.focus();
    return { input, go };
  }

  // For tests: node loads this file and calls parse
  if (typeof document === "undefined") { module.exports = { parse }; return; }

  // /bar/?q=QUERY goes straight to the results, unless the query needs a word
  if (location.pathname.startsWith("/bar")) {
    document.body.classList.add("anthe-bar-page");
    const ui = mount(true);
    const q = new URLSearchParams(location.search).get("q");
    if (q) { ui.input.value = q; ui.go(); }
  } else {
    mount(false);
  }
})();
