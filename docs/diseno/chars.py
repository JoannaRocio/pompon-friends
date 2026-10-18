import math, sys

W = 5
P = {}  # paleta activa


def smooth_closed(pts):
    n = len(pts)
    d = "M%.1f %.1f" % pts[0]
    for i in range(n):
        p0, p1, p2, p3 = pts[(i - 1) % n], pts[i], pts[(i + 1) % n], pts[(i + 2) % n]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6.0, p1[1] + (p2[1] - p0[1]) / 6.0)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6.0, p2[1] - (p3[1] - p1[1]) / 6.0)
        d += " C%.1f %.1f %.1f %.1f %.1f %.1f" % (c1 + c2 + p2)
    return d + " Z"


def fur_path(cx, cy, rx, ry, tufts, n=96):
    pts = []
    for i in range(n):
        a = 360.0 * i / n
        off = 0.0
        shift = 0.0
        for (a0, a1, kind, depth, sweep) in tufts:
            lo, hi = a0 % 360, a1 % 360
            inside = (lo <= a < hi) if lo < hi else (a >= lo or a < hi)
            if not inside:
                continue
            span = (hi - lo) % 360 or 360
            t = ((a - lo) % 360) / span
            if kind == "bump":
                off += depth * math.sin(math.pi * t)
            else:
                prof = 1.0 - abs(2 * t - 1.0)
                off += depth * (prof ** 1.4)
                shift += sweep * prof
        ang = math.radians(a + shift)
        pts.append((cx + (rx + off) * math.cos(ang), cy + (ry + off) * math.sin(ang)))
    return smooth_closed(pts)


def mirror(inner):
    return '<g transform="translate(512 0) scale(-1 1)">%s</g>' % inner


def pair(inner):
    return inner + mirror(inner)


def tube(d, outer, inner_w, fill):
    return ('<path d="%s" fill="none" stroke="%s" stroke-width="%d"/><path d="%s" fill="none" stroke="%s" stroke-width="%d"/>'
            % (d, P["OL"], outer, d, fill, inner_w))


# ----------------------------------------------------------- partes comunes

def body_parts(leg_color=None, arm_extra=""):
    leg = leg_color or P["BODY"]
    s = []
    s.append('<ellipse cx="256" cy="410" rx="98" ry="92" fill="%s"/>' % P["BODY"])
    s.append('<path d="M172 414 Q256 368 340 414 Q350 482 256 496 Q162 482 172 414 Z" fill="%s" stroke="none"/>' % P["BELLY"])
    for sx in (-1, 1):
        x0 = 256 + sx * 40
        s.append('<ellipse cx="%d" cy="490" rx="34" ry="30" fill="%s"/>' % (x0, leg))
        s.append('<path d="M%d 520 Q%d 502 %d 508 Q%d 500 %d 508 Q%d 502 %d 520 Q%d 536 %d 534 Q%d 536 %d 520 Z" fill="%s"/>' % (
            x0 - 38, x0 - 34, x0 - 22, x0 - 6, x0 + 8, x0 + 22, x0 + 38, x0 + 38, x0, x0 - 38, x0 - 38, leg))
    for sx in (-1, 1):
        tr = "" if sx == 1 else ' transform="translate(512 0) scale(-1 1)"'
        s.append('<g%s><ellipse cx="354" cy="404" rx="23" ry="42" fill="%s" transform="rotate(-18 354 404)"/><path d="M350 436 Q352 444 350 448 M360 434 Q363 442 362 446" fill="none" stroke-width="3.5"/></g>' % (tr, P["BODY"]))
    s.append(arm_extra)
    return "".join(s)


def head(tufts, rx=140, ry=118):
    return '<path d="%s" fill="%s"/>' % (fur_path(256, 218, rx, ry, tufts), P["BODY"])


TUFTS_STD = [
    (222, 242, "bump", 9, 0), (242, 266, "bump", 13, 0), (266, 290, "bump", 11, 0), (290, 312, "bump", 8, 0),
    (30, 54, "spike", 11, 10), (58, 84, "bump", 10, 0), (128, 150, "spike", 8, -8),
]
TUFTS_FLUFF = [
    (200, 224, "bump", 10, 0), (224, 250, "bump", 13, 0), (250, 276, "bump", 15, 0), (276, 302, "bump", 13, 0), (302, 330, "bump", 10, 0),
    (-6, 22, "bump", 9, 0), (158, 186, "bump", 9, 0), (34, 60, "bump", 8, 0), (120, 146, "bump", 8, 0),
]


