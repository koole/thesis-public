// Thesis Template

#import "./utils/horizontal-bar-chart.typ": data-table, horizontal-bar-chart
#import "@preview/marginalia:0.2.3" as marginalia: note, notefigure, wideblock
#import "./lilaq/src/lilaq.typ" as lq

#let space_right = 5cm

#let default-colors = (
  rgb("#15803d"), // Green 700
  rgb("#b91c1c"), // Red 700
  rgb("#0369a1"), // Sky 700
  rgb("#7e22ce"), // Purple 700
  rgb("#b45309"), // Amber 700
  rgb("#a21caf"), // Fuchsia 700
  rgb("#c2410c"), // Orange 700
  rgb("#047857"), // Emerald 700
  rgb("#1d4ed8"), // Blue 700
  rgb("#be185d"), // Pink 700
  rgb("#0f766e"), // Teal 700
  rgb("#6d28d9"), // Violet 700
  rgb("#be123c"), // Rose 700
  rgb("#4d7c0f"), // Lime 700
  rgb("#4338ca"), // Indigo 700
  rgb("#a16207"), // Yellow 700
  rgb("#0e7490"), // Cyan 700
)

#show: lq.set-diagram(
  cycle: default-colors
)

#let _metadata-labels = (
  diagnosis_confirm_type: "Diagnosis confirmation type",
  fitzpatrick_skin_type: "Fitzpatrick skin type",
  attribution: "Data source",
  age_approx: "Age",
  dermoscopic_type: "Dermoscopic type",
  diagnosis_2: "Diagnosis (H2)",
  anatom_site_general: "Anatomical site",
  image_type: "Image type",
  diagnosis_1: "Diagnosis (H1)",
  sex: "Sex",
)

#let metadata-label(col) = _metadata-labels.at(col, default: col)

#let in-outline = state("in-outline", false)

