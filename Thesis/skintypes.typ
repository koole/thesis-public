#import "template.typ": (
  color-table, full_width, inverted-uncertainty-color, margin_figure, margin_note, note, numbered_margin_note, thesis,
  white-to-red-color, white-to-green-color
)
#import "@preview/marginalia:0.2.3" as marginalia
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "./lilaq/src/lilaq.typ" as lq
#import "./utils/horizontal-bar-chart.typ": data-table, horizontal-bar-chart
#import "content.typ": (
  dataset_attribution_data, dataset_source_count, fitzpatrick_annotated_pct, fitzpatrick_skin_type_distribution_data,
  format-int, image_type_distribution_data, primary_diagnosis_distribution_data, secondary_diagnosis_distribution_data,
  secondary_diagnosis_distribution_data_cons, total_dataset_images, total_fitzpatrick_annotated,
)

#show: thesis

= Aahhhh

#let skin-type-samples = (
  "I": (
    "ISIC_9255171",
    "ISIC_3415291",
    "ISIC_2883836",
    "ISIC_6285925",
    "ISIC_9315533",
  ),
  "II": (
    "ISIC_3232113",
    "ISIC_3550118",
    "ISIC_1820914",
    "ISIC_1684127",
    "ISIC_4678323",
  ),
  "III": (
    "ISIC_3332799",
    "ISIC_9592049",
    "ISIC_1369882",
    "ISIC_0746536",
    "ISIC_2304572",
  ),
  "IV": (
    "ISIC_6299846",
    "ISIC_9467758",
    "ISIC_2176067",
    "ISIC_3403209",
    "ISIC_7200286",
  ),
  "V": (
    "ISIC_7208298",
    "ISIC_3938032",
    "ISIC_5356953",
    "ISIC_6470845",
    "ISIC_4486817",
  ),
  "VI": (
    "ISIC_6916623",
    "ISIC_7313027",
    "ISIC_7899885",
    "ISIC_7761374",
    "ISIC_0988480",
  ),
)

#let skin-type-order = ("I", "II", "III", "IV", "V", "VI")

#let skin-type-colors = (
  "I": rgb("#e9d8c3"),
  "II": rgb("#dec1a4"),
  "III": rgb("#c8a485"),
  "IV": rgb("#a67859"),
  "V": rgb("#5e3e2e"),
  "VI": rgb("#3a2b24"),
)

#let skin-type-label-text = (
  "I": black,
  "II": black,
  "III": black,
  "IV": white,
  "V": white,
  "VI": white,
)

#let skin-type-column(label, ids) = align(center)[
    #stack(spacing: 0mm)[
      #box(
        width: 100%,
        fill: skin-type-colors.at(label),
        inset: (
          y: 5pt,
          x: 0pt,
        ),
        stroke: none,
      )[
        #text(
          fill: skin-type-label-text.at(label),
          label,
        )
      ]
      #for id in ids {
        block(spacing: 2pt)[
          #image(
            "../Datasets/images/" + id + ".jpg",
            width: 100%,
            height: auto,
            fit: "cover",
          )
        ]
      }
    ]
]

#let skin-type-grid = {
  let columns = skin-type-order.map(label => skin-type-column(label, skin-type-samples.at(label)))
  grid(
    columns: (1fr,) * skin-type-order.len(),
    gutter: 2mm,
    ..columns
  )
}

// #full_width(
  #figure(
    skin-type-grid,
    caption: [Random samples from the test set for each Fitzpatrick skin type.],
  )
// )