def face(mouth=True, beak=False, extra=""):
    s = []
    s.append('<ellipse cx="192" cy="240" rx="11.5" ry="16" fill="%s" stroke="none"/>' % P["EYE"])
    s.append('<ellipse cx="320" cy="240" rx="11.5" ry="16" fill="%s" stroke="none"/>' % P["EYE"])
    if beak:
        s.append('<path d="M232 276 Q256 266 280 276 Q274 300 256 308 Q238 300 232 276 Z" fill="#ffa94d" stroke="%s" stroke-width="4.5"/>' % P["BEAK_OL"])
        s.append('<path d="M240 284 Q256 288 272 284" fill="none" stroke="%s" stroke-width="3" opacity="0.6"/>' % P["BEAK_OL"])
    elif mouth:
        s.append('<path d="M228 276 Q242 266 256 278 Q270 266 284 276 Q282 308 256 314 Q230 308 228 276 Z" fill="#ff8a5c" stroke-width="4.5"/>')
        s.append('<path d="M243 302 Q256 286 269 302 Q256 314 243 302 Z" fill="#ffbf98" stroke="none"/>')
    s.append('<path d="M158 288 L168 274 M172 292 L182 278 M186 296 L196 282 M354 288 L344 274 M340 292 L330 278 M326 296 L316 282" fill="none" stroke-width="3.8"/>')
    s.append(extra)
    return "".join(s)


def wrap(inner):
    return '<g stroke="%s" stroke-width="%d" stroke-linejoin="round" stroke-linecap="round">%s</g>' % (P["OL"], W, inner)


# ------------------------------------------------------------------- especies

def dragon_svg(front="", top=""):
    P.update(OL="#9b2335", BODY="#ff6464", BELLY="#ffdca0", EYE="#5a4632")
    horn = ("M168 142 C140 104 128 52 142 6 C146 -8 160 -8 164 6 C176 34 184 56 190 76 "
            "C198 62 212 48 230 38 C244 32 250 44 242 56 C230 76 230 104 232 132 Z")
    spike = SPK()
    tail = spike + '<path d="M312 380 C376 374 430 384 466 346 C474 338 488 346 484 358 C468 426 396 454 316 442 Z" fill="%s"/>' % P["BODY"]
    tail += '<path d="M326 430 C392 436 444 412 474 366 C466 404 424 436 326 438 Z" fill="%s" stroke="none"/>' % P["BELLY"]
    tail += '<path d="M466 346 Q484 330 494 326 Q494 344 486 358" fill="#ff9d52"/>'
    ear = ('<path d="M150 172 Q124 140 100 128 Q92 176 116 224 Q134 238 154 226 Z" fill="%s"/>'
           '<path d="M138 182 Q122 162 110 150 Q108 186 124 214 Q134 216 142 208 Z" fill="#ff8a8a" stroke="none"/>'
           '<path d="M130 192 Q122 182 116 178 M128 204 Q122 198 118 196" fill="none" stroke-width="3.5"/>') % P["BODY"]
    hornp = '<path d="%s" fill="#ffe4aa"/><path d="M148 30 Q158 56 172 92" fill="none" stroke-width="3.5" opacity="0.5"/>' % horn
    inner = tail + pair(hornp) + pair(ear) + body_parts() + front + head(TUFTS_STD)
    inner += '<path d="M190 112 Q196 98 212 100 Q222 104 214 114 Q208 110 206 116" fill="none" stroke-width="4"/>'
    inner += '<path d="M328 122 Q338 120 344 128 M338 142 Q350 142 354 152" fill="none" stroke-width="3.5"/>'
    inner += face() + top
    return wrap(inner), pair(hornp)


def SPK():
    out = []
    for (x, y, rot, s) in [(338, 392, -4, 1.0), (372, 384, -10, 0.95), (406, 380, -18, 0.9), (438, 370, -30, 0.82), (462, 350, -48, 0.72)]:
        out.append('<path d="M-14 8 Q-4 -18 3 -30 Q12 -10 16 8 Z" fill="#ff9d52" transform="translate(%d %d) rotate(%d) scale(%.2f)"/>' % (x, y, rot, s))
    return "".join(out)


def cat_svg(front="", top=""):
    P.update(OL="#c9507a", BODY="#ffb3c8", BELLY="#fff1f5", EYE="#5a4632")
    tail = tube("M330 450 Q420 462 418 372 Q416 350 398 352", 36, 26, P["BODY"])
    ear = ('<path d="M142 160 Q116 62 168 34 Q216 52 246 112 Z" fill="%s"/>'
           '<path d="M158 138 Q146 88 172 66 Q198 80 220 116 Z" fill="#ff8fb0" stroke="none"/>'
           '<path d="M170 100 Q180 90 190 92 M164 116 Q172 108 180 108" fill="none" stroke-width="3.5"/>') % P["BODY"]
    cheeks = ('<path d="M118 300 Q104 304 94 316 Q110 316 122 322 M394 300 Q408 304 418 316 Q402 316 390 322" fill="none" stroke-width="3.5"/>')
    inner = tail + pair(ear) + body_parts() + front + head(TUFTS_STD)
    inner += '<path d="M236 108 Q244 98 256 102 Q266 106 260 116" fill="none" stroke-width="4"/>'
    inner += cheeks + face(extra=whiskers()) + top
    return wrap(inner), pair(ear)


