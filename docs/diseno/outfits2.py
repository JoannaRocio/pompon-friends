from kawaii import *
items=[render("gatito", overalls("#4f7fc4"), bow("#ff5d7a","#e8446a")),
       render("conejo", dress("#ff8fb8"), flower()),
       render("perrito", tee("#fff6c8","#ffb347")+shorts("#5b8dd9"), cap("#4a90e2","#2f6fbf")),
       render("dragon", tee("#ffffff","#7cc4ff")+shorts("#6c5ce0"), cap("#ffd34d","#e0a800"))]
cells=""
for i,c in enumerate(items):
    cells+='<g transform="translate(%d 0) scale(0.62)">%s</g>'%(i*318,c)
open("outfits2.svg","w",encoding="utf-8").write(svg_doc(cells,1272,400))
