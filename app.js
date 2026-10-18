(function () {
  "use strict";
  var $ = function (id) { return document.getElementById(id); };
  var ORD = ["الأول", "الثاني"];

  /* ---------- الحالة ---------- */
  var DEF = {
    keys: { gh_token: "", gh_repo: "", sb_token: "", sb_ref: "", gemini: "", claude: "", claude_model: "claude-sonnet-5-5", gemini_model: "gemini-3.8-flash", gemini_x1: "", gemini_x2: "", gemini_x3: "" },
    extras: [{ n: "", v: "" }, { n: "", v: "" }, { n: "", v: "" }],
    apps: [{ name: "", desc: "", code: "", provider: "claude", sql: "", icon: "" }, { name: "", desc: "", code: "", provider: "claude", sql: "", icon: "" }],
    tab: "keys"
  };
  var S = JSON.parse(JSON.stringify(DEF));
  try {
    var saved = JSON.parse(localStorage.getItem("apkapps") || "null");
    if (saved) {
      Object.assign(S.keys, saved.keys || {});
      if (!S.keys.gemini_model || S.keys.gemini_model === "gemini-2.5-pro") S.keys.gemini_model = "gemini-3.8-flash";
      if (Array.isArray(saved.extras) && saved.extras.length) S.extras = saved.extras;
      if (Array.isArray(saved.apps)) saved.apps.slice(0, 2).forEach(function (a, i) { Object.assign(S.apps[i], a); });
      if (saved.tab) S.tab = saved.tab;
    }
  } catch (e) {}
  function save() { try { localStorage.setItem("apkapps", JSON.stringify(S)); } catch (e) {} }

  /* ---------- أدوات ---------- */
  function el(tag, attrs, kids) {
    var n = document.createElement(tag);
    Object.keys(attrs || {}).forEach(function (k) {
      if (k === "class") n.className = attrs[k];
      else if (k === "text") n.textContent = attrs[k];
      else n.setAttribute(k, attrs[k]);
    });
    (kids || []).forEach(function (c) { n.appendChild(c); });
    return n;
  }
  function sleep(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }
  function b64(s) { return btoa(unescape(encodeURIComponent(s))); }
  function stripFences(t) { return t.replace(/^\s*```[a-z]*\r?\n/i, "").replace(/\r?\n```\s*$/i, "").trim(); }
  function errMsg(e) {
    var m = e && e.message ? e.message : String(e);
    if (/Failed to fetch|NetworkError|Load failed|network error|connection abort|connection reset|terminated/i.test(m)) return "انقطع الاتصال أو تعذر (شبكة أو منع CORS من المتصفح).";
    return m;
  }

  function parseFiles(text) {
    var out = [], re = /^=== FILE: (.+?) ===\s*$/gm, m, marks = [];
    while ((m = re.exec(text))) marks.push({ path: m[1].trim().replace(/^\/+/, ""), start: re.lastIndex, head: m.index });
    for (var i = 0; i < marks.length; i++) {
      var end = i + 1 < marks.length ? marks[i + 1].head : text.length;
      var body = text.slice(marks[i].start, end).replace(/^\r?\n/, "");
      body = body.replace(/^```[a-z]*\r?\n/i, "").replace(/\r?\n```\s*$/i, "").replace(/\s+$/, "") + "\n";
      out.push({ path: marks[i].path, content: body });
    }
    return out;
  }
  function serialize(files) { return files.map(function (f) { return "=== FILE: " + f.path + " ===\n" + f.content; }).join("\n"); }
  function merge(oldText, newFiles) {
    var files = parseFiles(oldText);
    newFiles.forEach(function (nf) {
      var i = files.findIndex(function (f) { return f.path === nf.path; });
      if (i >= 0) files[i] = nf; else files.push(nf);
    });
    return serialize(files);
  }
  function pubName(files) {
    var p = files.find(function (f) { return f.path === "pubspec.yaml"; });
    var m = p && /^name:\s*([A-Za-z0-9_]+)/m.exec(p.content);
    return m ? m[1].toLowerCase() : null;
  }

  /* ---------- الذكاء الاصطناعي ---------- */
  async function readSSE(res, onData) {
    var reader = res.body.getReader(), dec = new TextDecoder(), buf = "";
    while (true) {
      var r = await reader.read();
      if (r.done) break;
      buf += dec.decode(r.value, { stream: true });
      var idx;
      while ((idx = buf.search(/\r?\n\r?\n/)) >= 0) {
        var block = buf.slice(0, idx);
        buf = buf.slice(idx).replace(/^\r?\n\r?\n/, "");
        block.split(/\r?\n/).forEach(function (line) {
          if (line.indexOf("data:") !== 0) return;
          var d = line.slice(5).trim();
          if (!d || d === "[DONE]") return;
          try { onData(JSON.parse(d)); } catch (e) {}
        });
      }
    }
  }
  async function aiOnce(provider, prompt, onProgress) {
    var K = S.keys, res, data, text = "";
    function tick() { if (onProgress) onProgress(text.length); }
    if (provider === "gemini") {
      var gkeys = [K.gemini, K.gemini_x1, K.gemini_x2, K.gemini_x3].filter(Boolean);
      if (!gkeys.length) throw new Error("أدخل مفتاح Gemini في قائمة المفاتيح.");
      var lastErr;
      for (var gi = 0; gi < gkeys.length; gi++) {
        res = await fetch("https://generativelanguage.googleapis.com/v1beta/models/" + encodeURIComponent(K.gemini_model || "gemini-3.8-flash") + ":streamGenerateContent?alt=sse", {
          method: "POST", headers: { "Content-Type": "application/json", "x-goog-api-key": gkeys[gi] },
          body: JSON.stringify({ contents: [{ role: "user", parts: [{ text: prompt }] }], generationConfig: { maxOutputTokens: 32000 } })
        });
        if (res.ok) {
          var gerr = "";
          await readSSE(res, function (d) {
            if (d.error) { gerr = d.error.message || "error"; return; }
            var parts = (d.candidates && d.candidates[0] && d.candidates[0].content && d.candidates[0].content.parts) || [];
            parts.forEach(function (p) { if (p.text) text += p.text; });
            tick();
          });
          if (!text) throw new Error("Gemini: " + (gerr || "لم يرجع نصاً."));
          return text;
        }
        data = await res.json().catch(function () { return {}; });
        lastErr = new Error("Gemini: " + ((data.error && data.error.message) || res.status));
        if (![400, 401, 403, 429, 503].includes(res.status) || gi === gkeys.length - 1) break;
        if (res.status === 400 && !/API key/i.test(lastErr.message)) break;
      }
      throw lastErr;
    }
    if (!K.claude) throw new Error("أدخل مفتاح Claude في قائمة المفاتيح.");
    res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-api-key": K.claude, "anthropic-version": "2023-06-01", "anthropic-dangerous-direct-browser-access": "true" },
      body: JSON.stringify({ model: K.claude_model || "claude-sonnet-5-5", max_tokens: 16000, stream: true, messages: [{ role: "user", content: prompt }] })
    });
    if (!res.ok) { data = await res.json().catch(function () { return {}; }); throw new Error("Claude: " + ((data.error && data.error.message) || res.status)); }
    var cerr = "";
    await readSSE(res, function (d) {
      if (d.type === "content_block_delta" && d.delta && d.delta.text) { text += d.delta.text; tick(); }
      else if (d.type === "error") cerr = (d.error && d.error.message) || "error";
    });
    if (!text) throw new Error("Claude: " + (cerr || "لم يرجع نصاً."));
    return text;
  }

  /* يعيد المحاولة تلقائياً لو انقطعت الشبكة أثناء التوليد */
  async function ai(provider, prompt, onProgress) {
    var lastE;
    for (var t = 0; t < 3; t++) {
      try { return await aiOnce(provider, prompt, onProgress); }
      catch (e) {
        lastE = e;
        if (!/Failed to fetch|NetworkError|Load failed|network|abort|terminated|connection|ECONN/i.test(String((e && e.message) || e))) throw e;
        if (t < 2) await sleep(3000 * (t + 1));
      }
    }
    throw lastE;
  }
  /* يمنع إطفاء الشاشة أثناء التوليد والبناء (انقطاع الاتصال غالباً بسبب خمول الجوال) */
  var wake = null;
  async function keepAwake(on) {
    try {
      if (on) { if (!wake && navigator.wakeLock) wake = await navigator.wakeLock.request("screen"); }
      else if (wake) { await wake.release(); wake = null; }
    } catch (e) { wake = null; }
  }

  var FORMAT = "OUTPUT FORMAT (strict): output only files, no prose before or after, no markdown fences. Each file starts with a line exactly like\n=== FILE: lib/main.dart ===\nfollowed by the full file content.";
  var RULES = [
    "STRICT COMPILE-SAFETY RULES (the code is compiled unseen with the latest stable Flutter SDK; one invented name breaks the whole build):",
    "- Use only classes, members and parameters you are certain exist in current stable Flutter/Dart. If unsure, use a simpler approach.",
    "- ThemeData component themes: cardTheme takes CardThemeData(...) (never CardTheme), dialogTheme takes DialogThemeData(...), tabBarTheme takes TabBarThemeData(...).",
    "- Colors: use only real members of the Colors class (Colors.green, Colors.red, Colors.teal, Colors.blueGrey, Colors.white70, Colors.black87, Colors.black54 ...). NEVER Tailwind-style or invented names such as emerald, rose, slate, sky, violet, zinc, gray, black82. For any other color write Color(0xFFRRGGBB).",
    "- Transparency: write color.withValues(alpha: 0.2). Never withOpacity.",
    "- Use PopScope (not WillPopScope), textScaler (not textScaleFactor), WidgetStateProperty (not MaterialStateProperty), ColorScheme.surface/onSurface (not background/onBackground).",
    "- Every import must be used correctly and every identifier must be defined in the project or imported. Check each file for missing imports before answering."
  ].join("\n");

  function genPrompt(a) {
    return [
      "You are a senior Flutter engineer. Generate a complete, runnable Flutter project for this app (the description is in Arabic):",
      "", "APP NAME: " + (a.name || "app"), "DESCRIPTION: " + a.desc.trim(), "",
      "Requirements:",
      "- Material 3, light and dark theme, clean structure under lib/ (models, services, state, screens, widgets).",
      "- UI in Arabic with RTL unless the description says otherwise. Code and identifiers in English.",
      "- Handle loading, empty and error states. Validate input. Null-safe modern Dart 3, no deprecated APIs.",
      "- Use only real pub.dev packages with caret versions. pubspec.yaml must use environment sdk: '>=3.3.0 <4.0.0' and a valid lowercase snake_case package name.",
      "- Include pubspec.yaml, analysis_options.yaml, lib/main.dart and every other lib file, and one passing test in test/.",
      "- Do NOT include android/, ios/, web/ or binary files.",
      "- If you use flutter_localizations or the intl package, write the dependency as intl: any so it matches the installed Flutter SDK. Prefer fewer, well-known packages.",
      "", RULES, FORMAT, "Begin with pubspec.yaml."
    ].join("\n");
  }
  function editPrompt(a, instr) {
    return ["You are a senior Flutter engineer. Here is a Flutter project:", "", a.code, "",
      "Apply this change (written by the user, may be Arabic): " + instr, "",
      "Output ONLY the files that changed or are new, each complete.", RULES, FORMAT].join("\n");
  }
  function previewPrompt(a) {
    return ["Below is a Flutter app's code. Produce ONE self-contained HTML file (inline CSS and JS, no external resources, no network) that mimics how the app looks and behaves, drawn as a phone screen about 390px wide, with in-memory sample data so every main screen and action works. Match the app's colors, text and direction (RTL if the UI is Arabic).",
      "Output only the HTML, starting with <!doctype html>.", "", "APP DESCRIPTION: " + a.desc, "", a.code.slice(0, 90000)].join("\n");
  }
  function sqlPrompt(idxs, shared) {
    var apps = idxs.map(function (i) {
      return "--- APP " + (i + 1) + " (" + (S.apps[i].name || "app" + (i + 1)) + ") ---\nDescription: " + S.apps[i].desc + "\nCode:\n" + S.apps[i].code.slice(0, 40000);
    }).join("\n\n");
    return [
      "You are a Supabase/PostgreSQL expert. Write the complete SQL setup for the app(s) below.", "", apps, "",
      "Rules:",
      "- PostgreSQL for Supabase, schema public. Must be idempotent: create table if not exists, add column if not exists, drop policy if exists before create policy.",
      "- Every table: uuid primary key default gen_random_uuid(), created_at timestamptz default now(), proper types, NOT NULL, constraints, indexes for real query patterns, foreign keys.",
      "- Enable row level security on every table and write explicit policies for select, insert, update and delete. If the app has accounts or per-user data, tie rows to auth.uid() (user_id uuid default auth.uid() references auth.users). If it has no login, allow the anon and authenticated roles.",
      "- Add the needed grants for anon and authenticated, and add tables to the supabase_realtime publication when the app needs live updates.",
      shared ? "- These two apps SHARE one database: design shared tables both use, with neutral names (no app prefix), so data written by one app is visible to the other as appropriate." :
               "- Prefix every table name with the app short name (lowercase snake_case) so it cannot collide with other apps.",
      "- Start with a comment block listing each table and its columns.",
      "Output only SQL, no prose, no markdown fences."
    ].join("\n");
  }
  function wirePrompt(a, sql, shared) {
    return ["You are a senior Flutter engineer. Here is a Flutter project:", "", a.code, "",
      "Its Supabase database was created with this SQL:", sql, "",
      "Task: connect the app to Supabase using the supabase_flutter package and replace any local-only data storage with this exact schema (table and column names must match the SQL).",
      "- Add supabase_flutter (caret version) to pubspec.yaml, keep the other dependencies.",
      "- In main(): WidgetsFlutterBinding.ensureInitialized() then await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey) with import 'supabase_config.dart'. That file already exists and defines the two constants; do NOT output it.",
      "- Put data access in a repository/service class. Handle errors with user-visible messages in the app's UI language.",
      shared ? "- This app shares the database with another app; use only the shared tables from the SQL and never delete other users' data." : "",
      "- Output ONLY the files that changed or are new, each complete.", RULES, FORMAT].join("\n");
  }

  function fixPrompt(a, errs) {
    return ["You are a senior Flutter engineer. This Flutter project failed `flutter build apk --release` on the latest stable Flutter SDK.", "",
      "BUILD ERRORS (from the compiler):", errs.slice(0, 9000), "",
      "PROJECT:", a.code, "",
      "Fix EVERY error shown, and also every identical mistake anywhere else in the project (search all files for the same wrong class, parameter or color name, even if it is not listed above). Do not change behavior, design or the package name. Do not output lib/supabase_config.dart.",
      RULES, "Output ONLY the files that changed, each complete.", FORMAT].join("\n");
  }

  /* ---------- Supabase ---------- */
  async function sbApi(path, opts) {
    var r = await fetch("https://api.supabase.com" + path, Object.assign({}, opts, { headers: Object.assign({ Authorization: "Bearer " + S.keys.sb_token, "Content-Type": "application/json" }, (opts || {}).headers) }));
    var txt = await r.text(), data; try { data = JSON.parse(txt); } catch (e) { data = txt; }
    if (!r.ok) throw new Error("Supabase " + r.status + ": " + (data && data.message ? data.message : String(txt).slice(0, 200)));
    return data;
  }
  async function sbAnon() {
    var keys = await sbApi("/v1/projects/" + S.keys.sb_ref + "/api-keys", { method: "GET" });
    var k = keys.find(function (x) { return x.name === "anon"; }) || keys.find(function (x) { return /anon/.test(x.name || ""); });
    if (!k) throw new Error("لم أجد مفتاح anon في المشروع.");
    return k.api_key;
  }
  async function sbRun(sql) { return sbApi("/v1/projects/" + S.keys.sb_ref + "/database/query", { method: "POST", body: JSON.stringify({ query: sql }) }); }

  /* ---------- GitHub ---------- */
  async function gh(path, opts) {
    return fetch("https://api.github.com" + path, Object.assign({}, opts, { headers: Object.assign({ Authorization: "Bearer " + S.keys.gh_token, Accept: "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28" }, (opts || {}).headers) }));
  }
  async function ghJson(path, opts) {
    var r = await gh(path, opts); var d = await r.json().catch(function () { return {}; });
    if (!r.ok) { var e = new Error("GitHub " + r.status + ": " + (d.message || "")); e.status = r.status; throw e; }
    return d;
  }
  function encPath(p) { return p.split("/").map(encodeURIComponent).join("/"); }

  /* ---------- سجل ---------- */
  function logTo(node, msg, cls) {
    node.classList.add("on");
    var line = document.createElement("div");
    if (cls) line.className = cls;
    line.textContent = new Date().toLocaleTimeString("en-GB") + "  " + msg;
    node.appendChild(line);
    while (node.childNodes.length > 80) node.removeChild(node.firstChild);
    node.scrollTop = node.scrollHeight;
    return line;
  }
  function logApps(idxs, msg, cls) { idxs.forEach(function (i) { logTo($("log-" + i), msg, cls); }); }

  /* ---------- واجهة المفاتيح ---------- */
  var KEYFIELDS = [
    ["gh_token", "GitHub Access Token", true], ["gh_repo", "مشروع GitHub (owner/repo)", false],
    ["sb_token", "Supabase Access Token", true], ["sb_ref", "Supabase Project Ref", false],
    ["gemini", "مفتاح Gemini API", true], ["gemini_model", "نموذج Gemini", false],
    ["gemini_x1", "مفتاح Gemini إضافي 1", true], ["gemini_x2", "مفتاح Gemini إضافي 2", true], ["gemini_x3", "مفتاح Gemini إضافي 3", true],
    ["claude", "مفتاح Claude API", true], ["claude_model", "نموذج Claude", false]
  ];
  function secretInput(value, onInput, id) {
    var inp = el("input", { type: "password", class: "ltr", autocomplete: "off", spellcheck: "false" });
    if (id) inp.id = id;
    inp.value = value || "";
    inp.addEventListener("input", function () { onInput(inp.value); });
    var tog = el("button", { type: "button", class: "btn small", text: "إظهار" });
    tog.onclick = function () { var show = inp.type === "password"; inp.type = show ? "text" : "password"; tog.textContent = show ? "إخفاء" : "إظهار"; };
    return el("div", { class: "inline" }, [inp, tog]);
  }
  function renderKeys() {
    var g = $("keyGrid"); g.textContent = "";
    KEYFIELDS.forEach(function (f) {
      var k = f[0], box = el("div", { class: "field" });
      box.appendChild(el("label", { class: "lbl", for: "k-" + k, text: f[1] }));
      if (f[2]) box.appendChild(secretInput(S.keys[k], function (v) { S.keys[k] = v.trim(); save(); }, "k-" + k));
      else {
        var inp = el("input", { type: "text", class: "ltr", id: "k-" + k, autocomplete: "off", spellcheck: "false" });
        inp.value = S.keys[k] || "";
        inp.addEventListener("input", function () { S.keys[k] = inp.value.trim(); save(); });
        box.appendChild(inp);
      }
      g.appendChild(box);
    });
    renderExtras();
  }
  function renderExtras() {
    var box = $("extras"); box.textContent = "";
    S.extras.forEach(function (row, i) {
      var n = el("input", { type: "text", placeholder: "الاسم", "aria-label": "اسم المفتاح " + (i + 1) });
      n.value = row.n; n.addEventListener("input", function () { row.n = n.value; save(); });
      var v = secretInput(row.v, function (x) { row.v = x; save(); });
      v.querySelector("input").setAttribute("aria-label", "قيمة المفتاح " + (i + 1));
      var rm = el("button", { type: "button", class: "btn small", text: "حذف" });
      rm.onclick = function () { S.extras.splice(i, 1); save(); renderExtras(); };
      box.appendChild(el("div", { class: "extra" }, [n, v, rm]));
    });
  }
  $("addExtra").onclick = function () { S.extras.push({ n: "", v: "" }); save(); renderExtras(); };

  var TESTS = {
    github: async function () {
      if (!S.keys.gh_token) throw new Error("أدخل توكن GitHub.");
      var u = await ghJson("/user"); var msg = "GitHub: متصل كمستخدم " + u.login;
      if (S.keys.gh_repo) { try { await ghJson("/repos/" + S.keys.gh_repo); msg += "، والمشروع موجود."; } catch (e) { msg += "، والمشروع غير موجود وسيُنشأ عند البناء."; } }
      return msg;
    },
    supabase: async function () {
      if (!S.keys.sb_token || !S.keys.sb_ref) throw new Error("أدخل توكن Supabase والـ Project Ref.");
      var p = await sbApi("/v1/projects/" + S.keys.sb_ref, { method: "GET" });
      return "Supabase: متصل بالمشروع " + (p.name || S.keys.sb_ref);
    },
    claude: async function () { await ai("claude", "Reply with: ok"); return "Claude: يعمل."; },
    gemini: async function () { await ai("gemini", "Reply with: ok"); return "Gemini: يعمل."; }
  };
  document.querySelectorAll("[data-test]").forEach(function (b) {
    b.onclick = async function () {
      var out = $("testOut"); out.className = "note"; out.textContent = "جارٍ الاختبار...";
      try { out.textContent = await TESTS[b.dataset.test](); out.className = "note ok"; }
      catch (e) { out.textContent = errMsg(e); out.className = "note err"; }
    };
  });

  /* ---------- واجهة الأكواد ---------- */
  var editing = [false, false];
  function busy(btn, fn) {
    return async function () {
      btn.disabled = true; var old = btn.textContent; keepAwake(true);
      try { await fn(); } finally { btn.disabled = false; btn.textContent = old; keepAwake(false); }
    };
  }
  function lock(i) { var ta = $("code-" + i); ta.readOnly = !!ta.value && !editing[i]; $("editrow-" + i).hidden = !editing[i]; $("edit-" + i).textContent = editing[i] ? "قفل التعديل" : "تعديل الكود"; }
  function setCode(i, text) { S.apps[i].code = text; $("code-" + i).value = text; save(); lock(i); }
  function showSql(i) {
    var d = $("sql-" + i), a = S.apps[i]; d.hidden = !a.sql; d.querySelector("pre").textContent = a.sql || "";
  }

  function acc(i, key, title, open, kids) {
    var d = el("details", { class: "acc", name: "acc-" + i }, [el("summary", { text: title }), el("div", { class: "body" }, kids)]);
    if (open) d.open = true; d.id = "acc-" + key + "-" + i; return d;
  }
  /* ---------- أيقونة التطبيق ---------- */
  function loadImg(src) {
    return new Promise(function (res, rej) {
      var im = new Image();
      im.onload = function () { res(im); };
      im.onerror = function () { rej(new Error("تعذر قراءة الصورة. جرّب صورة PNG أو JPG.")); };
      im.src = src;
    });
  }
  function squarePng(im, size) {
    var c = document.createElement("canvas"); c.width = size; c.height = size;
    var x = c.getContext("2d"), w = im.naturalWidth || im.width, h = im.naturalHeight || im.height, s = Math.min(w, h);
    x.imageSmoothingQuality = "high";
    x.drawImage(im, (w - s) / 2, (h - s) / 2, s, s, 0, 0, size, size);
    return c.toDataURL("image/png");
  }
  async function makeIcon(file) {
    if (!/^image\//.test(file.type || "")) throw new Error("اختر ملف صورة.");
    var url = URL.createObjectURL(file);
    try { return squarePng(await loadImg(url), 256); } finally { URL.revokeObjectURL(url); }
  }
  function iconField(i) {
    return el("div", { class: "field" }, [
      el("label", { class: "lbl", text: "أيقونة التطبيق (اختياري)" }),
      el("div", { class: "row", style: "align-items:center" }, [
        el("img", { id: "iconimg-" + i, alt: "أيقونة التطبيق", style: "width:56px;height:56px;border-radius:12px;object-fit:cover;display:none" }),
        el("button", { class: "btn", id: "iconpick-" + i, type: "button", text: "اختر صورة من المعرض" }),
        el("button", { class: "btn small", id: "iconrm-" + i, type: "button", text: "إزالة" })
      ]),
      el("input", { type: "file", id: "iconfile-" + i, accept: "image/*", style: "display:none" }),
      el("p", { class: "note", text: "تُقصّ الصورة مربعة من المنتصف، وتُطبَّق كأيقونة للتطبيق عند بناء الـ APK." })
    ]);
  }
  function showIcon(i) {
    var a = S.apps[i], img = $("iconimg-" + i);
    if (a.icon) img.src = a.icon;
    img.style.display = a.icon ? "block" : "none";
    $("iconrm-" + i).hidden = !a.icon;
  }

  function card(i) {
    var c = el("div", { class: "pane" });
    var g = el("div", { class: "grid" });
    g.appendChild(el("div", { class: "field" }, [el("label", { class: "lbl", for: "name-" + i, text: "اسم التطبيق" }), el("input", { type: "text", id: "name-" + i, placeholder: "اكتب أي اسم" })]));
    g.appendChild(el("div", { class: "field" }, [el("label", { class: "lbl", for: "prov-" + i, text: "الذكاء الاصطناعي" }), el("select", { id: "prov-" + i }, [el("option", { value: "claude", text: "Claude" }), el("option", { value: "gemini", text: "Gemini" })])]));
    c.appendChild(acc(i, "desc", "1. وصف التطبيق والتوليد", true, [g, iconField(i),
      el("div", { class: "field" }, [el("label", { class: "lbl", for: "desc-" + i, text: "وصف التطبيق (إذا تريد أن ينشئ الذكاء الاصطناعي الكود والتطبيق)" }), el("textarea", { id: "desc-" + i, placeholder: "مثال: تطبيق متتبع مصروفات شخصي بتصنيفات وإحصائيات شهرية" })]),
      el("div", { class: "row" }, [el("button", { class: "btn primary", id: "gen-" + i, type: "button", text: "ولّد الكود بالذكاء الاصطناعي" })])]));
    var er = el("div", { class: "inline", id: "editrow-" + i }, [el("input", { type: "text", id: "editin-" + i, placeholder: "اكتب التعديل المطلوب وسيطبقه الذكاء الاصطناعي", "aria-label": "التعديل المطلوب" }), el("button", { class: "btn primary", id: "editgo-" + i, type: "button", text: "طبّق" })]);
    er.hidden = true;
    c.appendChild(acc(i, "code", "2. الكود والمعاينة", false, [
      el("div", { class: "field" }, [el("label", { class: "lbl", for: "code-" + i, text: "الكود (اكتبه هنا أو الصقه، بصيغة === FILE: المسار ===)" }), el("textarea", { id: "code-" + i, class: "code ltr", spellcheck: "false" })]),
      el("div", { class: "row" }, [el("button", { class: "btn", id: "prev-" + i, type: "button", text: "معاينة" }), el("button", { class: "btn", id: "edit-" + i, type: "button", text: "تعديل الكود" })]), er]));
    var det = el("details", { id: "sql-" + i }, [el("summary", { text: "SQL المُنشأ (جدول وصلاحيات)" }), el("div", { class: "row", style: "margin-top:8px" }, [el("button", { class: "btn small", id: "sqlcopy-" + i, type: "button", text: "نسخ SQL" })]), el("pre")]);
    det.hidden = true;
    c.appendChild(acc(i, "sb", "3. الربط بـ Supabase", false, [
      el("p", { class: "note", text: "ينشئ SQL للجدول والصلاحيات، يعدّل الكود، وينفّذ SQL على مشروعك." }),
      el("div", { class: "row" }, [el("button", { class: "btn", id: "link-" + i, type: "button", text: "ربط التطبيق عبر Supabase" })]), det]));
    c.appendChild(el("div", { class: "log", id: "log-" + i }));
    return c;
  }

  function bindCard(i) {
    var a = S.apps[i];
    $("name-" + i).value = a.name; $("desc-" + i).value = a.desc; $("prov-" + i).value = a.provider; $("code-" + i).value = a.code;
    $("name-" + i).oninput = function () { a.name = this.value; save(); renderBuildSelect(); };
    $("desc-" + i).oninput = function () { a.desc = this.value; save(); };
    $("prov-" + i).onchange = function () { a.provider = this.value; save(); };
    $("code-" + i).oninput = function () { a.code = this.value; save(); lock(i); };
    lock(i); showSql(i); showIcon(i);
    $("iconpick-" + i).onclick = function () { $("iconfile-" + i).click(); };
    $("iconfile-" + i).onchange = async function () {
      var f = this.files && this.files[0]; if (!f) return;
      try {
        a.icon = await makeIcon(f); save(); showIcon(i);
        logTo($("log-" + i), "تم اختيار الأيقونة. ستُطبَّق عند بناء الـ APK.", "g");
      } catch (e) { logTo($("log-" + i), errMsg(e), "e"); }
      try { this.value = ""; } catch (e2) {}
    };
    $("iconrm-" + i).onclick = function () { a.icon = ""; save(); showIcon(i); };

    $("gen-" + i).onclick = busy($("gen-" + i), async function () {
      if (!a.desc.trim()) return logTo($("log-" + i), "اكتب وصف التطبيق أولاً.", "e");
      var pl = logTo($("log-" + i), "جارٍ توليد الكود بواسطة " + a.provider + " ...");
      try {
        var files = parseFiles(await ai(a.provider, genPrompt(a), function (n) { pl.textContent = "جارٍ الكتابة... " + n + " حرف"; }));
        if (!files.length) throw new Error("لم يرجع الذكاء الاصطناعي ملفات.");
        editing[i] = false; setCode(i, serialize(files));
        logTo($("log-" + i), "تم توليد " + files.length + " ملف.", "g");
      } catch (e) { logTo($("log-" + i), errMsg(e), "e"); }
    });
    $("edit-" + i).onclick = function () { editing[i] = !editing[i]; lock(i); if (editing[i]) $("code-" + i).focus(); };
    $("editgo-" + i).onclick = busy($("editgo-" + i), async function () {
      var ins = $("editin-" + i).value.trim();
      if (!ins || !a.code.trim()) return logTo($("log-" + i), "اكتب التعديل وتأكد من وجود كود.", "e");
      var pe = logTo($("log-" + i), "جارٍ تطبيق التعديل...");
      try {
        var nf = parseFiles(await ai(a.provider, editPrompt(a, ins), function (n) { pe.textContent = "جارٍ الكتابة... " + n + " حرف"; }));
        if (!nf.length) throw new Error("لم يرجع الذكاء الاصطناعي ملفات.");
        setCode(i, merge(a.code, nf)); $("editin-" + i).value = "";
        logTo($("log-" + i), "عُدّل: " + nf.map(function (f) { return f.path; }).join("، "), "g");
      } catch (e) { logTo($("log-" + i), errMsg(e), "e"); }
    });
    $("prev-" + i).onclick = busy($("prev-" + i), async function () {
      if (!a.code.trim()) return logTo($("log-" + i), "لا يوجد كود للمعاينة.", "e");
      logTo($("log-" + i), "جارٍ تجهيز المعاينة...");
      try {
        var html = stripFences(await ai(a.provider, previewPrompt(a)));
        $("prevFrame").srcdoc = html; $("prevDlg").showModal();
        logTo($("log-" + i), "المعاينة جاهزة (تقريبية، ليست Flutter الفعلي).", "g");
      } catch (e) { logTo($("log-" + i), errMsg(e), "e"); }
    });
    $("link-" + i).onclick = busy($("link-" + i), function () { return linkApps([i], false, i); });
    $("sqlcopy-" + i).onclick = async function () { try { await navigator.clipboard.writeText(a.sql); this.textContent = "تم النسخ"; } catch (e) { this.textContent = "حدد النص وانسخه"; } };
  }
  $("prevClose").onclick = function () { $("prevDlg").close(); $("prevFrame").srcdoc = ""; };

  function renderCodes() {
    var p = $("pane-codes"); p.textContent = "";
    var bar = el("nav", { class: "tabs sub", "aria-label": "التطبيقات" }), cards = [], btns = [], cur = 0;
    function show(i) {
      cur = i;
      cards.forEach(function (x, j) { x.hidden = j !== i; });
      btns.forEach(function (y, j) { y.setAttribute("aria-selected", j === i ? "true" : "false"); });
    }
    [0, 1].forEach(function (i) {
      var b = el("button", { type: "button", text: "التطبيق " + ORD[i], "aria-selected": i === 0 ? "true" : "false" });
      var c = card(i); c.hidden = i !== 0; cards.push(c); btns.push(b);
      b.onclick = function () { show(i); };
    });
    var both = el("button", { type: "button", class: "linkboth", id: "both", text: "ربط التطبيقين عبر Supabase" });
    both.onclick = busy(both, function () { return linkApps([0, 1], true, cur); });
    bar.appendChild(btns[0]); bar.appendChild(both); bar.appendChild(btns[1]);
    p.appendChild(bar); cards.forEach(function (c) { p.appendChild(c); });
    bindCard(0); bindCard(1);
  }

  /* ---------- الربط عبر Supabase ---------- */
  async function linkApps(idxs, shared, trigger) {
    var provider = S.apps[trigger].provider, L = function (m, c) { logApps(idxs, m, c); };
    for (var q = 0; q < idxs.length; q++) {
      var ap = S.apps[idxs[q]];
      if (!ap.code.trim()) { L("التطبيق " + ORD[idxs[q]] + " بلا كود. ولّد الكود أولاً.", "e"); return; }
    }
    try {
      L("إنشاء SQL للجدول والصلاحيات...");
      var sql = stripFences(await ai(provider, sqlPrompt(idxs, shared)));
      if (!/create\s+table/i.test(sql)) throw new Error("لم يرجع SQL صالحاً.");
      idxs.forEach(function (i) { S.apps[i].sql = sql; showSql(i); }); save();
      L("تم إنشاء SQL.", "g");

      var url = S.keys.sb_ref ? "https://" + S.keys.sb_ref + ".supabase.co" : "https://YOUR_PROJECT_REF.supabase.co", anon = "PASTE_ANON_KEY";
      if (S.keys.sb_token && S.keys.sb_ref) {
        try { anon = await sbAnon(); L("تم جلب مفتاح anon من المشروع.", "g"); }
        catch (e) { L("تعذر جلب مفتاح anon: " + errMsg(e) + " (ضعه يدوياً في lib/supabase_config.dart)", "e"); }
      } else L("لم تدخل توكن Supabase أو Project Ref، سأضع قيماً مؤقتة في lib/supabase_config.dart.", "e");
      var cfg = { path: "lib/supabase_config.dart", content: "// Generated by apk apps. The anon key is public by design; access is controlled by RLS policies.\nconst supabaseUrl = '" + url + "';\nconst supabaseAnonKey = '" + anon + "';\n" };

      for (var k = 0; k < idxs.length; k++) {
        var i = idxs[k], a = S.apps[i];
        L("ربط كود التطبيق " + ORD[i] + " بـ Supabase...");
        var nf = parseFiles(await ai(S.apps[i].provider, wirePrompt(a, sql, shared)));
        if (!nf.length) throw new Error("لم يرجع الذكاء الاصطناعي ملفات للتطبيق " + ORD[i] + ".");
        nf = nf.filter(function (f) { return f.path !== cfg.path; }); nf.push(cfg);
        editing[i] = false; setCode(i, merge(a.code, nf));
        L("تم تعديل " + nf.length + " ملف في التطبيق " + ORD[i] + ".", "g");
      }

      if (S.keys.sb_token && S.keys.sb_ref) {
        L("تنفيذ SQL على مشروع Supabase...");
        try { await sbRun(sql); L("تم إنشاء الجداول والصلاحيات في Supabase.", "g"); }
        catch (e) { L("تعذر تنفيذ SQL تلقائياً: " + errMsg(e) + " انسخ SQL من القائمة أدناه ونفّذه في SQL Editor.", "e"); }
      } else L("لتنفيذ SQL تلقائياً أدخل توكن Supabase والـ Project Ref. الـ SQL جاهز للنسخ أدناه.", "e");
    } catch (e) { L(errMsg(e), "e"); }
  }

  /* ---------- البناء ---------- */
  function renderBuildSelect() {
    var s = $("buildApp"), v = s.value; s.textContent = "";
    S.apps.forEach(function (a, i) { s.appendChild(el("option", { value: String(i), text: "التطبيق " + ORD[i] + (a.name ? " - " + a.name : "") })); });
    if (v) s.value = v;
  }
  function workflow(slug, label) {
    var safe = (label || slug).replace(/["'&<>#\\|\n\r]/g, " ").trim() || slug;
    var d = "apps/" + slug;
    return [
      "name: build-" + slug, "on:", "  workflow_dispatch:", "permissions:", "  contents: write",
      "jobs:", "  build:", "    runs-on: ubuntu-latest", "    defaults:", "      run:", "        working-directory: " + d, "    steps:",
      "      - uses: actions/checkout@v4",
      "      - uses: actions/setup-java@v4", "        with:", "          distribution: temurin", "          java-version: '17'",
      "      - uses: subosito/flutter-action@v2", "        with:", "          channel: stable", "          cache: true",
      "      - name: Add Android platform", "        run: |",
      "          flutter create --platforms=android --project-name " + slug + " _scaffold",
      "          cp -r _scaffold/android ./android", "          rm -rf _scaffold",
      "          sed -i 's#<application#<uses-permission android:name=\"android.permission.INTERNET\"/>\\n    <application#' android/app/src/main/AndroidManifest.xml",
      "          sed -i 's#android:label=\"[^\"]*\"#android:label=\"" + safe + "\"#' android/app/src/main/AndroidManifest.xml",
      "      - name: Apply app icon (if provided)",
      "        run: |",
      "          if [ -d app_icon ]; then cp -r app_icon/mipmap-* android/app/src/main/res/; fi",
      "      - name: Fix known version conflicts",
      "        run: |",
      "          sed -i -E 's/^([[:space:]]*intl:).*/\\1 any/' pubspec.yaml",
      "      - name: Get packages",
      "        run: |",
      "          set -o pipefail",
      "          (flutter pub get || flutter pub upgrade --major-versions) 2>&1 | tee -a \"$RUNNER_TEMP/build.log\"",
      "      - name: Signing key (created once, then reused for every build)",
      "        run: |",
      "          KS=\"$GITHUB_WORKSPACE/keystores/" + slug + ".jks\"",
      "          PWF=\"$GITHUB_WORKSPACE/keystores/" + slug + ".pass\"",
      "          mkdir -p \"$GITHUB_WORKSPACE/keystores\"",
      "          if [ ! -f \"$KS\" ]; then",
      "            PW=$(openssl rand -hex 16)",
      "            keytool -genkeypair -keystore \"$KS\" -alias key -keyalg RSA -keysize 2048 -validity 36500 -storepass \"$PW\" -keypass \"$PW\" -dname \"CN=" + slug + ", O=apk apps, C=SA\"",
      "            echo \"$PW\" > \"$PWF\"",
      "            git -C \"$GITHUB_WORKSPACE\" config user.name apk-apps",
      "            git -C \"$GITHUB_WORKSPACE\" config user.email apk-apps@users.noreply.github.com",
      "            git -C \"$GITHUB_WORKSPACE\" add keystores",
      "            git -C \"$GITHUB_WORKSPACE\" commit -m \"apk apps: signing key for " + slug + "\"",
      "            git -C \"$GITHUB_WORKSPACE\" push",
      "          fi",
      "      - name: Build APK",
      "        run: |",
      "          set -o pipefail",
      "          flutter build apk --release 2>&1 | tee -a \"$RUNNER_TEMP/build.log\"",
      "      - name: Sign APK with the fixed key",
      "        run: |",
      "          SDK=\"${ANDROID_HOME:-$ANDROID_SDK_ROOT}\"",
      "          APKSIGNER=$(ls \"$SDK\"/build-tools/*/apksigner | sort -V | tail -1)",
      "          PW=$(cat \"$GITHUB_WORKSPACE/keystores/" + slug + ".pass\")",
      "          \"$APKSIGNER\" sign --ks \"$GITHUB_WORKSPACE/keystores/" + slug + ".jks\" --ks-pass pass:\"$PW\" --key-pass pass:\"$PW\" --out build/app/outputs/flutter-apk/" + slug + ".apk build/app/outputs/flutter-apk/app-release.apk",
      "          \"$APKSIGNER\" verify --print-certs build/app/outputs/flutter-apk/" + slug + ".apk",
      "      - uses: softprops/action-gh-release@v2", "        with:",
      "          tag_name: " + slug + "-${{ github.run_number }}",
      "          name: " + slug + " build ${{ github.run_number }}",
      "          files: " + d + "/build/app/outputs/flutter-apk/" + slug + ".apk",
      "      - name: Save build errors for the app (auto-fix)",
      "        if: failure()",
      "        run: |",
      "          LOG=\"$RUNNER_TEMP/build.log\"",
      "          OUT=\"$GITHUB_WORKSPACE/build-logs/" + slug + "-${{ github.run_id }}.txt\"",
      "          mkdir -p \"$GITHUB_WORKSPACE/build-logs\"",
      "          if [ -f \"$LOG\" ]; then",
      "            grep -E -B1 -A4 'Error:|error:|What went wrong|Because |version solving failed|Could not|Unresolved' \"$LOG\" | sed -E 's/\\x1b\\[[0-9;]*[A-Za-z]//g' | head -c 12000 > \"$OUT\" || true",
      "          fi",
      "          [ -s \"$OUT\" ] || echo \"NO_DART_ERRORS\" > \"$OUT\"",
      "          git -C \"$GITHUB_WORKSPACE\" config user.name apk-apps",
      "          git -C \"$GITHUB_WORKSPACE\" config user.email apk-apps@users.noreply.github.com",
      "          git -C \"$GITHUB_WORKSPACE\" add build-logs",
      "          git -C \"$GITHUB_WORKSPACE\" commit -m \"apk apps: build errors " + slug + "\" || true",
      "          git -C \"$GITHUB_WORKSPACE\" pull --rebase || true",
      "          git -C \"$GITHUB_WORKSPACE\" push || true", ""
    ].join("\n");
  }
  var lastApk = null;
  async function putB64(repo, path, b64content, msg) {
    var sha; try { var cur = await ghJson("/repos/" + repo + "/contents/" + encPath(path)); sha = cur.sha; } catch (e) {}
    var body = { message: msg, content: b64content }; if (sha) body.sha = sha;
    await ghJson("/repos/" + repo + "/contents/" + encPath(path), { method: "PUT", body: JSON.stringify(body) });
  }
  async function putFile(repo, path, content, msg) { return putB64(repo, path, b64(content), msg); }
  async function delFile(repo, path, msg) {
    try {
      var cur = await ghJson("/repos/" + repo + "/contents/" + encPath(path));
      await ghJson("/repos/" + repo + "/contents/" + encPath(path), { method: "DELETE", body: JSON.stringify({ message: msg, sha: cur.sha }) });
    } catch (e) {}
  }
  var ICON_DIRS = [["mdpi", 48], ["hdpi", 72], ["xhdpi", 96], ["xxhdpi", 144], ["xxxhdpi", 192]];
  var MAX_FIX = 3, NO_CODE_ERR = "NO_DART_ERRORS";
  function dec64(s) {
    var t = String(s || "").replace(/\s+/g, "");
    try { return decodeURIComponent(escape(atob(t))); } catch (e) { try { return atob(t); } catch (e2) { return ""; } }
  }
  async function getBuildErrors(repo, slug, runId) {
    for (var n = 0; n < 4; n++) {
      try {
        var f = await ghJson("/repos/" + repo + "/contents/" + encPath("build-logs/" + slug + "-" + runId + ".txt"));
        return dec64(f.content).trim();
      } catch (e) { await sleep(3000); }
    }
    return "";
  }
  async function buildOnce(repo, wf, branch, L, st) {
    var t0 = new Date(Date.now() - 30000).toISOString(), ok = false;
    for (var n = 0; n < 8 && !ok; n++) {
      var r = await gh("/repos/" + repo + "/actions/workflows/" + wf + "/dispatches", { method: "POST", body: JSON.stringify({ ref: branch }) });
      if (r.status === 204) ok = true;
      else if (r.status === 404 && n < 7) await sleep(5000);
      else { var dj = await r.json().catch(function () { return {}; }); throw new Error("تعذر تشغيل البناء: " + r.status + " " + (dj.message || "") + " (تأكد أن Actions مفعّل وأن التوكن يملك صلاحية workflow)"); }
    }
    L("بدأ البناء على GitHub، جارٍ المتابعة...");
    var run = null;
    for (var w = 0; w < 20 && !run; w++) {
      await sleep(5000);
      var lst = await ghJson("/repos/" + repo + "/actions/workflows/" + wf + "/runs?event=workflow_dispatch&per_page=5");
      run = (lst.workflow_runs || []).find(function (x) { return x.created_at >= t0; }) || null;
    }
    if (!run) throw new Error("لم أجد تشغيل البناء على GitHub.");
    L("رابط التشغيل: " + run.html_url);
    var last = "";
    for (var p = 0; p < 240; p++) {
      run = await ghJson("/repos/" + repo + "/actions/runs/" + run.id);
      if (run.status !== last) { last = run.status; L("الحالة: " + run.status); st.textContent = "الحالة: " + run.status; }
      if (run.status === "completed") break;
      await sleep(10000);
    }
    if (run.status !== "completed") throw new Error("انتهت مهلة الانتظار. تابع البناء من الرابط أعلاه.");
    return run;
  }
  $("buildGo").onclick = async function () {
    var btn = this, log = $("buildLog"), st = $("buildState"), i = +$("buildApp").value, a = S.apps[i], K = S.keys;
    log.textContent = ""; $("buildResult").hidden = true; lastApk = null;
    var L = function (m, c) { return logTo(log, m, c); };
    var files = parseFiles(a.code);
    if (!files.length || !files.some(function (f) { return f.path === "pubspec.yaml"; })) { L("لا يوجد مشروع صالح في هذا التطبيق (يلزم pubspec.yaml).", "e"); return; }
    if (!K.gh_token || !K.gh_repo || !/^[\w.-]+\/[\w.-]+$/.test(K.gh_repo)) { L("أدخل توكن GitHub واسم المشروع بصيغة owner/repo في قائمة المفاتيح.", "e"); return; }
    btn.disabled = true; st.textContent = ""; keepAwake(true);
    var repo = K.gh_repo, slug = pubName(files) || "app" + (i + 1), wf = "build-" + slug + ".yml";
    try {
      var info;
      try { info = await ghJson("/repos/" + repo); L("المشروع موجود: " + repo); }
      catch (e) {
        if (e.status !== 404) throw e;
        L("المشروع غير موجود، جارٍ إنشاؤه (خاص)...");
        info = await ghJson("/user/repos", { method: "POST", body: JSON.stringify({ name: repo.split("/")[1], private: true, auto_init: true }) });
        await sleep(3000);
      }
      var branch = info.default_branch || "main";
      L("رفع " + files.length + " ملف إلى apps/" + slug + " ...");
      for (var f = 0; f < files.length; f++) await putFile(repo, "apps/" + slug + "/" + files[f].path, files[f].content, "apk apps: " + slug);
      if (a.icon) {
        L("رفع أيقونة التطبيق...");
        var iconImg = await loadImg(a.icon);
        for (var di = 0; di < ICON_DIRS.length; di++) {
          await putB64(repo, "apps/" + slug + "/app_icon/mipmap-" + ICON_DIRS[di][0] + "/ic_launcher.png", squarePng(iconImg, ICON_DIRS[di][1]).split(",")[1], "apk apps: icon " + slug);
        }
      } else {
        for (var dj = 0; dj < ICON_DIRS.length; dj++) await delFile(repo, "apps/" + slug + "/app_icon/mipmap-" + ICON_DIRS[dj][0] + "/ic_launcher.png", "apk apps: remove icon " + slug);
      }
      await putFile(repo, ".github/workflows/" + wf, workflow(slug, a.name), "apk apps: workflow " + slug);
      L("تم رفع الكود وملف البناء.", "g");

      var attempt = 0, run;
      while (true) {
        run = await buildOnce(repo, wf, branch, L, st);
        if (run.conclusion === "success") break;
        var errs = await getBuildErrors(repo, slug, run.id);
        if (!errs || errs.indexOf(NO_CODE_ERR) === 0 || attempt >= MAX_FIX) {
          throw new Error("فشل البناء (" + run.conclusion + ")." + (attempt ? " جُرّب الإصلاح التلقائي " + attempt + " مرة ولم ينجح." : "") + " افتح سجل التشغيل لمعرفة السبب: " + run.html_url);
        }
        attempt++;
        L("فشل البناء بسبب أخطاء في الكود. إصلاح تلقائي (" + attempt + " من " + MAX_FIX + ")...", "e");
        st.textContent = "إصلاح تلقائي " + attempt + "/" + MAX_FIX;
        var pf = L("الذكاء الاصطناعي يقرأ الأخطاء ويصلح الكود...");
        var fixed = parseFiles(await ai(a.provider, fixPrompt(a, errs), function (n) { pf.textContent = "جارٍ الإصلاح... " + n + " حرف"; }));
        fixed = fixed.filter(function (x) { return x.path !== "lib/supabase_config.dart" && !/(^|\/)\.\.(\/|$)/.test(x.path); });
        var np = fixed.find(function (x) { return x.path === "pubspec.yaml"; });
        if (np && pubName([np]) !== slug) fixed = fixed.filter(function (x) { return x !== np; });
        if (!fixed.length) throw new Error("لم يرجع الذكاء الاصطناعي إصلاحاً. افتح سجل التشغيل: " + run.html_url);
        setCode(i, merge(a.code, fixed));
        for (var q = 0; q < fixed.length; q++) await putFile(repo, "apps/" + slug + "/" + fixed[q].path, fixed[q].content, "apk apps: auto-fix " + slug);
        L("تم إصلاح: " + fixed.map(function (x) { return x.path; }).join("، ") + ". جارٍ إعادة البناء...", "g");
      }

      var rel = await ghJson("/repos/" + repo + "/releases/tags/" + slug + "-" + run.run_number);
      var asset = (rel.assets || []).find(function (x) { return /\.apk$/i.test(x.name); });
      if (!asset) throw new Error("نجح البناء لكن لم أجد ملف APK في الإصدار.");
      L("اكتمل البناء: " + asset.name + " (" + (asset.size / 1048576).toFixed(1) + " MB)", "g");
      lastApk = { asset: asset, name: (a.name || slug).replace(/[\\/:*?"<>|]/g, "_") + ".apk" };
      $("relLink").href = rel.html_url; $("buildResult").hidden = false; st.textContent = "جاهز للتحميل.";
    } catch (e) { L(errMsg(e), "e"); st.textContent = "فشل."; }
    finally { btn.disabled = false; keepAwake(false); }
  };
  $("apkDl").onclick = async function () {
    if (!lastApk) return;
    var log = $("buildLog");
    try {
      logTo(log, "جارٍ تحميل الـ APK...");
      var r = await fetch(lastApk.asset.url, { headers: { Authorization: "Bearer " + S.keys.gh_token, Accept: "application/octet-stream" } });
      if (!r.ok) throw new Error("HTTP " + r.status);
      var blob = await r.blob(), u = URL.createObjectURL(blob), a = document.createElement("a");
      a.href = u; a.download = lastApk.name; document.body.appendChild(a); a.click(); a.remove();
      setTimeout(function () { URL.revokeObjectURL(u); }, 10000);
      logTo(log, "تم التحميل: " + lastApk.name, "g");
    } catch (e) { logTo(log, "تعذر التحميل المباشر (" + errMsg(e) + "). حمّله من صفحة الإصدار على GitHub بالرابط أعلاه.", "e"); }
  };

  document.querySelectorAll("#sub-keys [data-sub]").forEach(function (b) {
    b.onclick = function () {
      var x = b.dataset.sub === "1";
      $("keysMain").hidden = x; $("keysExtra").hidden = !x;
      document.querySelectorAll("#sub-keys button").forEach(function (y) { y.setAttribute("aria-selected", y === b ? "true" : "false"); });
    };
  });
  /* ---------- التبويبات ---------- */
  function showTab(t) {
    S.tab = t; save();
    ["keys", "codes", "build"].forEach(function (k) {
      $("pane-" + k).hidden = k !== t; $("tab-" + k).setAttribute("aria-selected", k === t ? "true" : "false");
    });
  }
  document.querySelectorAll("[data-tab]").forEach(function (b) { b.onclick = function () { showTab(b.dataset.tab); }; });

  renderKeys(); renderCodes(); renderBuildSelect(); showTab(S.tab || "keys");
})();