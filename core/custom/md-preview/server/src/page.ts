import { getTheme, themeNames, type PageVars, type ThemeDef } from "./themes";

export interface PageInput {
  title: string;
  body: string;
  themeName: string;
  meta?: Record<string, unknown>;
}

const META_FIELDS = ["author", "date", "description", "tags"];

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function metaValueHtml(value: unknown): string {
  if (Array.isArray(value)) {
    return value
      .map((item) => `<span class="mdprv-tag">${escapeHtml(String(item))}</span>`)
      .join(" ");
  }
  return escapeHtml(String(value));
}

function renderMeta(meta: Record<string, unknown> | undefined): string {
  if (!meta) {
    return "";
  }
  const items: string[] = [];
  for (const key of META_FIELDS) {
    const value = meta[key];
    if (value === undefined || value === null || value === "") {
      continue;
    }
    if (Array.isArray(value) && value.length === 0) {
      continue;
    }
    items.push(
      `<span class="mdprv-meta-item"><span class="mdprv-meta-key">${escapeHtml(key)}</span>${metaValueHtml(value)}</span>`
    );
  }
  if (items.length === 0) {
    return "";
  }
  return `<div class="mdprv-meta">${items.join("")}</div>`;
}

function rootVars(v: PageVars): string {
  return [
    `--mdprv-bg:${v.bg}`,
    `--mdprv-fg:${v.fg}`,
    `--mdprv-muted:${v.muted}`,
    `--mdprv-link:${v.link}`,
    `--mdprv-border:${v.border}`,
    `--mdprv-code-bg:${v.codeBg}`,
    `--mdprv-quote:${v.blockquote}`,
  ].join(";");
}

function themeCss(theme: ThemeDef): string {
  if (theme.kind === "auto" && theme.light && theme.dark) {
    return [
      `:root{${rootVars(theme.light)}}`,
      `@media (prefers-color-scheme: dark){:root{${rootVars(theme.dark)}}}`,
    ].join("\n");
  }
  if (theme.vars) {
    return `:root{${rootVars(theme.vars)}}`;
  }
  return "";
}

const BASE_CSS = `:root{color-scheme:light dark}
*{box-sizing:border-box}
body{margin:0 auto;max-width:46rem;padding:2.5rem 1.25rem 6rem;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;font-size:17px;line-height:1.65;color:var(--mdprv-fg);background:var(--mdprv-bg);word-wrap:break-word}
h1,h2,h3,h4,h5,h6{margin:1.8em 0 .6em;line-height:1.25;font-weight:600}
h1{font-size:2em;padding-bottom:.3em;border-bottom:1px solid var(--mdprv-border)}
h2{font-size:1.5em;padding-bottom:.3em;border-bottom:1px solid var(--mdprv-border)}
h3{font-size:1.25em}
p{margin:0 0 1em}
a{color:var(--mdprv-link);text-decoration:none}
a:hover{text-decoration:underline}
code{font-family:ui-monospace,SFMono-Regular,"SF Mono",Menlo,Consolas,monospace;font-size:.88em;background:var(--mdprv-code-bg);padding:.15em .35em;border-radius:5px}
pre{background:var(--mdprv-code-bg);border:1px solid var(--mdprv-border);border-radius:6px;padding:1em;overflow:auto}
pre code{background:none;padding:0;font-size:.85em}
pre.shiki{background:var(--mdprv-code-bg)}
blockquote{margin:0 0 1em;padding:0 1em;color:var(--mdprv-quote);border-left:.25em solid var(--mdprv-border)}
ul,ol{margin:0 0 1em;padding-left:2em}
li{margin:.25em 0}
li input[type=checkbox]{margin-right:.4em}
table{border-collapse:collapse;margin:0 0 1em;display:block;overflow:auto}
th,td{border:1px solid var(--mdprv-border);padding:.4em .75em}
th{background:var(--mdprv-code-bg);font-weight:600}
img{max-width:100%}
hr{height:1px;border:0;background:var(--mdprv-border);margin:2em 0}
del{color:var(--mdprv-muted)}
sup{font-size:.75em}
pre.mermaid{background:transparent;border:0;text-align:center;overflow:visible}
pre.mermaid svg{max-width:100%;height:auto}
.mdprv-theme-toggle{position:fixed;top:.75rem;right:.75rem;z-index:10;font:inherit;font-size:13px;padding:.25rem .5rem;color:var(--mdprv-fg);background:var(--mdprv-code-bg);border:1px solid var(--mdprv-border);border-radius:6px;cursor:pointer}
.mdprv-meta{display:flex;flex-wrap:wrap;gap:.35rem 1.25rem;margin:0 0 1.5rem;padding:.6rem .8rem;border:1px solid var(--mdprv-border);border-radius:6px;background:var(--mdprv-code-bg);font-size:.85em;color:var(--mdprv-muted)}
.mdprv-meta-item{display:inline-flex;align-items:center;gap:.35rem}
.mdprv-meta-key{font-weight:600;color:var(--mdprv-fg);text-transform:uppercase;font-size:.85em;letter-spacing:.03em}
.mdprv-tag{display:inline-block;padding:.05rem .5rem;border:1px solid var(--mdprv-border);border-radius:999px;background:var(--mdprv-bg)}`;

