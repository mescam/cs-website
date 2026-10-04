#let pp-blue = rgb("#006288")
#let pp-orange = rgb("#bf5327")
#let pale-blue = rgb("#e8f1f5")
#let gray = rgb("#6b7280")

#set document(
  title: "Ansible — automatyzacja konfiguracji serwerów",
  author: "mgr inż. Jakub Woźniak",
)
#set page(
  paper: "a4",
  margin: (top: 2cm, bottom: 1.8cm, left: 2.1cm, right: 2.1cm),
  numbering: "1",
  header: context [
    #set text(font: "DejaVu Sans", size: 8pt, fill: gray)
    #grid(columns: (1fr, auto),
      [ZARZĄDZANIE SYSTEMAMI ROZPROSZONYMI],
      [POLITECHNIKA POZNAŃSKA],
    )
    #v(5pt)
    #line(length: 100%, stroke: 0.6pt + pp-blue)
  ],
  footer: context [
    #set text(font: "DejaVu Sans", size: 8pt, fill: gray)
    #grid(columns: (1fr, auto),
      [Laboratorium · Ansible],
      context counter(page).display("1"),
    )
  ],
)
#set text(font: "DejaVu Serif", size: 10pt, lang: "pl")
#set par(justify: true, leading: 0.68em)
#set heading(numbering: none)
#set table(inset: 6pt, stroke: 0.4pt + rgb("#c6c6c6"))
#show heading.where(level: 1): it => block(above: 17pt, below: 7pt, sticky: true)[
  #set text(font: "DejaVu Sans", fill: pp-blue, size: 17pt, weight: "bold")
  #it.body
]
#show heading.where(level: 2): it => block(above: 11pt, below: 5pt, sticky: true)[
  #set text(font: "DejaVu Sans", fill: pp-blue, size: 12pt, weight: "bold")
  #it.body
]
#show heading.where(level: 3): it => block(above: 8pt, below: 4pt, sticky: true)[
  #set text(font: "DejaVu Sans", fill: pp-orange, size: 10pt, weight: "bold")
  #it.body
]
#show raw: set text(font: "DejaVu Sans Mono", size: 8pt)
#show raw.where(block: true): it => block(
  width: 100%,
  inset: 8pt,
  fill: pale-blue,
  breakable: false,
  it,
)
#show strong: set text(font: "DejaVu Sans", weight: "bold")
#let horizontalrule = line(length: 100%, stroke: 0.6pt + pp-blue)

#v(62pt)
#block(width: 100%, inset: 20pt, fill: pale-blue)[
  #set text(font: "DejaVu Sans", fill: pp-blue, weight: "bold")
  #text(size: 11pt)[ZARZĄDZANIE SYSTEMAMI ROZPROSZONYMI]
  #v(20pt)
  #text(size: 27pt)[Ansible]
  #v(8pt)
  #text(size: 16pt, weight: "regular")[Automatyzacja konfiguracji serwerów]
  #v(18pt)
  #line(length: 54pt, stroke: 2pt + pp-orange)
  #v(12pt)
  #set text(font: "DejaVu Serif", fill: rgb("#374151"), size: 11pt)
  Configuration as Code · inventory · playbooki · szablony · handlery
]

#v(1fr)
#set text(font: "DejaVu Sans", size: 10pt)
#text(weight: "bold", fill: pp-blue)[mgr inż. Jakub Woźniak]
#line(length: 100%, stroke: 0.5pt + rgb("#c6c6c6"))
#v(8pt)
#set text(fill: gray, size: 9pt)
Instytut Informatyki · Politechnika Poznańska

#pagebreak()
$body$
