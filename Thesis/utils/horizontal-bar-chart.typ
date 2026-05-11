#import "@preview/cetz:0.4.0"

#let default-colors = (
  rgb("#15803d"), // Green 700
  rgb("#b91c1c"), // Red 700
  rgb("#0369a1"), // Sky 700
  rgb("#7e22ce"), // Purple 700
  rgb("#c2410c"), // Orange 700
  rgb("#047857"), // Emerald 700
  rgb("#1d4ed8"), // Blue 700
  rgb("#be185d"), // Pink 700
  rgb("#a16207"), // Yellow 700
  rgb("#0f766e"), // Teal 700
  rgb("#6d28d9"), // Violet 700
  rgb("#be123c"), // Rose 700
  rgb("#4d7c0f"), // Lime 700
  rgb("#4338ca"), // Indigo 700
  rgb("#b45309"), // Amber 700
  rgb("#0e7490"), // Cyan 700
  rgb("#a21caf"), // Fuchsia 700
)

/// Normalizes data to have percentage values
/// Handles both count-based and percentage-based data
#let normalize-data(data) = {
  let has-count = data.any(item => "count" in item)
  let has-percentage = data.any(item => "percentage" in item)

  if has-count and has-percentage {
    panic("Data cannot contain both 'count' and 'percentage' fields. Use one or the other.")
  }

  if has-count {
    let total-count = data.map(item => item.count).sum()
    if total-count == 0 {
      panic("Total count cannot be zero")
    }

    return data.map(item => (
      label: item.label,
      percentage: calc.round(item.count / total-count * 100, digits: 2),
      count: item.count,
      total: total-count,
    ))
  } else if has-percentage {
    let total-percentage = data.map(item => item.percentage).sum()
    if calc.abs(total-percentage - 100) > 0.01 {
      panic("Total percentage must equal 100%, got " + str(total-percentage) + "%")
    }

    return data.map(item => (
      label: item.label,
      percentage: item.percentage,
    ))
  } else {
    panic("Data must contain either 'count' or 'percentage' field for each item")
  }
}