def whiskers():
    return '<path d="M132 262 L96 252 M132 276 L92 278 M380 262 L416 252 M380 276 L420 278" fill="none" stroke-width="3" opacity="0.8"/>'


def bunny_svg(front="", top=""):
    P.update(OL="#5f8fbd", BODY="#bcdcf5", BELLY="#f6fbff", EYE="#4a3a4a")
    ear = ('<g transform="rotate(-8 200 90)"><ellipse cx="200" cy="52" rx="30" ry="82" fill="%s"/>'
           '<ellipse cx="200" cy="58" rx="14" ry="58" fill="#ffc2d4" stroke="none"/>'
           '<path d="M190 -2 Q200 10 210 4" fill="none" stroke-width="3.5"/></g>') % P["BODY"]
    tail = '<path d="%s" fill="#ffffff"/>' % fur_path(366, 470, 30, 30, [(0, 360, "bump", 0, 0)] + [(a, a + 40, "bump", 7, 0) for a in range(0, 360, 40)], 72)
    inner = tail + pair(ear) + body_parts() + front + head(TUFTS_FLUFF)
    inner += '<path d="M236 108 Q244 98 256 102 Q266 106 260 116" fill="none" stroke-width="4"/>'
    inner += face() + top
    return wrap(inner), pair(ear)


def dog_svg(front="", top=""):
    P.update(OL="#a8693a", BODY="#efc48f", BELLY="#fff1d9", EYE="#4a3328")
    ear = ('<path d="M156 150 Q96 146 92 232 Q92 292 134 282 Q158 236 164 176 Z" fill="#cf9a62"/>'
           '<path d="M118 176 Q110 214 118 252" fill="none" stroke-width="3.5" opacity="0.6"/>')
    tail = tube("M338 452 Q392 458 392 404", 34, 24, P["BODY"])
    snout = '<ellipse cx="256" cy="288" rx="62" ry="44" fill="#fff1d9" stroke="none"/>'
    nose = '<ellipse cx="256" cy="262" rx="15" ry="10" fill="#4a3328" stroke="none"/><ellipse cx="251" cy="259" rx="4.5" ry="2.8" fill="#fff" stroke="none" opacity="0.7"/>'
    inner = tail + body_parts() + pair(ear) + front + head(TUFTS_FLUFF)
    inner += '<path d="M240 108 Q248 98 260 102 Q270 106 264 116" fill="none" stroke-width="4"/>'
    inner += snout + face() + nose + top
    return wrap(inner), ""


def bird_svg(front="", top=""):
    P.update(OL="#c99a1c", BODY="#ffe27a", BELLY="#fff6cf", EYE="#4a3a2a", BEAK_OL="#d9822b")
    tail = ('<path d="M330 460 Q380 440 392 470 Q360 478 330 482 Z M334 440 Q388 410 408 440 Q372 452 334 458 Z" fill="%s"/>' % P["BODY"])
    tuft = ('<path d="M236 100 Q226 56 208 44 Q226 46 240 70 Z M256 98 Q258 46 250 28 Q274 44 270 98 Z M276 100 Q292 62 312 54 Q298 70 292 106 Z" fill="%s"/>' % P["BODY"])
    inner = tail + body_parts(leg_color="#ffb04a") + front + tuft + head(TUFTS_FLUFF)
    inner += face(mouth=False, beak=True) + top
    return wrap(inner), ""


# ------------------------------------------------------------------- ropa

def tee(color, stripe=None, outline="#7a5a1a"):
    s = '<clipPath id="ct"><ellipse cx="256" cy="410" rx="98" ry="92"/></clipPath><g clip-path="url(#ct)">'
    s += '<path d="M150 340 Q256 322 362 340 L370 470 L142 470 Z" fill="%s" stroke="none"/>' % color
    if stripe:
        for y in (372, 404, 436):
            s += '<rect x="140" y="%d" width="232" height="16" fill="%s" stroke="none"/>' % (y, stripe)
    s += '</g>'
    s += '<path d="M160 336 Q256 316 352 336" fill="none" stroke="%s" stroke-width="4"/>' % outline
    s += '<path d="M156 340 Q170 380 164 470 M356 340 Q342 380 348 470" fill="none" stroke="none"/>'
    for sx in (-1, 1):
        tr = "" if sx == 1 else ' transform="translate(512 0) scale(-1 1)"'
        s += '<g%s><ellipse cx="350" cy="376" rx="30" ry="24" fill="%s" transform="rotate(-24 350 376)"/></g>' % (tr, color)
    s += '<path d="M150 470 Q256 484 362 470" fill="none" stroke="%s" stroke-width="4" opacity="0.5"/>' % outline
    return s