#let thesis(
  // Metadata
  title: "Thesis Title",
  author: "Author Name",
  date: datetime.today(),
  // Layout options
  space_right: space_right,
  page_margins: (left: 2.3cm, right: 2.3cm, top: 2.5cm, bottom: 2.5cm),
  // Typography
  font: "Libertinus Serif",
  font_size: 11pt,
  // Content sections
  abstract: [],
  acknowledgments: [],
  // The main document content
  body,
) = {
  // Right margin includes space reserved for margin content
  let right_margin = page_margins.left + space_right

  // ========================================
  // UTILITY FUNCTIONS
  // ========================================

  let full_width(content) = {
    pad(left: 0cm, right: -space_right)[#content]
  }

  let note-colors = (
    yellow: (bg: rgb("#fffbf0"), stroke: rgb("#f0d000"), text: rgb("#8b7000")),
    blue: (bg: rgb("#e3f2fd"), stroke: rgb("#1976d2"), text: rgb("#1565c0")),
    green: (bg: rgb("#e8f5e9"), stroke: rgb("#43a047"), text: rgb("#2e7d32")),
    red: (bg: rgb("#ffebee"), stroke: rgb("#e53935"), text: rgb("#c62828")),
    purple: (bg: rgb("#f3e5f5"), stroke: rgb("#8e24aa"), text: rgb("#6a1b9a")),
    orange: (bg: rgb("#fff3e0"), stroke: rgb("#fb8c00"), text: rgb("#e65100")),
  )

  let note(content, color: "yellow", title: "Note") = {
    let colors = note-colors.at(color, default: note-colors.yellow)
    block(
      fill: colors.bg,
      stroke: colors.stroke + 1pt,
      radius: 4pt,
      inset: 12pt,
      width: 100%,
      [
        #text(weight: "bold", fill: colors.text)[#title:]
        #content
      ],
    )
  }

  let draft-note(content) = note(content, color: "blue", title: "Draft")

  // ========================================
  // GLOBAL STYLING
  // ========================================

  show: marginalia.setup.with(
    outer: (far: page_margins.left, width: space_right - 0.5cm, sep: 0cm),
    inner: (far: page_margins.left - 0.2cm, width: 1.5cm, sep: 0cm),
    top: page_margins.top,
    bottom: page_margins.bottom,
    left: page_margins.left,
    right: right_margin,
    book: false,
  )

  set page("a4", numbering: "1")
  set par(justify: true)
  set text(font: font, size: font_size)

  set math.equation(numbering: "(1)")

  // Flex-caption support: track when rendering inside an outline
  show outline: it => {
    in-outline.update(true)
    it
    in-outline.update(false)
  }

  // ========================================
  // FIGURE STYLING
  // ========================================

  show figure.caption: it => {
    // Detect margin figures by inspecting the body for our marker
    let is_margin_figure = false
    let body_str = repr(it.body)
    if body_str.contains("margin-figure") {
      is_margin_figure = true
    }

    if is_margin_figure {
      // Caption is rendered by the show figure rule instead
      none
    } else {
      align(left)[
        #context {
          let content = it.body
          let supplement = it.supplement
          let numbering = it.numbering
          let number = if numbering != none { it.counter.display(numbering) } else { it.counter.display() }

          [#text(weight: "bold")[#supplement #number:] #text(style: "italic")[#content]]
        }
      ]
    }
  }

  show figure.where(kind: table): set figure.caption(position: top)

  show figure: it => {
    let is_margin_figure = false

    // Detect margin figures by checking the body for our metadata marker
    let body_str = repr(it.body)
    if body_str.contains("margin-figure") {
      is_margin_figure = true
    }

    if is_margin_figure {
      block[
        #marginalia.note(numbering: none)[
          #context {
            let fig_number = it.counter.display(it.numbering)
            v(2.2em)
            text()[
              #text(weight: "bold")[#it.supplement #fig_number:]
              #text(style: "italic")[#it.caption.body]
            ]
          }
        ]
        #it.body
      ]
    } else {
      v(1em)
      it
      v(1em)
    }
  }

  // ========================================
  // TITLE PAGE
  // ========================================

  set page(numbering: none, margin: (left: 4cm, right: 4cm, top: 4cm, bottom: 4cm))
  include "title_page.typ"

  // ========================================
  // FRONT MATTER
  // ========================================

  set page(
    numbering: "i",
    margin: (
      left: page_margins.left,
      right: right_margin,
      top: page_margins.top,
      bottom: page_margins.bottom,
    ),
  )

  set heading(numbering: none)
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    text(weight: "bold", size: 1.2em)[#it.body]
    line(length: 100%, stroke: 1pt + gray)
    v(0.5em)
  }

  if abstract != [] {
    heading(level: 1, outlined: false)[Abstract]
    abstract
    pagebreak()
  }

  if acknowledgments != [] {
    heading(level: 1, outlined: false)[Acknowledgments]
    acknowledgments
    pagebreak()
  }

  outline(
    title: "Table of Contents",
    indent: auto,
  )
  pagebreak()

  outline(title: "Figures", target: figure.where(kind: image))
  pagebreak()

  // ========================================
  // MAIN CONTENT
  // ========================================

  set page(numbering: "1", header: context {
    let physical-page = here().page()
    let page-num = counter(page).at(here()).first()
    let headings = query(heading.where(level: 1))
    let current-heading = none

    for h in headings {
      if h.location().page() <= physical-page {
        current-heading = h
      }
    }

    if current-heading != none {
      let chapter-title = current-heading.body
      if calc.odd(page-num) {
        // Header spans the full page width, ignoring body margins
        full_width[
          #align(right)[
            #emph[#chapter-title] — #page-num
          ]
        ]
      } else {
        full_width[
          #align(left)[
            #page-num — #emph[#chapter-title]
          ]
        ]
      }
    } else {
      if calc.odd(page-num) {
        full_width[
          #align(right)[#page-num]
        ]
      } else {
        full_width[
          #align(left)[#page-num]
        ]
      }
    }
  })

  // Restart page numbering at 1 for the main content
  counter(page).update(1)

  // ========================================
  // HEADING STYLES
  // ========================================

  set heading(numbering: "1.1")

  // Level 1: large chapter number above the title
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    v(3em)
    text(weight: "bold", size: 4em)[#counter(heading).display()]
    v(-3em)
    text(weight: "bold", size: 1.3em)[#it.body]
    line(length: 100%, stroke: 1pt + gray)
    v(0.5em)
  }

  // Level 2: number in left margin, body inline
  show heading.where(level: 2): it => {
    place(left, dx: -2.5cm, dy: 0pt)[
      #box(width: 2.3cm)[
        #align(right)[
          #text(weight: "bold", size: 1.2em)[#counter(heading).display()]
        ]
      ]
    ]
    text(weight: "bold", size: 1.2em)[#it.body]
  }

  // Level 3: number in left margin, body inline
  show heading.where(level: 3): it => {
    place(left, dx: -2.5cm, dy: 0pt)[
      #box(width: 2.3cm)[
        #align(right)[
          #text(weight: "bold", size: 1.1em)[#counter(heading).display()]
        ]
      ]
    ]
    text(size: 1.1em)[#it.body]
  }

  show heading.where(level: 4): it => {
    text(style: "italic")[#it.body]
  }

  body
}

