import math, sys

OL = "#2a2024"
W = 6
CX = 256


def smooth_closed(pts):
    n = len(pts)
    d = "M%.1f %.1f" % pts[0]
    for i in range(n):
        p0, p1, p2, p3 = pts[(i - 1) % n], pts[i], pts[(i + 1) % n], pts[(i + 2) % n]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6.0, p1[1] + (p2[1] - p0[1]) / 6.0)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6.0, p2[1] - (p3[1] - p1[1]) / 6.0)
        d += " C%.1f %.1f %.1f %.1f %.1f %.1f" % (c1 + c2 + p2)
    return d + " Z"


def superellipse(cx, cy, rx, ry, n=2.4, pts=64, squash_bottom=1.0):
    out = []
    for i in range(pts):
        a = 2 * math.pi * i / pts
        c, s = math.cos(a), math.sin(a)
        x = cx + rx * math.copysign(abs(c) ** (2 / n), c)
        k = ry * (squash_bottom if s > 0 else 1.0)
        y = cy + k * math.copysign(abs(s) ** (2 / n), s)
        out.append((x, y))
    return smooth_closed(out)


def mirror(inner):
    return '<g transform="translate(512 0) scale(-1 1)">%s</g>' % inner


def pair(inner):
    return inner + mirror(inner)


def tube(d, outer, inner_w, fill):
    return ('<path d="%s" fill="none" stroke="%s" stroke-width="%d"/><path d="%s" fill="none" stroke="%s" stroke-width="%d"/>'
            % (d, OL, outer, d, fill, inner_w))


# ------------------------------------------------------------------ cuerpo

def body(c, belly, leg=None, arm=None, belly_shape="oval"):
    leg = leg or c
    arm = arm or c
    s = []
    for sx in (-1, 1):
        x0 = CX + sx * 30
        s.append('<rect x="%d" y="428" width="44" height="52" rx="22" fill="%s"/>' % (x0 - 22, leg))
        s.append('<ellipse cx="%d" cy="474" rx="33" ry="17" fill="%s"/>' % (x0 - sx * 2, leg))
    s.append('<path d="M208 282 C192 340 190 410 206 448 Q256 466 306 448 C322 410 320 340 304 282 Z" fill="%s"/>' % c)
    if belly:
        s.append('<ellipse cx="256" cy="374" rx="40" ry="58" fill="%s" stroke="none"/>' % belly)
    s.append(pair(tube("M214 304 Q176 336 178 384", 34, 22, arm)))
    return "".join(s)


def head_path(c, rx=152, ry=106):
    return '<path d="%s" fill="%s"/>' % (superellipse(CX, 192, rx, ry, 2.35, 72, 1.0), c)


def eyes(color="#2a2024", glossy=True):
    s = ""
    for x in (188, 324):
        s += '<ellipse cx="%d" cy="204" rx="17" ry="19" fill="%s" stroke="none"/>' % (x, color)
        if glossy:
            s += '<circle cx="%d" cy="196" r="7.5" fill="#fff" stroke="none"/><circle cx="%d" cy="212" r="3.8" fill="#fff" stroke="none"/>' % (x + 5, x - 6)
    return s


def blush(color="#ffb3c2"):
    return ('<ellipse cx="140" cy="250" rx="28" ry="15" fill="%s" stroke="none" opacity="0.9"/>'
            '<ellipse cx="372" cy="250" rx="28" ry="15" fill="%s" stroke="none" opacity="0.9"/>') % (color, color)


def mouth(nose="#2a2024", show_nose=True):
    s = ""
    if show_nose:
        s += '<ellipse cx="256" cy="228" rx="9" ry="6" fill="%s" stroke="none"/>' % nose
    s += '<path d="M236 240 Q256 292 276 240 Q256 252 236 240 Z" fill="#e8344a" stroke-width="4.5"/>'
    s += '<path d="M244 268 Q256 258 268 268 Q256 280 244 268 Z" fill="#ff8ea0" stroke="none"/>'
    s += '<path d="M222 236 Q236 250 252 238 M260 238 Q276 250 290 236" fill="none" stroke-width="4"/>'
    return s