const SHIKI_DUAL_CSS = `@media (prefers-color-scheme: dark){.shiki,.shiki span{color:var(--shiki-dark)!important;background-color:var(--shiki-dark-bg)!important}}`;

function scriptSafe(value: unknown): string {
  return JSON.stringify(value).replace(/</g, "\\u003c");
}

function buildScripts(theme: ThemeDef): string {
  const data = {
    auto: theme.kind === "auto",
    mermaid: theme.mermaid,
    mermaidDark: theme.mermaidDark || null,
  };
  return `(function(){
  var data = ${scriptSafe(data)};
  function cfg(){
    if (data.auto) {
      return window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches
        ? data.mermaidDark : data.mermaid;
    }
    return data.mermaid;
  }
  if (typeof mermaid !== "undefined") {
    try {
      mermaid.initialize(Object.assign({ startOnLoad: false, securityLevel: "strict" }, cfg()));
      mermaid.run({ querySelector: "pre.mermaid" });
    } catch (e) { console.error("md-preview: mermaid", e); }
  }
})();
(function(){
  var sel = document.getElementById("mdprv-theme");
  if (!sel) return;
  sel.addEventListener("change", function(){
    var v = sel.value;
    document.cookie = "mdprv_theme=" + encodeURIComponent(v) + ";path=/;max-age=31536000;SameSite=Lax";
    location.href = location.pathname + (v === "auto" ? "" : "?theme=" + encodeURIComponent(v));
  });
})();
(function(){
  var current = null;
  var base = location.pathname.replace(/\\/$/, "");
  function poll(){
    fetch(base + "/version" + location.search)
      .then(function(r){ return r.text(); })
      .then(function(v){
        if (current === null) { current = v; }
        else if (v !== current) { current = v; location.reload(); }
      })
      .catch(function(){});
  }
  setInterval(poll, 700);
})();`;
}

export function renderPage(input: PageInput): string {
  const theme = getTheme(input.themeName);
  const css = [
    themeCss(theme),
    BASE_CSS,
    theme.kind === "auto" ? SHIKI_DUAL_CSS : "",
  ]
    .filter(Boolean)
    .join("\n");

  const options = themeNames()
    .map(
      (name) =>
        `<option value="${escapeHtml(name)}"${name === theme.name ? " selected" : ""}>${escapeHtml(name)}</option>`
    )
    .join("");

  return [
    "<!DOCTYPE html>",
    '<html lang="en">',
    "<head>",
    '<meta charset="utf-8">',
    '<meta name="viewport" content="width=device-width, initial-scale=1">',
    `<title>${escapeHtml(input.title)}</title>`,
    "<style>",
    css,
    "</style>",
    "</head>",
    "<body>",
    `<select id="mdprv-theme" class="mdprv-theme-toggle" aria-label="Theme">${options}</select>`,
    renderMeta(input.meta),
    '<article class="markdown-body">',
    input.body,
    "</article>",
    '<script src="/__assets/mermaid.min.js"></script>',
    "<script>",
    buildScripts(theme),
    "</script>",
    "</body>",
    "</html>",
  ].join("\n");
}
