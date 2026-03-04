// PSR Theme — Politechnika Poznańska, wrapper nad typslides
#import "@preview/typslides:1.3.2": *

// ── Kolory PP ────────────────────────────────────────────────
#let kolor-pp        = rgb(0, 98, 136)
#let orange-pp       = rgb(191, 83, 39)
#let dark-gray       = rgb(33, 33, 33)
#let light-gray      = rgb(150, 150, 150)
#let very-light-gray = rgb(249, 249, 249)
#let dark-green      = rgb(91, 141, 8)

// Aliasy (kompatybilność z tabelami)
#let ibm-blue-80  = kolor-pp
#let ibm-blue-60  = kolor-pp
#let ibm-blue-10  = rgb("#e8f1f5")
#let ibm-blue-30  = rgb("#7fb5cc")
#let ibm-gray-30  = rgb("#c6c6c6")
#let ibm-gray-60  = light-gray
#let ibm-teal-60  = kolor-pp
#let ibm-teal-70  = kolor-pp
#let ibm-red-60   = orange-pp
#let ibm-green-60 = dark-green

// ── Bloki ────────────────────────────────────────────────────

#let defblock(title, body) = block(
  width: 100%, above: 8pt, below: 8pt,
  radius: 3pt, clip: true,
  stroke: 1pt + kolor-pp,
  stack(
    block(width: 100%, inset: (x: 10pt, y: 5pt),
      fill: kolor-pp,
      text(fill: white, weight: "bold", size: 0.85em, title)),
    block(width: 100%, inset: (x: 10pt, y: 8pt),
      fill: very-light-gray,
      text(size: 0.9em, body)),
  ),
)

#let exblock(title, body) = block(
  width: 100%, above: 8pt, below: 8pt,
  radius: 3pt, clip: true,
  stroke: 1pt + dark-green,
  stack(
    block(width: 100%, inset: (x: 10pt, y: 5pt),
      fill: dark-green,
      text(fill: white, weight: "bold", size: 0.85em, title)),
    block(width: 100%, inset: (x: 10pt, y: 8pt),
      fill: rgb("#f5f9ee"),
      text(size: 0.9em, body)),
  ),
)

#let alertblock(title, body) = block(
  width: 100%, above: 8pt, below: 8pt,
  radius: 3pt, clip: true,
  stroke: 1pt + orange-pp,
  stack(
    block(width: 100%, inset: (x: 10pt, y: 5pt),
      fill: orange-pp,
      text(fill: white, weight: "bold", size: 0.85em, title)),
    block(width: 100%, inset: (x: 10pt, y: 8pt),
      fill: rgb("#fdf3ee"),
      text(size: 0.9em, body)),
  ),
)

// ── Pomocnicze ───────────────────────────────────────────────
#let src(body)  = text(size: 0.75em, fill: light-gray, style: "italic", body)
#let hl(body)   = text(fill: kolor-pp, weight: "bold", body)
#let sm(body)   = text(size: 0.82em, body)
