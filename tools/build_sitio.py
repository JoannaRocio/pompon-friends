"""Arma docs/sitio/index.html (politica de privacidad) desde docs/store/privacy-policy.md.
Uso: python tools/build_sitio.py   (despues subir la carpeta docs/sitio/ entera a Netlify o GitHub Pages)."""
import html, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "docs", "store", "privacy-policy.md")
OUT = os.path.join(ROOT, "docs", "sitio", "index.html")


def inline(t: str) -> str:
    t = html.escape(t, quote=False)
    t = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', t)
    t = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", t)
    t = re.sub(r"(?<![\w])_(.+?)_(?![\w])", r"<em>\1</em>", t)
    t = re.sub(r"([\w.+-]+@[\w-]+\.[\w.]+)", r'<a href="mailto:\1">\1</a>', t)
    return t


def main() -> None:
    text = open(SRC, encoding="utf-8").read()
    title = ""
    parts = {"es": [], "en": []}
    cur = None
    for block in re.split(r"\n\s*\n", text.strip()):
        b = block.strip()
        if b.startswith("# "):
            title = b[2:].strip()
        elif b == "---":
            continue
        elif b.startswith("## "):
            cur = "en" if "English" in b else "es"
        elif cur is None:
            parts["es"].append('<p class="small">%s</p>' % inline(b))
            parts["en"].append('<p class="small">%s</p>' % inline(b.replace("Última actualización", "Last updated")))
        else:
            parts[cur].append("<p>%s</p>" % inline(b))
    page = TEMPLATE.replace("{title}", html.escape(title)).replace("{es}", "\n    ".join(parts["es"])).replace("{en}", "\n    ".join(parts["en"]))
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(page)
    print("escrito:", OUT)


TEMPLATE = """<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Política de privacidad · Pompon Friends</title>
<meta name="description" content="Política de privacidad de Pompon Friends / Pompon Friends privacy policy.">
<link rel="icon" href="icon.png">
<!-- Generado con tools/build_sitio.py desde docs/store/privacy-policy.md: editar el .md, no este archivo. -->
<style>
  :root { --ink: #5b3a4a; --pink-dark: #d6336c; --line: #ffc2d9; --soft: #fff1f6; --bg: #fff7ec; }
  * { box-sizing: border-box; }
  body { margin: 0; background: var(--bg); color: var(--ink); font: 17px/1.6 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }
  main { max-width: 720px; margin: 0 auto; padding: 24px 16px 48px; }
  header { display: flex; align-items: center; gap: 14px; }
  header img { width: 64px; height: 64px; border-radius: 16px; }
  h1 { font-size: 1.7rem; margin: 0; color: var(--pink-dark); line-height: 1.2; }
  .lang { margin: 8px 0 12px; font-size: .95rem; }
  a { color: var(--pink-dark); }
  .lang a { font-weight: 600; }
  .delete { display: block; background: #fff; border: 3px solid var(--line); border-radius: 18px; padding: 12px 16px; margin: 12px 0 20px; font-weight: 600; text-decoration: none; }
  .small { font-size: .92rem; opacity: .85; }
  section[lang=en] { display: none; }
  body.en section[lang=es] { display: none; }
  body.en section[lang=en] { display: block; }
</style>
</head>
<body>
<main>
  <header><img src="icon.png" alt=""><h1 id="title">{title}</h1></header>
  <p class="lang"><a href="#es" data-lang="es">Español</a> · <a href="#en" data-lang="en">English</a></p>
  <section lang="es">
    <a class="delete" href="borrar-datos.html">¿Quieres borrar tus datos del servidor? Pídelo acá →</a>
    {es}
  </section>
  <section lang="en">
    <a class="delete" href="borrar-datos.html#en">Want your data deleted from the server? Request it here →</a>
    {en}
  </section>
</main>
<script>
  function setLang(l) {
    document.body.classList.toggle("en", l === "en");
    document.documentElement.lang = l;
    document.getElementById("title").textContent = l === "en" ? "Privacy policy — Pompon Friends" : "Política de privacidad — Pompon Friends";
    document.title = l === "en" ? "Privacy policy · Pompon Friends" : "Política de privacidad · Pompon Friends";
  }
  document.querySelectorAll("[data-lang]").forEach(function (a) {
    a.addEventListener("click", function (e) { e.preventDefault(); setLang(a.dataset.lang); history.replaceState(null, "", "#" + a.dataset.lang); });
  });
  var nav = (navigator.language || "es").toLowerCase();
  setLang(location.hash === "#en" || (location.hash !== "#es" && nav.indexOf("es") !== 0) ? "en" : "es");
</script>
</body>
</html>
"""

if __name__ == "__main__":
    main()
