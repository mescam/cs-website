// Motyw ZSR — Politechnika Poznańska, wrapper nad typslides.
#import "@preview/typslides:1.3.2": *

#let kolor-pp = rgb(0, 98, 136)
#let orange-pp = rgb(191, 83, 39)
#let dark-gray = rgb(33, 33, 33)
#let light-gray = rgb(150, 150, 150)
#let very-light-gray = rgb(249, 249, 249)
#let dark-green = rgb(91, 141, 8)

#let ibm-blue-80 = kolor-pp
#let ibm-blue-60 = kolor-pp
#let ibm-blue-10 = rgb("#e8f1f5")
#let ibm-blue-30 = rgb("#7fb5cc")
#let ibm-gray-30 = rgb("#c6c6c6")
#let ibm-gray-60 = light-gray
#let ibm-teal-60 = kolor-pp
#let ibm-teal-70 = kolor-pp
#let ibm-red-60 = orange-pp
#let ibm-green-60 = dark-green

#let defblock(title, body) = block(
  width: 100%, above: 8pt, below: 8pt, radius: 3pt, clip: true,
  stroke: 1pt + kolor-pp,
  stack(
    block(width: 100%, inset: (x: 10pt, y: 5pt), fill: kolor-pp,
      text(fill: white, weight: "bold", size: 0.85em, title)),
    block(width: 100%, inset: (x: 10pt, y: 8pt), fill: very-light-gray,
      text(size: 0.9em, body)),
  ),
)

#let exblock(title, body) = block(
  width: 100%, above: 8pt, below: 8pt, radius: 3pt, clip: true,
  stroke: 1pt + dark-green,
  stack(
    block(width: 100%, inset: (x: 10pt, y: 5pt), fill: dark-green,
      text(fill: white, weight: "bold", size: 0.85em, title)),
    block(width: 100%, inset: (x: 10pt, y: 8pt), fill: rgb("#f5f9ee"),
      text(size: 0.9em, body)),
  ),
)

#let alertblock(title, body) = block(
  width: 100%, above: 8pt, below: 8pt, radius: 3pt, clip: true,
  stroke: 1pt + orange-pp,
  stack(
    block(width: 100%, inset: (x: 10pt, y: 5pt), fill: orange-pp,
      text(fill: white, weight: "bold", size: 0.85em, title)),
    block(width: 100%, inset: (x: 10pt, y: 8pt), fill: rgb("#fdf3ee"),
      text(size: 0.9em, body)),
  ),
)

#let src(body) = block(above: 8pt, below: 0pt, text(size: 13pt, fill: rgb("#555555"), style: "italic", body))
#let hl(body) = text(fill: kolor-pp, weight: "bold", body)
#let sm(body) = text(size: 0.82em, body)

// Kod i tabele: stała, czytelna wielkość zamiast dopasowania do zawartości.
#let codebox(body) = block(width: 100%, inset: 10pt, radius: 3pt,
  fill: ibm-blue-10, {
    set text(font: "DejaVu Sans Mono", size: 15pt)
    show raw: set text(font: "DejaVu Sans Mono", size: 17pt)
    set par(leading: 0.5em)
    body
  })
#let data-table(n, ..cells) = {
  set text(size: 17pt)
  table(columns: n, inset: 8pt, stroke: 0.5pt + ibm-gray-30,
    fill: (_, y) => if y == 0 { ibm-blue-10 } else { white },
    ..cells.pos(),
  )
}
#let flow(..items) = align(center)[
  #for (i, item) in items.pos().enumerate() {
    if i > 0 { [#sym.arrow.r #h(8pt)] }
    box(inset: 9pt, stroke: 1pt + kolor-pp, radius: 3pt, text(size: 17pt, item))
  }
]
