from chars import *
_, hornp = dragon_svg()
d_front = tee("#fff6c8", "#ffb347", "#d6a82e") + shorts("#5b8dd9", "#3a64b0")
d_top = cap("#4a90e2", "#2f6fbf", "#2d67b0")
dragon_o = render("dragon", d_front, d_top)
cat_o = render("gatito", overalls("#4f7fc4", "#355fa0"), bow("#ff5d7a", "#e8446a"))
bun_o = render("conejo", dress("#ff8fb8", "#d9608f"), flower())
cells = ""
for i, c in enumerate([cat_o, bun_o, dragon_o]):
    cells += '<g transform="translate(%d 0) scale(0.62)">%s</g>' % (i * 330, c)
open("outfits.svg", "w", encoding="utf-8").write(svg_doc(cells, 990, 420))