def wrap(inner):
    return '<g stroke="%s" stroke-width="%d" stroke-linejoin="round" stroke-linecap="round">%s</g>' % (OL, W, inner)


# ----------------------------------------------------------------- especies

def gatito(front="", top=""):
    c, belly, inn = "#ffc58a", "#fff3e4", "#ff9db8"
    ear = ('<path d="M112 170 Q96 92 120 60 Q168 84 206 118 Z" fill="%s"/>'
           '<path d="M126 150 Q116 102 130 82 Q158 98 182 122 Z" fill="%s" stroke="none"/>') % (c, inn)
    tail = tube("M308 446 Q392 470 408 392 Q412 366 394 362", 40, 28, c)
    stripe = '<path d="M392 366 Q404 372 406 388 M386 418 Q404 420 412 410" fill="none" stroke-width="5"/>'
    whisk = '<path d="M112 238 L58 226 M110 254 L54 258 M400 238 L454 226 M402 254 L458 258" fill="none" stroke-width="4"/>'
    inner = tail + stripe + pair(ear) + body(c, belly) + front + head_path(c) + eyes() + blush() + mouth() + whisk + top
    return wrap(inner)


def conejo(front="", top=""):
    c, belly, inn = "#ffffff", "#ffd9e2", "#ffc1d1"
    ear = ('<g transform="rotate(-10 190 80)"><ellipse cx="190" cy="40" rx="42" ry="104" fill="%s"/>'
           '<ellipse cx="190" cy="48" rx="24" ry="78" fill="%s" stroke="none"/></g>') % (c, inn)
    tail = '<circle cx="332" cy="470" r="26" fill="#fff"/>'
    inner = tail + pair(ear) + body(c, belly) + front + head_path(c) + eyes() + blush("#ffa8bb") + mouth() + top
    return wrap(inner)


def perrito(front="", top=""):
    c, belly, ear_c = "#dcb594", "#ffffff", "#c79a76"
    ear = ('<path d="M120 124 Q60 100 52 170 Q50 224 96 214 Q126 190 136 150 Z" fill="%s"/>' % ear_c)
    tail = '<path d="M306 452 Q356 440 366 400 Q342 424 308 430 Z" fill="%s"/>' % c
    spot = '<ellipse cx="338" cy="190" rx="42" ry="40" fill="%s" stroke="none"/>' % ear_c
    muzzle = '<rect x="198" y="212" width="116" height="86" rx="30" fill="#fff" stroke="none"/>'
    inner = tail + body(c, belly) + front + pair(ear) + head_path(c) + spot + eyes() + muzzle + blush() + mouth() + top
    return wrap(inner)


def dragon(front="", top=""):
    c, belly = "#ff6b6b", "#ffe0a8"
    horn = ("M178 112 C150 84 140 40 152 -2 C156 -14 170 -14 174 -2 C184 22 190 44 194 62 "
            "C202 48 216 34 232 24 C246 18 252 30 244 42 C232 60 232 86 234 110 Z")
    ear = '<path d="M116 170 Q90 136 66 126 Q60 176 84 220 Q104 232 124 218 Z" fill="%s"/><path d="M104 176 Q90 156 78 148 Q78 182 92 206 Q100 208 108 200 Z" fill="#ff9a9a" stroke="none"/>' % c
    tail = ('<path d="M308 440 C372 436 432 440 466 388 C474 376 490 384 484 398 C468 464 388 490 312 474 Z" fill="%s"/>'
            '<path d="M322 470 C390 476 446 450 476 404 C466 444 424 474 322 478 Z" fill="%s" stroke="none"/>') % (c, belly)
    spikes = "".join('<path d="M-14 8 Q-4 -18 3 -30 Q12 -10 16 8 Z" fill="#ff9d52" transform="translate(%d %d) rotate(%d) scale(%.2f)"/>' % t for t in
                     [(344, 438, -6, 1.0), (380, 434, -12, 0.95), (414, 428, -22, 0.9), (446, 412, -38, 0.8)])
    hornp = '<path d="%s" fill="#ffe4aa"/>' % horn
    inner = spikes + tail + pair(hornp) + pair(ear) + body(c, belly) + front + head_path(c) + eyes() + blush("#ff9aa8") + mouth(show_nose=False) + top
    return wrap(inner)


