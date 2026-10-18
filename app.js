(function () {
  "use strict";
  var $ = function (id) { return document.getElementById(id); };
  var ORD = ["الأول", "الثاني"];

  /* ---------- الحالة ---------- */
  var DEF = {
    keys: { gh_token: "", gh_repo: "", sb_token: "", sb_ref: "", gemini: "", claude: "", claude_model: "claude-sonnet-5-5", gemini_model: "gemini-3.8-flash", gemini_x1: "", gemini_x2: "", gemini_x3: "" },
    extras: [{ n: "", v: "" }, { n: "", v: "" }, { n: "", v: "" }],
    apps: [{ name: "", desc: "", code: "", provider: "claude", sql: "" }, { name: "", desc: "", code: "", provider: "claude", sql: "" }],
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
    if (/Failed to fetch|NetworkError|Load failed/i.test(m)) return "تعذر الاتصال (شبكة أو منع CORS من المتصفح).";
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
  async function ai(provider, prompt) {
    var K = S.keys, res, data;
    if (provider === "gemini") {
      var gkeys = [K.gemini, K.gemini_x1, K.gemini_x2, K.gemini_x3].filter(Boolean);
      if (!gkeys.length) throw new Error("أدخل مفتاح Gemini في قائمة المفاتيح.");
      var lastErr;
      for (var gi = 0; gi < gkeys.length; gi++) {
        res = await fetch("https://generativelanguage.googleapis.com/v1beta/models/" + encodeURIComponent(K.gemini_model || "gemini-3.8-flash") + ":generateContent", {
          method: "POST", headers: { "Content-Type": "application/json", "x-goog-api-key": gkeys[gi] },
          body: JSON.stringify({ contents: [{ role: "user", parts: [{ text: prompt }] }], generationConfig: { maxOutputTokens: 32000 } })
        });
        data = await res.json().catch(function () { return {}; });
        if (res.ok) {
          var parts = (data.candidates && data.candidates[0] && data.candidates[0].content && data.candidates[0].content.parts) || [];
          var t = parts.map(function (p) { return p.text || ""; }).join("");
          if (!t) throw new Error("Gemini لم يرجع نصاً.");
          return t;
        }
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
      body: JSON.stringify({ model: K.claude_model || "claude-sonnet-5-5", max_tokens: 16000, messages: [{ role: "user", content: prompt }] })
    });
    data = await res.json().catch(function () { return {}; });
    if (!res.ok) throw new Error("Claude: " + ((data.error && data.error.message) || res.status));
    return (data.content || []).filter(function (c) { return c.type === "text"; }).map(function (c) { return c.text; }).join("");
  }

  var FORMAT = "OUTPUT FORMAT (strict): output only files, no prose before or after, no markdown fences. Each file starts with a line exactly like\n=== FILE: lib/main.dart ===\nfollowed by the full file content.";

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
      "", FORMAT, "Begin with pubspec.yaml."
    ].join("\n");
  }
  function editPrompt(a, instr) {
    return ["You are a senior Flutter engineer. Here is a Flutter project:", "", a.code, "",
      "Apply this change (written by the user, may be Arabic): " + instr, "",
      "Output ONLY the files that changed or are new, each complete.", FORMAT].join("\n");
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
      "- Output ONLY the files that changed or are new, each complete.", FORMAT].join("\n");
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
      var all = document.querySelectorAll("button"); var was = [];
      btn.disabled = true; var old = btn.textContent;
      try { await fn(); } finally { btn.disabled = false; btn.textContent = old; }
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
  function card(i) {
    var c = el("div", { class: "pane" });
    var g = el("div", { class: "grid" });
    g.appendChild(el("div", { class: "field" }, [el("label", { class: "lbl", for: "name-" + i, text: "اسم التطبيق" }), el("input", { type: "text", id: "name-" + i, placeholder: "اكتب أي اسم" })]));
    g.appendChild(el("div", { class: "field" }, [el("label", { class: "lbl", for: "prov-" + i, text: "الذكاء الاصطناعي" }), el("select", { id: "prov-" + i }, [el("option", { value: "claude", text: "Claude" }), el("option", { value: "gemini", text: "Gemini" })])]));
    c.appendChild(acc(i, "desc", "1. وصف التطبيق والتوليد", true, [g,
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
      el("div", { class: "row" }, [el("button", { class: "btn", id: "link-" + i, type: "button", text: "ربط التطبيق عبر Supabase" }), el("button", { class: "btn", id: "both-" + i, type: "button", text: "ربط التطبيقين عبر Supabase" })]), det]));
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
    lock(i); showSql(i);

    $("gen-" + i).onclick = busy($("gen-" + i), async function () {
      if (!a.desc.trim()) return logTo($("log-" + i), "اكتب وصف التطبيق أولاً.", "e");
      logTo($("log-" + i), "جارٍ توليد الكود بواسطة " + a.provider + " (قد يستغرق دقيقة)...");
      try {
        var files = parseFiles(await ai(a.provider, genPrompt(a)));
        if (!files.length) throw new Error("لم يرجع الذكاء الاصطناعي ملفات.");
        editing[i] = false; setCode(i, serialize(files));
        logTo($("log-" + i), "تم توليد " + files.length + " ملف.", "g");
      } catch (e) { logTo($("log-" + i), errMsg(e), "e"); }
    });
    $("edit-" + i).onclick = function () { editing[i] = !editing[i]; lock(i); if (editing[i]) $("code-" + i).focus(); };
    $("editgo-" + i).onclick = busy($("editgo-" + i), async function () {
      var ins = $("editin-" + i).value.trim();
      if (!ins || !a.code.trim()) return logTo($("log-" + i), "اكتب التعديل وتأكد من وجود كود.", "e");
      logTo($("log-" + i), "جارٍ تطبيق التعديل...");
      try {
        var nf = parseFiles(await ai(a.provider, editPrompt(a, ins)));
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
    $("both-" + i).onclick = busy($("both-" + i), function () { return linkApps([0, 1], true, i); });
    $("sqlcopy-" + i).onclick = async function () { try { await navigator.clipboard.writeText(a.sql); this.textContent = "تم النسخ"; } catch (e) { this.textContent = "حدد النص وانسخه"; } };
  }
  $("prevClose").onclick = function () { $("prevDlg").close(); $("prevFrame").srcdoc = ""; };

  function renderCodes() {
    var p = $("pane-codes"); p.textContent = "";
    var bar = el("nav", { class: "tabs sub", "aria-label": "التطبيقات" }), cards = [];
    [0, 1].forEach(function (i) {
      var b = el("button", { type: "button", text: "التطبيق " + ORD[i], "aria-selected": i === 0 ? "true" : "false" });
      var c = card(i); c.hidden = i !== 0; cards.push(c);
      b.onclick = function () { cards.forEach(function (x, j) { x.hidden = j !== i; }); Array.prototype.forEach.call(bar.children, function (y, j) { y.setAttribute("aria-selected", j === i ? "true" : "false"); }); };
      bar.appendChild(b);
    });
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
      "      - run: flutter pub get", "      - run: flutter build apk --release",
      "      - uses: softprops/action-gh-release@v2", "        with:",
      "          tag_name: " + slug + "-${{ github.run_number }}",
      "          name: " + slug + " build ${{ github.run_number }}",
      "          files: " + d + "/build/app/outputs/flutter-apk/app-release.apk", ""
    ].join("\n");
  }
  var lastApk = null;
  async function putFile(repo, path, content, msg) {
    var sha; try { var cur = await ghJson("/repos/" + repo + "/contents/" + encPath(path)); sha = cur.sha; } catch (e) {}
    var body = { message: msg, content: b64(content) }; if (sha) body.sha = sha;
    await ghJson("/repos/" + repo + "/contents/" + encPath(path), { method: "PUT", body: JSON.stringify(body) });
  }
  $("buildGo").onclick = async function () {
    var btn = this, log = $("buildLog"), st = $("buildState"), i = +$("buildApp").value, a = S.apps[i], K = S.keys;
    log.textContent = ""; $("buildResult").hidden = true; lastApk = null;
    var L = function (m, c) { logTo(log, m, c); };
    var files = parseFiles(a.code);
    if (!files.length || !files.some(function (f) { return f.path === "pubspec.yaml"; })) { L("لا يوجد مشروع صالح في هذا التطبيق (يلزم pubspec.yaml).", "e"); return; }
    if (!K.gh_token || !K.gh_repo || !/^[\w.-]+\/[\w.-]+$/.test(K.gh_repo)) { L("أدخل توكن GitHub واسم المشروع بصيغة owner/repo في قائمة المفاتيح.", "e"); return; }
    btn.disabled = true; st.textContent = "";
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
      await putFile(repo, ".github/workflows/" + wf, workflow(slug, a.name), "apk apps: workflow " + slug);
      L("تم رفع الكود وملف البناء.", "g");

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
      if (run.conclusion !== "success") throw new Error("فشل البناء (" + run.conclusion + "). افتح سجل التشغيل على GitHub لمعرفة السبب: " + run.html_url);
      var rel = await ghJson("/repos/" + repo + "/releases/tags/" + slug + "-" + run.run_number);
      var asset = (rel.assets || []).find(function (x) { return /\.apk$/i.test(x.name); });
      if (!asset) throw new Error("نجح البناء لكن لم أجد ملف APK في الإصدار.");
      L("اكتمل البناء: " + asset.name + " (" + (asset.size / 1048576).toFixed(1) + " MB)", "g");
      lastApk = { asset: asset, name: (a.name || slug).replace(/[\\/:*?"<>|]/g, "_") + ".apk" };
      $("relLink").href = rel.html_url; $("buildResult").hidden = false; st.textContent = "جاهز للتحميل.";
    } catch (e) { L(errMsg(e), "e"); st.textContent = "فشل."; }
    finally { btn.disabled = false; }
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