// Standalone utility functions for use outside the template
#let full_width(space_right: space_right, content) = {
  pad(left: 0cm, right: -space_right)[#content]
}

#let margin_figure(content, caption: none, label: none, kind: image, supplement: auto, numbering: "1", gap: 0.65em) = {
  // Embed a marker so the show figure rule can detect margin figures later
  figure(
    block[
      #metadata("margin-figure")
      #align(center)[
        #box(width: 12cm)[
          #align(center)[#content]
        ]
      ]
    ],
    caption: caption,
    kind: kind,
    supplement: if supplement == auto { "Figure" } else { supplement },
    numbering: numbering,
  )

  if label != none {
    [#label]
  }
}

#let note-colors = (
  yellow: (bg: rgb("#fff6de"), fg: rgb("#7a6822")),
  blue: (bg: rgb("#e3f2fd"), fg: rgb("#1565c0")),
  green: (bg: rgb("#e8f5e9"), fg: rgb("#2e7d32")),
  red: (bg: rgb("#ffebee"), fg: rgb("#c62828")),
  purple: (bg: rgb("#f3e5f5"), fg: rgb("#6a1b9a")),
  orange: (bg: rgb("#fff3e0"), fg: rgb("#e65100")),
)

#let note(content, color: "yellow", title: "Note") = {
  let colors = note-colors.at(color, default: note-colors.yellow)
  block(
    fill: colors.bg,
    inset: 12pt,
    width: 100%,
    [
      #text(weight: "bold", fill: colors.fg)[#title:]
      #text(fill: colors.fg)[#content]
    ],
  )
}

#let draft-note(content) = note(content, color: "blue", title: "Draft")

#let margin_note(content) = marginalia.note(numbering: none)[#content]

#let numbered_margin_counter = counter("notes")
#let numbered_margin_note(content) = marginalia.note(
  counter: numbered_margin_counter,
  numbering: (..i) => text(
    weight: 900,
    size: 5pt,
    style: "normal",
    numbering("1", ..i),
  ),
  anchor-numbering: (.., i) => super[#i],
)[#content]

#let uncertainty-color(val, min, max) = {
  let mid = (min + max) / 2
  if val <= mid {
    // Green to white below the midpoint
    let t = (val - min) / (mid - min)
    rgb(
      int(255 * t + 21 * (1 - t)),
      int(255 * t + 128 * (1 - t)),
      int(255 * t + 61 * (1 - t)),
    )
  } else {
    // White to red above the midpoint
    let t = (val - mid) / (max - mid)
    rgb(
      int(255 * (1 - t) + 185 * t),
      int(255 * (1 - t) + 28 * t),
      int(255 * (1 - t) + 28 * t),
    )
  }
}