def pajarito(front="", top=""):
    c, belly = "#ffe27a", "#fff7d2"
    tuft = '<path d="M226 90 Q214 44 192 28 Q226 28 244 80 Z M256 86 Q258 28 246 6 Q280 24 276 86 Z M286 90 Q306 48 332 40 Q310 56 300 98 Z" fill="%s"/>' % c
    tail = '<path d="M306 440 Q372 424 388 462 Q350 474 308 470 Z M312 420 Q384 390 408 420 Q364 436 314 442 Z" fill="%s"/>' % c
    beak = '<path d="M232 232 Q256 220 280 232 Q272 270 256 284 Q240 270 232 232 Z" fill="#ffa94d" stroke-width="5"/><path d="M240 246 Q256 252 272 246" fill="none" stroke-width="3.5"/>'
    inner = tail + body(c, belly, leg="#ffb04a") + front + tuft + head_path(c) + eyes() + blush("#ffa8a8") + beak + top
    return wrap(inner)


def raton(front="", top=""):
    c, belly, inn = "#cfcbdc", "#fff0f4", "#ffb3c6"
    ear = ('<circle cx="120" cy="120" r="62" fill="%s"/><circle cx="120" cy="120" r="38" fill="%s" stroke="none"/>') % (c, inn)
    tail = tube("M308 450 Q398 480 420 420 Q430 392 410 384", 24, 14, "#ffb3c6")
    inner = tail + pair(ear) + body(c, belly) + front + head_path(c) + eyes() + blush() + mouth(nose="#ff7b98") + \
        '<path d="M116 246 L70 236 M114 262 L66 268 M396 246 L442 236 M398 262 L446 268" fill="none" stroke-width="3.5"/>' + top
    return wrap(inner)


def reptil(front="", top=""):
    c, belly = "#8fd19e", "#e6f7d8"
    crest = ''.join('<path d="M%d 96 Q%d 52 %d 84 Z" fill="#ffd978"/>' % (x - 18, x, x + 18) for x in (196, 256, 316))
    tail = tube("M308 446 Q400 480 428 420 Q438 394 420 388", 44, 32, c)
    dots = '<circle cx="350" cy="140" r="9" fill="#6bb784" stroke="none"/><circle cx="170" cy="150" r="7" fill="#6bb784" stroke="none"/><circle cx="214" cy="112" r="6" fill="#6bb784" stroke="none"/>'
    inner = tail + crest + body(c, belly) + front + head_path(c) + dots + eyes() + blush("#ffb0a8") + mouth(show_nose=False) + top
    return wrap(inner)


SPECIES = {"gatito": gatito, "conejo": conejo, "perrito": perrito, "dragon": dragon,
           "pajarito": pajarito, "raton": raton, "reptil": reptil}


# --------------------------------------------------------------------- ropa

def clip_torso():
    return '<clipPath id="ct"><path d="M208 282 C192 340 190 410 206 448 Q256 466 306 448 C322 410 320 340 304 282 Z"/></clipPath>'


def tee(color, stripe=None):
    s = clip_torso() + '<g clip-path="url(#ct)"><rect x="180" y="276" width="152" height="150" fill="%s" stroke="none"/>' % color
    if stripe:
        for y in (306, 338, 370, 402):
            s += '<rect x="180" y="%d" width="152" height="14" fill="%s" stroke="none"/>' % (y, stripe)
    s += '</g><path d="M208 284 Q256 300 304 284" fill="none" stroke-width="5"/>'
    s += '<path d="M200 426 Q256 440 312 426" fill="none" stroke-width="5"/>'
    s += pair('<ellipse cx="206" cy="318" rx="24" ry="30" fill="%s" transform="rotate(26 206 318)"/>' % color)
    return s


