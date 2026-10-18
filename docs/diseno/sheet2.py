from kawaii import *
names=["gatito","conejo","perrito","dragon","pajarito","raton","reptil"]
cells=""
for i,n in enumerate(names):
    cells+='<g transform="translate(%d 0) scale(0.5)">%s</g>'%(i*256, render(n))
open("sheet2.svg","w",encoding="utf-8").write(svg_doc(cells,1792,335))