def shorts(color, outline):
    s = ""
    for sx in (-1, 1):
        x0 = 256 + sx * 40
        s += '<path d="M%d 462 Q%d 456 %d 462 L%d 512 Q%d 520 %d 512 Z" fill="%s" stroke="%s"/>' % (x0 - 40, x0, x0 + 40, x0 + 38, x0, x0 - 38, color, outline)
    s += '<path d="M168 456 Q256 480 344 456 L346 478 Q256 500 166 478 Z" fill="%s" stroke="%s"/>' % (color, outline)
    return s


def cap(color, dark, outline):
    s = '<path d="M196 150 Q198 78 256 74 Q314 78 316 150 Q256 134 196 150 Z" fill="%s" stroke="%s"/>' % (color, outline)
    s += '<path d="M210 150 Q256 176 302 150 Q296 170 256 174 Q216 170 210 150 Z" fill="%s" stroke="%s"/>' % (dark, outline)
    s += '<circle cx="256" cy="76" r="8" fill="%s" stroke="%s"/>' % (dark, outline)
    s += '<path d="M256 100 L261 112 L274 113 L264 121 L267 133 L256 126 L245 133 L248 121 L238 113 L251 112 Z" fill="#fff" stroke="none"/>'
    return s


def dress(color, outline):
    s = '<path d="M170 372 Q256 340 342 372 L404 496 Q256 524 108 496 Z" fill="%s" stroke="%s"/>' % (color, outline)
    s += '<path d="M172 384 Q256 402 340 384" fill="none" stroke="#fff" stroke-width="7"/>'
    for x in range(124, 400, 38):
        s += '<circle cx="%d" cy="%d" r="11" fill="#fff" stroke="%s" stroke-width="3.5"/>' % (x + 8, 500 - 0.0006 * (x - 256) ** 2, outline)
    return s


def overalls(color, outline):
    s = '<path d="M196 366 Q196 350 212 350 L300 350 Q316 350 316 366 L336 478 Q256 500 176 478 Z" fill="%s" stroke="%s"/>' % (color, outline)
    s += '<path d="M206 352 L196 318 M306 352 L316 318" stroke="%s" stroke-width="22" stroke-linecap="round"/><path d="M206 352 L196 318 M306 352 L316 318" stroke="%s" stroke-width="12" stroke-linecap="round"/>' % (outline, color)
    s += '<circle cx="204" cy="372" r="8" fill="#ffd34d" stroke="%s" stroke-width="3"/><circle cx="308" cy="372" r="8" fill="#ffd34d" stroke="%s" stroke-width="3"/>' % (outline, outline)
    s += '<rect x="226" y="410" width="60" height="40" rx="10" fill="#6c97dc" stroke="%s" stroke-width="4"/>' % outline
    for sx in (-1, 1):
        x0 = 256 + sx * 40
        s += '<path d="M%d 468 L%d 468 L%d 512 Q%d 518 %d 512 Z" fill="%s" stroke="%s"/>' % (x0 - 38, x0 + 38, x0 + 36, x0, x0 - 36, color, outline)
    return s


def bow(color, dark):
    return ('<path d="M330 96 L284 66 L284 126 Z M330 96 L376 66 L376 126 Z" fill="%s" stroke="#a82a4a" stroke-width="4.5"/>'
            '<circle cx="330" cy="96" r="14" fill="%s" stroke="#a82a4a" stroke-width="4.5"/>') % (color, dark)


def flower():
    s = ""
    for (cx, cy, r) in [(168, 112, 24), (214, 90, 16)]:
        for i in range(6):
            a = math.radians(60 * i)
            s += '<circle cx="%.1f" cy="%.1f" r="%d" fill="#ffd34d" stroke="#d99a00" stroke-width="3.5"/>' % (cx + math.cos(a) * r * 0.85, cy + math.sin(a) * r * 0.85, r * 0.6)
        s += '<circle cx="%d" cy="%d" r="%d" fill="#fff" stroke="#d99a00" stroke-width="3.5"/>' % (cx, cy, r * 0.45)
    return s


SPECIES = {"gatito": cat_svg, "conejo": bunny_svg, "perrito": dog_svg, "dragon": dragon_svg, "pajarito": bird_svg}


def render(species, front="", top="", dec=""):
    body, _ = SPECIES[species](front, top)
    return body


def svg_doc(inner, w=512, h=610):
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -50 %d %d" width="%d" height="%d">%s</svg>' % (w, h, w, h, inner)


if __name__ == "__main__":
    which = sys.argv[1]
    out = sys.argv[2]
    open(out, "w", encoding="utf-8").write(svg_doc(render(which)))