def shorts(color):
    s = ""
    for sx in (-1, 1):
        x0 = CX + sx * 30
        s += '<path d="M%d 424 L%d 424 L%d 478 Q%d 486 %d 478 Z" fill="%s"/>' % (x0 - 28, x0 + 28, x0 + 24, x0, x0 - 24, color)
    s += '<path d="M200 420 Q256 438 312 420 L314 442 Q256 458 198 442 Z" fill="%s"/>' % color
    return s


def cap(color, dark):
    s = '<path d="M164 138 Q164 62 256 58 Q348 62 348 138 Q256 118 164 138 Z" fill="%s"/>' % color
    s += '<path d="M186 136 Q256 164 326 136 Q316 160 256 164 Q196 160 186 136 Z" fill="%s"/>' % dark
    s += '<circle cx="256" cy="60" r="9" fill="%s"/>' % dark
    s += '<path d="M256 84 L262 98 L277 99 L265 108 L269 122 L256 114 L243 122 L247 108 L235 99 L250 98 Z" fill="#fff" stroke="none"/>'
    return s


def dress(color):
    s = '<path d="M200 286 Q256 306 312 286 L372 466 Q256 500 140 466 Z" fill="%s"/>' % color
    s += '<path d="M204 300 Q256 322 308 300" fill="none" stroke="#fff" stroke-width="8"/>'
    for i, x in enumerate(range(150, 372, 36)):
        s += '<circle cx="%d" cy="%d" r="12" fill="#fff"/>' % (x + 8, 474 - 0.0009 * (x - 256) ** 2 * 0)
    return s


def overalls(color):
    s = '<path d="M216 322 Q216 306 232 306 L280 306 Q296 306 296 322 L312 446 Q256 466 200 446 Z" fill="%s"/>' % color
    s += '<path d="M226 308 L214 276 M286 308 L298 276" stroke-width="26" stroke-linecap="round"/><path d="M226 308 L214 276 M286 308 L298 276" stroke="%s" stroke-width="14" stroke-linecap="round"/>' % color
    s += '<circle cx="224" cy="330" r="8" fill="#ffd34d" stroke-width="3.5"/><circle cx="288" cy="330" r="8" fill="#ffd34d" stroke-width="3.5"/>'
    s += '<rect x="232" y="366" width="48" height="36" rx="9" fill="#6c97dc" stroke-width="4.5"/>'
    for sx in (-1, 1):
        x0 = CX + sx * 30
        s += '<path d="M%d 430 L%d 430 L%d 478 Q%d 486 %d 478 Z" fill="%s"/>' % (x0 - 28, x0 + 28, x0 + 24, x0, x0 - 24, color)
    return s


def bow(color, dark):
    return ('<path d="M352 100 L300 66 L300 134 Z M352 100 L404 66 L404 134 Z" fill="%s"/>'
            '<circle cx="352" cy="100" r="15" fill="%s"/>') % (color, dark)


def flower():
    s = ""
    for (cx, cy, r) in [(164, 112, 26), (214, 90, 17)]:
        for i in range(6):
            a = math.radians(60 * i)
            s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#ffd34d" stroke-width="4"/>' % (cx + math.cos(a) * r * 0.85, cy + math.sin(a) * r * 0.85, r * 0.6)
        s += '<circle cx="%d" cy="%d" r="%.1f" fill="#fff" stroke-width="4"/>' % (cx, cy, r * 0.45)
    return s


def render(name, front="", top=""):
    return SPECIES[name](front, top)


def svg_doc(inner, w=512, h=610, y0=-50):
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 %d %d %d" width="%d" height="%d">%s</svg>' % (y0, w, h, w, h, inner)


if __name__ == "__main__":
    open(sys.argv[2], "w", encoding="utf-8").write(svg_doc(render(sys.argv[1])))