// Inverted scale (red to white to green) for metrics where higher is better
#let inverted-uncertainty-color(val, min, max) = {
  let mid = (min + max) / 2
  if val <= mid {
    // Red to white below the midpoint
    let t = (val - min) / (mid - min)
    rgb(
      int(255 * t + 185 * (1 - t)),
      int(255 * t + 28 * (1 - t)),
      int(255 * t + 28 * (1 - t)),
    )
  } else {
    // White to green above the midpoint
    let t = (val - mid) / (max - mid)
    rgb(
      int(255 * (1 - t) + 21 * t),
      int(255 * (1 - t) + 128 * t),
      int(255 * (1 - t) + 61 * t),
    )
  }
}

#let white-to-red-color(val, min, max) = {
  let t = if max == min { 0.0 } else { (val - min) / (max - min) }
  let t = calc.clamp(t, 0.0, 1.0)
  rgb(
    int(255 * (1 - t) + 185 * t),
    int(255 * (1 - t) + 28 * t),
    int(255 * (1 - t) + 28 * t),
  )
}

#let white-to-green-color(val, min, max) = {
  let t = if max == min { 0.0 } else { (val - min) / (max - min) }
  let t = calc.clamp(t, 0.0, 1.0)
  rgb(
    int(255 * (1 - t) + 21 * t),
    int(255 * (1 - t) + 128 * t),
    int(255 * (1 - t) + 61 * t),
  )
}

// threshold is the value where the color is white (typically 1.0 for ratios);
// max-green is the value at which the color is fully green
#let ratio-color(val, threshold, max-green) = {
  if val < threshold {
    let t = calc.clamp(1.0 - val / threshold, 0.0, 1.0)
    rgb(
      int(255 * (1 - t) + 185 * t),
      int(255 * (1 - t) + 28 * t),
      int(255 * (1 - t) + 28 * t),
    )
  } else {
    let t = calc.clamp((val - threshold) / (max-green - threshold), 0.0, 1.0)
    rgb(
      int(255 * (1 - t) + 21 * t),
      int(255 * (1 - t) + 128 * t),
      int(255 * (1 - t) + 61 * t),
    )
  }
}

#let color-table(
  data,
  row-headers,
  col-headers,
  min-val,
  max-val,
  color-fn: uncertainty-color,
  row-label-max-chars: 28,
  col-label-max-chars: 22,
  use-cell-colors: true,
) = {
  let ellipsize = (value, max-chars) => {
    if value == none {
      ""
    } else if max-chars == none {
      value
    } else {
      let str-value = if type(value) == str { value } else { str(value) }
      if str-value.len() <= max-chars {
        str-value
      } else if max-chars <= 1 {
        "…"
      } else {
        str-value.slice(0, max-chars - 1) + "…"
      }
    }
  }
  show table.cell: it => {
    if it.x == 0 or it.y == 0 {
      set text(style: "italic")
      it
    } else {
      it
    }
  }

  let table-data = ()

  // Header row anchored to the bottom of its cell
  table-data.push((
    [],
    ..col-headers.map(header => table.cell(align: bottom)[#ellipsize(header, col-label-max-chars)]),
  ))

  for (row-idx, row-name) in row-headers.enumerate() {
    let row = (table.cell()[#ellipsize(row-name, row-label-max-chars)],)
    for (col-idx, val) in data.at(row-idx).enumerate() {
      if val == none {
        row.push(table.cell()[—])
      } else {
        let cell-fill = if use-cell-colors {
          let fn = if type(color-fn) == array { color-fn.at(col-idx) } else { color-fn }
          let mn = if type(min-val) == array { min-val.at(col-idx) } else { min-val }
          let mx = if type(max-val) == array { max-val.at(col-idx) } else { max-val }
          fn(val, mn, mx)
        } else { none }
        row.push(table.cell(fill: cell-fill)[#val])
      }
    }
    table-data.push(row)
  }

  table(
    columns: (auto,) + (1fr,) * col-headers.len(),
    stroke: none,
    align: (x, _) => if x == 0 { left } else { right },
    inset: (x, y) => if x == 0 { (left: 0pt, right: 8pt, top: 5pt, bottom: 5pt) } else { 5pt },
    table.hline(y: 1),
    ..table-data.flatten()
  )
}

#let flex-caption(long, short) = context if in-outline.get() { short } else { long }