/// Draws a horizontal bar chart with percentage sections
///
/// Parameters:
/// - data: Array of dictionaries with "label" and either "percentage" OR "count" keys
///   Percentage example: (("label": "Category 1", "percentage": 40), ("label": "Category 2", "percentage": 30))
///   Count example: (("label": "Category 1", "count": 120), ("label": "Category 2", "count": 80))
/// - position: Starting position for the bar (default: (0, 0))
/// - width: Total width of the bar (default: 8)
/// - height: Height of the bar (default: 1)
/// - colors: Array of colors to use for sections (default: predefined palette)
/// - legend-columns: Number of columns for the legend (default: 2)
/// - legend-spacing: Vertical spacing between legend items (default: 0.5)
/// - legend-column-spacing: Horizontal spacing between legend columns (default: 1)
/// - legend-offset: Vertical offset of legend from bar (default: -2)
/// - show-percentages: Whether to show percentages in legend (default: true)
/// - show-counts: Whether to show counts in legend when available (default: false)
/// - max-legend-items: Maximum number of items to show in legend, rest grouped as "Others" (default: none for no limit)
#let horizontal-bar-chart(
  data,
  position: (0, 0),
  width: 11.4,
  height: 1,
  colors: default-colors,
  legend-columns: 2,
  legend-spacing: 0.5,
  legend-column-spacing: 0.1,
  legend-offset: -0.5,
  show-percentages: true,
  show-counts: false,
  max-legend-items: none,
  legend-label-max-chars: 55,
  legend-right-max-chars: none,
) = {
  let chart-width = width
  let normalized-data = normalize-data(data)

  let legend-data = if max-legend-items != none and normalized-data.len() > max-legend-items {
    let shown-items = normalized-data.slice(0, max-legend-items - 1)

    // Remaining items are collapsed into a single "Others" entry
    let remaining-items = normalized-data.slice(max-legend-items - 1)
    let others-percentage = remaining-items.map(item => item.percentage).sum()
    let others-count = if "count" in remaining-items.first() {
      remaining-items.map(item => item.count).sum()
    } else {
      none
    }

    let others-item = (
      label: "Others",
      percentage: calc.round(others-percentage, digits: 2),
    )

    if others-count != none {
      others-item.insert("count", others-count)
    }

    shown-items + (others-item,)
  } else {
    normalized-data
  }

  let ellipsize = (value, max-chars) => {
    if value == none or max-chars == none {
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

  cetz.canvas({
    import cetz.draw: *

  let (start-x, start-y) = position
  let current-x = start-x

    for (i, item) in normalized-data.enumerate() {
      let section-width = chart-width * item.percentage / 100
      let color = colors.at(calc.rem(i, colors.len()))

      rect(
        (current-x, start-y),
        (current-x + section-width, start-y + height),
        fill: color,
        stroke: white + 1pt,
      )

      current-x += section-width
    }

  let legend-y = start-y + legend-offset
  let items-per-column = calc.ceil(legend-data.len() / legend-columns)
  let available-width = chart-width - (legend-columns - 1) * legend-column-spacing
  let column-width = available-width / legend-columns

    for (i, item) in legend-data.enumerate() {
      let column = calc.quo(i, items-per-column)
      let row = calc.rem(i, items-per-column)

      let legend-x = start-x + column * (column-width + legend-column-spacing)
      let legend-item-y = legend-y - row * legend-spacing

      // "Others" gets a white swatch so it reads as a residual bucket
      let color = if item.label == "Others" {
        white
      } else {
        colors.at(calc.rem(i, colors.len()))
      }

      rect(
        (legend-x, legend-item-y - 0.1),
        (legend-x + 0.3, legend-item-y + 0.12),
        fill: color,
        stroke: none,
      )

      let label-text = ellipsize(item.label, legend-label-max-chars)
      let right-parts = ()

      if show-counts and "count" in item {
        right-parts.push("n=" + str(item.count))
      }

      if show-percentages {
        right-parts.push(str(item.percentage) + "%")
      }

      let right-text = "(" + right-parts.join(" ") + ")"
      right-text = ellipsize(right-text, legend-right-max-chars)

      content(
        (legend-x + 0.4, legend-item-y),
        text(size: 10pt, label-text),
        anchor: "west",
      )

      if right-text != "" {
        content(
          (legend-x + column-width - 0.1, legend-item-y),
          text(size: 10pt, right-text),
          anchor: "east",
        )
      }
    }
  })
}

/// Creates a table showing label, count, and percentage for each category
///
/// Parameters:
/// - data: Array of dictionaries with "label" and either "percentage" OR "count" keys
///   Same format as horizontal-bar-chart function
/// - show-total: Whether to include a total row at the bottom (default: true)
/// - caption: Optional caption for the table
#let data-table(
  data,
  show-total: true,
  caption: none,
) = {
  let normalized-data = normalize-data(data)

  let table-data = (
    [*Category*],
    [*Count*],
    [*Percentage*],
  )

  for item in normalized-data {
    table-data.push(item.label)
    if "count" in item {
      table-data.push(str(item.count))
    } else {
      table-data.push("—")
    }
    table-data.push(str(item.percentage) + "%")
  }

  if show-total and "count" in normalized-data.first() {
    let total-count = normalized-data.map(item => item.count).sum()
    table-data.push([*Total*])
    table-data.push([*#str(total-count)*])
    table-data.push([*100%*])
  }

  let result-table = table(
    columns: 3,
    align: (left, right, right),
    stroke: 0.5pt,
    inset: 8pt,
    ..table-data
  )

  if caption != none {
    figure(
      result-table,
      caption: caption,
    )
  } else {
    result-table
  }
}
