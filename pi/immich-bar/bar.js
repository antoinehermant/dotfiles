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
    body.anthe-viewing #anthe-bar { display: none; }
    #anthe-bar .row { display: flex; gap: 6px; }
    #anthe-bar .row input.query { flex: 1; }
    #anthe-select-tags { flex: 0 0 15em; }
    #anthe-select-tags input { width: 100%; border-color: #c792ea; }
    .anthe-panel { position: fixed; left: 12px; bottom: 12px; z-index: 100000; max-width: 40vw;
      font: 14px sans-serif; display: flex; flex-wrap: wrap; align-items: center; gap: 4px; }
    .anthe-panel .chips { display: contents; }
    .anthe-panel .tag { padding: 3px 4px 3px 9px; border-radius: 12px; background: rgba(11, 41, 66, .85);
      color: #d6deeb; }
    .anthe-panel .tag button { border: 0; background: none; color: #8a9ba8; cursor: pointer;
      padding: 0 4px; font-size: 14px; }
    .anthe-panel .tag button:hover { color: #ef5350; }
    .anthe-panel .tag.some { opacity: .6; }
    .anthe-panel .error { color: #ef5350; padding-right: 9px; }
    .anthe-panel input { width: 11em; padding: 3px 9px; border-radius: 12px; border: 1px solid #5f7e97;
      background: rgba(1, 22, 39, .85); color: #d6deeb; outline: none; font: inherit; }
    .anthe-panel input:focus { border-color: #c792ea; width: 16em; }
    .anthe-count { position: absolute; right: 6px; bottom: 6px; z-index: 3; pointer-events: auto;
      display: flex; align-items: center; gap: 3px; padding: 1px 6px; border-radius: 9px;
      background: rgba(1, 22, 39, .75); color: #d6deeb; font: 600 11px sans-serif; }
    .anthe-add { position: relative; display: inline-block; }
    .anthe-add ul { position: absolute; top: 100%; left: 0; list-style: none; margin: 2px 0 0;
      padding: 0; min-width: 16em; background: #0b2942; border-radius: 6px; overflow: hidden;
      font: 14px sans-serif; }
    .anthe-add.up ul { top: auto; bottom: 100%; margin: 0 0 2px; display: flex;
      flex-direction: column-reverse; }
    .anthe-add li { padding: 4px 10px; color: #d6deeb; cursor: pointer; white-space: nowrap; }
    .anthe-add li.on { background: #1d3b53; }
  `;

  function mount(standalone) {
    if (document.getElementById("anthe-bar")) return;
    const style = document.createElement("style");
    style.textContent = STYLE;
    document.head.appendChild(style);
    const bar = document.createElement("div");
    bar.id = "anthe-bar";
    bar.innerHTML = `<div class="row"><input type="search" class="query"
      placeholder="2025 christmas, july 2024 canada…" autocomplete="off" spellcheck="false"></div>
      <ul class="query-list"></ul><div class="note" hidden></div>`;
    document.body.appendChild(bar);
    const input = bar.querySelector("input.query"), list = bar.querySelector("ul.query-list"),
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
    return { input, go, bar };
  }

  // Tags, on the photo open in Immich's viewer and on the photos selected
  // in its grid. The viewer shows the photo's tags in its bottom left
  // corner, x removing one; a field next to them, and one next to the
  // search bar while photos are selected, adds a tag, existing or new
  // (Trips/Canada makes it under Trips). t goes to the field, rather than
  // to Immich's tag dialog.

  const api = (method, path, body) => fetch(path, {
    method, credentials: "same-origin",
    headers: body ? { "Content-Type": "application/json" } : {},
    body: body && JSON.stringify(body),
  }).then((r) => { if (!r.ok) throw new Error(`${method} ${path}: ${r.status}`); return r.status === 204 ? null : r.json(); });

  // The photo open in the viewer: /photos/ID, /albums/…/photos/ID, /search/photos/ID…
  const openAsset = () => (location.pathname.match(/\/photos\/([0-9a-f-]{36})(?:\/|$)/) || [])[1];

  // The photos selected in the grid, those Immich has on the page: it only
  // keeps the thumbnails near the screen
  const selectedAssets = () => [...document.querySelectorAll(
    "[data-thumbnail-focus-container][data-asset][data-selected]")].map((e) => e.dataset.asset);

  // How many Immich says are selected, as "12 Selected" at the top
  function selectedCount() {
    let count = null;
    for (const e of document.querySelectorAll("body *")) {
      if (e.children.length || e.closest("#anthe-bar, .anthe-panel")) continue;
      const m = e.textContent.trim().match(/^(\d+)\s+\p{L}+$/u);
      if (m && e.getBoundingClientRect().top < 80 && e.getBoundingClientRect().height > 0)
        count = Math.max(count || 0, +m[1]);
    }
    return count;
  }

  // Each photo's tags, as Immich last gave them, asked 6 at a time, the
  // latest asked first: the thumbnails just scrolled to
  const tagCache = new Map(), pending = new Map(), failed = new Set(), queue = [];
  let running = 0;
  function tagsOfAsset(id) {
    if (tagCache.has(id)) return Promise.resolve(tagCache.get(id));
    if (!pending.has(id))
      pending.set(id, new Promise((resolve, reject) => { queue.push({ id, resolve, reject }); pump(); }));
    return pending.get(id);
  }
  function pump() {
    while (running < 6 && queue.length) {
      const { id, resolve, reject } = queue.pop();
      running++;
      api("GET", `/api/assets/${id}`)
        .then((a) => { tagCache.set(id, a.tags || []); resolve(a.tags || []); },
              (e) => { failed.add(id); reject(e); })
        .finally(() => { running--; pending.delete(id); pump(); });
    }
  }
  const forget = (ids) => ids.forEach((id) => tagCache.delete(id));

  const vocabularyTag = (value) => (vocabulary || [])
    .find((e) => e.kind === "tag" && e.label.toLowerCase() === value.toLowerCase());

  // A field adding a tag to assets(), completing the tags but those of
  // except(), then calling done(tag) or failed(message)
  function tagField(container, { placeholder, assets, except = () => [], done, failed }) {
    const add = document.createElement("span");
    add.className = "anthe-add";
    add.innerHTML = `<ul></ul><input autocomplete="off" spellcheck="false">`;
    container.appendChild(add);
    const input = add.querySelector("input"), list = add.querySelector("ul");
    input.placeholder = placeholder;
    let choices = [], chosen = 0;

    // The tags starting so, or a part of which does, and the text typed as
    // a new tag unless it is one; Enter adds the one highlighted, the first
    // existing one at first
    function complete() {
      const typed = input.value.trim(), lower = typed.toLowerCase();
      const seen = new Set(except());
      choices = [];
      if (typed && vocabulary)
        for (const e of vocabulary)
          if (e.kind === "tag" && !seen.has(e.id) && !choices.some((c) => c.id === e.id)
              && (e.label.toLowerCase().startsWith(lower) || e.label.toLowerCase().includes("/" + lower)))
            choices.push({ id: e.id, value: e.label, label: e.label });
      choices = choices.slice(0, 8);
      if (typed && !vocabularyTag(typed)) choices.push({ value: typed, label: `new tag: ${typed}` });
      chosen = 0;
      show();
    }
    function show() {
      list.innerHTML = "";
      choices.forEach((c, k) => {
        const li = document.createElement("li");
        li.textContent = c.label;
        li.className = k === chosen ? "on" : "";
        li.onmousedown = (ev) => { ev.preventDefault(); addTag(c.value); };
        list.appendChild(li);
      });
    }
    async function addTag(name) {
      const ids = assets();
      if (!ids.length) return;
      try {
        // Made if new, its parents too
        const [tag] = await api("PUT", "/api/tags", { tags: [name] });
        await api("PUT", "/api/tags/assets", { tagIds: [tag.id], assetIds: ids });
        if (!vocabularyTag(tag.value)) vocabulary = null;
        input.value = "";
        list.innerHTML = "";
        choices = [];
        forget(ids);
        done(tag, ids);
      } catch (e) { failed(e.message); }
    }

    input.addEventListener("input", complete);
    input.addEventListener("focus", () => loadVocabulary().then(complete));
    input.addEventListener("blur", () => { list.innerHTML = ""; });
    input.addEventListener("keydown", (ev) => {
      ev.stopPropagation();  // Immich's shortcuts, as the arrows, stay out of it
      const n = choices.length;
      if (ev.key === "Tab" && n) { ev.preventDefault(); input.value = choices[chosen].value; complete(); }
      else if ((ev.key === "ArrowDown" || ev.key === "ArrowUp") && n) {
        ev.preventDefault();
        // The list opens upwards from the viewer's field, downwards from the bar's
        const up = add.classList.contains("up");
        chosen = (chosen + ((ev.key === "ArrowDown") !== up ? 1 : n - 1)) % n;
        show();
      } else if (ev.key === "Enter") { ev.preventDefault(); if (n) addTag(choices[chosen].value); }
      else if (ev.key === "Escape") { ev.preventDefault(); input.blur(); }
    });
    return { input, add };
  }

  // The viewer's panel
  function mountTags() {
    const panel = document.createElement("div");
    panel.id = "anthe-tags";
    panel.className = "anthe-panel";
    panel.hidden = true;
    document.body.appendChild(panel);
    const chips = document.createElement("span");
    chips.className = "chips";
    panel.appendChild(chips);
    const error = document.createElement("span");
    let asset = null, tags = [];

    const field = tagField(panel, {
      placeholder: "+ tag (t)",
      assets: () => (asset ? [asset] : []),
      except: () => tags.map((t) => t.id),
      done: () => load().then(() => field.input.focus()),
      failed: fail,
    });
    field.add.classList.add("up");
    error.className = "tag error";
    panel.appendChild(error);

    function fail(message) { error.textContent = message; error.hidden = false; }
    function render() {
      chips.innerHTML = "";
      error.hidden = true;
      for (const t of tags) {
        const chip = document.createElement("span");
        chip.className = "tag";
        chip.textContent = t.value;
        const x = document.createElement("button");
        x.textContent = "×";
        x.title = `Remove ${t.value}`;
        x.onclick = () => api("DELETE", `/api/tags/${t.id}/assets`, { ids: [asset] })
          .then(() => forget([asset]))
          .then(load, (e) => fail(e.message));
        chip.appendChild(x);
        chips.appendChild(chip);
      }
    }
    async function load() {
      const id = asset;
      const a = await api("GET", `/api/assets/${id}`);
      tagCache.set(id, a.tags || []);
      if (id !== asset) return;  // another photo meanwhile
      tags = [...(a.tags || [])].sort((x, y) => x.value.localeCompare(y.value));
      render();
    }

    // Immich changes pages without loading them
    setInterval(() => {
      const id = openAsset();
      document.body.classList.toggle("anthe-viewing", !!id);
      if (id === asset) return;
      asset = id;
      panel.hidden = !id;
      tags = [];
      render();
      if (id) load().catch((e) => fail(e.message));
    }, 300);
    return field;
  }

  // The selection's field, next to the search bar, and its tags in the
  // bottom left corner: those on all the photos selected, then those on
  // some of them, dimmed, with how many. x removes one from all of them, to
  // undo a tag put by mistake, as after searching for it.
  function mountSelectionTags(bar) {
    const box = document.createElement("span");
    box.id = "anthe-select-tags";
    box.hidden = true;
    bar.querySelector(".row").appendChild(box);
    const note = bar.querySelector(".note");
    const panel = document.createElement("div");
    panel.id = "anthe-select-common";
    panel.className = "anthe-panel";
    panel.hidden = true;
    document.body.appendChild(panel);
    const say = (message) => { note.hidden = false; note.textContent = message; };
    const photos = (n) => `${n} photo${n > 1 ? "s" : ""}`;
    let ids = [];

    const field = tagField(box, {
      placeholder: "+ tag",
      assets: () => ids,
      done: (tag, tagged) => {
        say(`${tag.value}: added to ${photos(tagged.length)}`);
        refresh();
        field.input.focus();
      },
      failed: say,
    });

    async function refresh() {
      const wanted = ids;
      if (!wanted.length) { panel.hidden = true; return; }
      let lists;
      try { lists = await Promise.all(wanted.map(tagsOfAsset)); } catch (e) { return say(e.message); }
      if (wanted !== ids) return;  // the selection changed meanwhile
      const counts = new Map();
      for (const list of lists)
        for (const t of list) {
          const c = counts.get(t.id) || { tag: t, n: 0 };
          c.n++;
          counts.set(t.id, c);
        }
      const all = [...counts.values()].sort((a, b) =>
        (b.n === wanted.length) - (a.n === wanted.length) || a.tag.value.localeCompare(b.tag.value));
      panel.innerHTML = "";
      panel.hidden = !all.length;
      for (const { tag, n } of all) {
        const chip = document.createElement("span");
        chip.className = n === wanted.length ? "tag" : "tag some";
        chip.textContent = n === wanted.length ? tag.value : `${tag.value} (${n} of ${wanted.length})`;
        const x = document.createElement("button");
        x.textContent = "×";
        x.title = `Remove ${tag.value} from the ${photos(n)} having it`;
        x.onclick = async () => {
          const having = wanted.filter((id) => (tagCache.get(id) || []).some((t) => t.id === tag.id));
          try {
            await api("DELETE", `/api/tags/${tag.id}/assets`, { ids: having });
            forget(having);
            say(`${tag.value}: removed from ${photos(having.length)}`);
            refresh();
          } catch (e) { say(e.message); }
        };
        chip.appendChild(x);
        panel.appendChild(chip);
      }
    }

    setInterval(() => {
      const now = openAsset() ? [] : selectedAssets();
      if (now.join() === ids.join()) return;
      ids = now;
      box.hidden = !ids.length;
      if (!ids.length) { note.hidden = true; panel.hidden = true; return; }
      const count = selectedCount();
      field.input.placeholder = count && count > ids.length
        ? `+ tag (${ids.length} of ${count}: scroll over the others)`
        : `+ tag (${photos(ids.length)}, t)`;
      refresh();
    }, 300);
    return field;
  }

  // On each thumbnail of the grid, its number of tags, in its bottom right
  // corner, the tags themselves on hovering it; nothing on those without:
  // what is left to sort
  const TAG_ICON = `<svg viewBox="0 0 24 24" width="11" height="11"><path fill="currentColor"
    d="M21.4 11.6l-9-9A2 2 0 0011 2H4a2 2 0 00-2 2v7c0 .6.2 1.1.6 1.4l9 9a2 2 0 002.8 0l7-7a2 2 0 000-2.8zM6.5 8A1.5 1.5 0 116.5 5a1.5 1.5 0 010 3z"/></svg>`;

  function mountCounts() {
    setInterval(() => {
      if (openAsset()) return;
      for (const thumb of document.querySelectorAll("[data-thumbnail-focus-container][data-asset]")) {
        // Immich reuses a thumbnail for another photo as it scrolls
        const id = thumb.dataset.asset, tags = tagCache.get(id);
        let badge = thumb.querySelector(":scope > .anthe-count");
        if (!tags && !failed.has(id)) tagsOfAsset(id).catch(() => {});
        if (!tags || !tags.length) { if (badge) badge.remove(); continue; }
        if (!badge) {
          badge = document.createElement("span");
          badge.className = "anthe-count";
          if (getComputedStyle(thumb).position === "static") thumb.style.position = "relative";
          thumb.appendChild(badge);
        }
        const title = tags.map((t) => t.value).sort().join(", ");
        if (badge.title !== title) { badge.innerHTML = TAG_ICON + tags.length; badge.title = title; }
      }
    }, 500);
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
    const ui = mount(false);
    const viewer = mountTags(), selection = mountSelectionTags(ui.bar);
    mountCounts();
    window.addEventListener("keydown", (ev) => {
      if (ev.key !== "t" || ev.ctrlKey || ev.metaKey || ev.altKey || ev.shiftKey) return;
      if (ev.target.closest && ev.target.closest("input, textarea, [contenteditable]")) return;
      const field = openAsset() ? viewer : !selection.add.parentNode.hidden ? selection : null;
      if (!field) return;
      ev.preventDefault();
      ev.stopImmediatePropagation();
      field.input.focus();
    }, true);
  }
})();
