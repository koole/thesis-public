#import "template.typ": (
  color-table, flex-caption, full_width, inverted-uncertainty-color, margin_figure, margin_note, metadata-label, note,
  numbered_margin_note, ratio-color, thesis, uncertainty-color, white-to-green-color, white-to-red-color,
)
#import "@preview/marginalia:0.2.3" as marginalia
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "./lilaq/src/lilaq.typ" as lq
#import "./utils/horizontal-bar-chart.typ": data-table, horizontal-bar-chart
#import "content.typ": (
  dataset_attribution_data, dataset_source_count, dataset_split_distribution_data, fitzpatrick_annotated_pct,
  fitzpatrick_skin_type_distribution_data, format-int, image_type_distribution_data,
  primary_diagnosis_distribution_data, primary_diagnosis_distribution_data_cons, primary_diagnosis_test_data,
  primary_diagnosis_train_data, primary_diagnosis_val_data, secondary_diagnosis_distribution_data,
  secondary_diagnosis_distribution_data_cons, total_dataset_images, total_fitzpatrick_annotated,
)

#let metrics_dir = "../Notebooks/results/metrics"
#let predictive_entropy_rows = csv(
  metrics_dir + "/predictive_entropy_distribution_test_set.csv",
  row-type: dictionary,
)

#let read-dist(path, label-field: "group_value", count-field: "count") = {
  let rows = csv(path, row-type: dictionary)
  rows.map(r => (
    "label": r.at(label-field),
    "count": int(r.at(count-field)),
  ))
}

#let dist_skin_type = read-dist(metrics_dir + "/distribution_test_set_by_fitzpatrick_skin_type.csv")

#let test_set_rows = csv("../Datasets/splits/test_set.csv", row-type: dictionary)

#let build-metadata-lookup(field) = {
  let lookup = (:)
  for row in test_set_rows {
    let value = row.at(field, default: none)
    if value != none and value != "" {
      lookup.insert(row.isic_id, value)
    }
  }
  lookup
}

#let find-index(seq, needle) = {
  for (idx, item) in seq.enumerate() {
    if item == needle {
      return idx
    }
  }
  none
}

#let fitzpatrick_skin_types = ("I", "II", "III", "IV", "V", "VI")

#let collect-entropy-by-metadata(categories, metadata_lookup, head: "head2") = {
  let grouped = categories.map(_ => ())
  for row in predictive_entropy_rows {
    if row.dataset != "test_set" or row.head != head or row.run_type != "ensemble" {
      continue
    }
    let value = metadata_lookup.at(row.isic_id, default: none)
    if value == none or value == "" {
      continue
    }
    let idx = find-index(categories, value)
    if idx != none {
      grouped.at(idx).push(float(row.predictive_entropy))
    }
  }
  grouped
}

#let fitzpatrick_lookup = build-metadata-lookup("fitzpatrick_skin_type")

#let build-skin-entropy-distribution = head => (
  skin_types: fitzpatrick_skin_types,
  grouped: collect-entropy-by-metadata(
    fitzpatrick_skin_types,
    fitzpatrick_lookup,
    head: head,
  ),
)

#let ensemble_head1_entropy_distributions_by_skin = build-skin-entropy-distribution("head1")
#let ensemble_head2_entropy_distributions_by_skin = build-skin-entropy-distribution("head2")

#show: thesis.with(
  title: "Uncertainty Quantification in Dermatological AI",
  author: "Your Name",
  abstract: [
    Deep learning models for skin lesion classification can help clinicians detect skin cancer early, but clinical use requires that models indicate when their predictions should not be trusted. Uncertainty quantification (UQ) methods can flag unreliable predictions, yet few studies compare techniques from different UQ families under identical conditions in a dermatological setting.

    This thesis compares five UQ methods: Monte Carlo Dropout, Monte Carlo DropConnect, Flipout, Deep Ensembles, and Deterministic Uncertainty Quantification (DUQ). All make use of an EfficientNet-B3 backbone with two heads, one for binary malignant detection and one for five-class diagnosis. All five are trained and evaluated on over 90,000 dermoscopic and clinical images from the ISIC Archive.

    Deep Ensembles performs best on all three reliability dimensions defined in this thesis: predictive accuracy, calibration of confidence estimates, and the ability to identify cases for deferral to a human expert. MC Dropout and DropConnect match its accuracy but calibrate considerably worse. Flipout falls below the baseline in accuracy and produces near-zero epistemic uncertainty. All methods largely agree on which samples are difficult (pairwise Spearman correlations of 0.54 to 0.91), suggesting that the choice of UQ method matters more for calibration quality than for identifying hard cases. Analysis of patient metadata shows that malignant samples for darker Fitzpatrick skin types are nearly absent from the dataset, so uncertainty estimates for these populations cannot yet be validated.
  ],
  acknowledgments: [
    First, I want to thank my supervisors Jiapan Guo and Matias Valdenegro Toro. Our meetings were always genuinely helpful, and their feedback kept me on track throughout. Matias deserves a special mention for being incredibly supportive and patient with me over the past two years.

    Thanks also to my friends and family for putting up with me while I was buried in this thesis. It helped more than you probably know.
  ],
)

#let skin_types_head1 = ensemble_head1_entropy_distributions_by_skin.skin_types
#let distributions_head1 = ensemble_head1_entropy_distributions_by_skin.grouped
#let skin_types_head2 = ensemble_head2_entropy_distributions_by_skin.skin_types
#let distributions_head2 = ensemble_head2_entropy_distributions_by_skin.grouped
#let skin_palette = (
  rgb("#e9d8c3"),
  rgb("#dec1a4"),
  rgb("#c8a485"),
  rgb("#a67859"),
  rgb("#5e3e2e"),
  rgb("#3a2b24"),
)

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

// === Results Section Helper Functions and Data Loading ===

#let read-metrics(path) = {
  let rows = csv(path, row-type: dictionary)
  if rows.len() > 0 {
    rows.at(0)
  } else {
    none
  }
}

#let read-grouped-metrics(path) = {
  csv(path, row-type: dictionary)
}

#let read-calibration(path) = {
  csv(path, row-type: dictionary)
}

#let to_float(val, decimals: 3, default: 0.0) = {
  if val == none or val == "" {
    return default
  }
  let num = if type(val) == str {
    float(val)
  } else {
    val
  }
  calc.round(num, digits: decimals)
}

#let fmt(val, decimals: 3) = {
  if val == none or val == "" {
    return "—"
  }
  let num = if type(val) == str {
    float(val)
  } else {
    val
  }
  // Check for NaN by comparing to itself (NaN != NaN)
  if num != num {
    return "—"
  }
  str(calc.round(num, digits: decimals))
}

#let collect-group-metric(rows, categories, field, default: 0.0) = {
  let values = ()
  for cat in categories {
    let row = rows.find(r => r.group_value == cat)
    if row != none {
      values.push(to_float(row.at(field)))
    } else {
      values.push(default)
    }
  }
  values
}

#let transpose(data) = {
  if data.len() == 0 { return () }
  let n-cols = data.at(0).len()
  let result = ()
  for col-idx in range(n-cols) {
    let new-row = data.map(row => row.at(col-idx))
    result.push(new-row)
  }
  result
}

#let model_labels = ("Baseline", "Deep Ensembles", "MC Dropout", "DropConnect", "Flipout", "DUQ")
#let model_labels_uq = ("Deep Ensembles", "MC Dropout", "DropConnect", "Flipout")  // For uncertainty decomposition; excludes baseline and DUQ since they can not decompose uncertainty
#let model_labels_short = ("BL", "ENS", "DO", "DC", "FLP", "DUQ")  // Short labels for compact tables
#let model_labels_short_uq = ("ENS", "DO", "DC", "FLP", "DUQ")
#let model_run_types = ("baseline", "ensemble", "dropout", "dropconnect", "flipout", "duq")
#let model_palette = (
  rgb("#6b7280"), // Gray 500 (baseline)
  rgb("#15803d"), // Green 700
  rgb("#b91c1c"), // Red 700
  rgb("#0369a1"), // Sky 700
  rgb("#7e22ce"), // Purple 700
  rgb("#ca8a04"), // Yellow 600 (DUQ)
)

#let metrics_dir = "../Notebooks/results/metrics"

#let baseline_test_head1 = read-metrics(metrics_dir + "/metrics_baseline_test_set_head1.csv")
#let ensemble_test_head1 = read-metrics(metrics_dir + "/metrics_ensemble_test_set_head1.csv")
#let dropout_test_head1 = read-metrics(metrics_dir + "/metrics_dropout_test_set_head1.csv")
#let dropconnect_test_head1 = read-metrics(metrics_dir + "/metrics_dropconnect_test_set_head1.csv")
#let flipout_test_head1 = read-metrics(metrics_dir + "/metrics_flipout_test_set_head1.csv")

#let baseline_test_head2 = read-metrics(metrics_dir + "/metrics_baseline_test_set_head2.csv")
#let ensemble_test_head2 = read-metrics(metrics_dir + "/metrics_ensemble_test_set_head2.csv")
#let dropout_test_head2 = read-metrics(metrics_dir + "/metrics_dropout_test_set_head2.csv")
#let dropconnect_test_head2 = read-metrics(metrics_dir + "/metrics_dropconnect_test_set_head2.csv")
#let flipout_test_head2 = read-metrics(metrics_dir + "/metrics_flipout_test_set_head2.csv")
#let duq_test_head1 = read-metrics(metrics_dir + "/metrics_duq_test_set_head1.csv")
#let duq_test_head2 = read-metrics(metrics_dir + "/metrics_duq_test_set_head2.csv")

#let baseline_test_indet_head1 = read-metrics(metrics_dir + "/metrics_baseline_test_indeterminate_set_head1.csv")
#let ensemble_test_indet_head1 = read-metrics(metrics_dir + "/metrics_ensemble_test_indeterminate_set_head1.csv")
#let dropout_test_indet_head1 = read-metrics(metrics_dir + "/metrics_dropout_test_indeterminate_set_head1.csv")
#let dropconnect_test_indet_head1 = read-metrics(metrics_dir + "/metrics_dropconnect_test_indeterminate_set_head1.csv")
#let flipout_test_indet_head1 = read-metrics(metrics_dir + "/metrics_flipout_test_indeterminate_set_head1.csv")

#let baseline_test_indet_head2 = read-metrics(metrics_dir + "/metrics_baseline_test_indeterminate_set_head2.csv")
#let ensemble_test_indet_head2 = read-metrics(metrics_dir + "/metrics_ensemble_test_indeterminate_set_head2.csv")
#let dropout_test_indet_head2 = read-metrics(metrics_dir + "/metrics_dropout_test_indeterminate_set_head2.csv")
#let dropconnect_test_indet_head2 = read-metrics(metrics_dir + "/metrics_dropconnect_test_indeterminate_set_head2.csv")
#let flipout_test_indet_head2 = read-metrics(metrics_dir + "/metrics_flipout_test_indeterminate_set_head2.csv")
#let duq_test_indet_head1 = read-metrics(metrics_dir + "/metrics_duq_test_indeterminate_set_head1.csv")
#let duq_test_indet_head2 = read-metrics(metrics_dir + "/metrics_duq_test_indeterminate_set_head2.csv")

#let cal_baseline_test_head1 = read-calibration(metrics_dir + "/calibration_baseline_test_set_head1.csv")
#let cal_ensemble_test_head1 = read-calibration(metrics_dir + "/calibration_ensemble_test_set_head1.csv")
#let cal_dropout_test_head1 = read-calibration(metrics_dir + "/calibration_dropout_test_set_head1.csv")
#let cal_dropconnect_test_head1 = read-calibration(metrics_dir + "/calibration_dropconnect_test_set_head1.csv")
#let cal_flipout_test_head1 = read-calibration(metrics_dir + "/calibration_flipout_test_set_head1.csv")

#let cal_baseline_test_head2 = read-calibration(metrics_dir + "/calibration_baseline_test_set_head2.csv")
#let cal_ensemble_test_head2 = read-calibration(metrics_dir + "/calibration_ensemble_test_set_head2.csv")
#let cal_dropout_test_head2 = read-calibration(metrics_dir + "/calibration_dropout_test_set_head2.csv")
#let cal_dropconnect_test_head2 = read-calibration(metrics_dir + "/calibration_dropconnect_test_set_head2.csv")
#let cal_flipout_test_head2 = read-calibration(metrics_dir + "/calibration_flipout_test_set_head2.csv")
#let cal_duq_test_head1 = read-calibration(metrics_dir + "/calibration_duq_test_set_head1.csv")
#let cal_duq_test_head2 = read-calibration(metrics_dir + "/calibration_duq_test_set_head2.csv")

#let h1_pct = csv(metrics_dir + "/class_distribution_by_skintype_head1_pct.csv", row-type: dictionary)
#let h2_pct = csv(metrics_dir + "/class_distribution_by_skintype_head2_pct.csv", row-type: dictionary)
#let h1_counts = csv(metrics_dir + "/class_distribution_by_skintype_head1.csv", row-type: dictionary)
#let h2_counts = csv(metrics_dir + "/class_distribution_by_skintype_head2.csv", row-type: dictionary)
#let entropy_within_diag = csv(metrics_dir + "/entropy_by_skintype_within_diagnosis.csv", row-type: dictionary)
#let cross_model_ratio = csv(metrics_dir + "/cross_model_overconfidence_by_skintype.csv", row-type: dictionary)
#let indet_comparison = csv(metrics_dir + "/entropy_test_vs_indeterminate.csv", row-type: dictionary)
#let perf_data = csv(metrics_dir + "/skintype_performance_summary_head1.csv", row-type: dictionary)
#let diagnosis_by_confirm = csv(metrics_dir + "/diagnosis_by_confirmation_type.csv", row-type: dictionary)

#let diagnosis2_dist = csv(metrics_dir + "/distribution_test_set_by_diagnosis_2.csv", row-type: dictionary)

#let ensemble_diagnosis2_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_ensemble_test_set_head1_by_diagnosis_2.csv",
)
#let dropout_diagnosis2_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_dropout_test_set_head1_by_diagnosis_2.csv",
)
#let dropconnect_diagnosis2_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_dropconnect_test_set_head1_by_diagnosis_2.csv",
)
#let flipout_diagnosis2_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_flipout_test_set_head1_by_diagnosis_2.csv",
)
#let duq_diagnosis2_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_duq_test_set_head1_by_diagnosis_2.csv",
)

#let attribution_dist = csv(metrics_dir + "/distribution_test_set_by_attribution.csv", row-type: dictionary)

#let ensemble_attribution_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_ensemble_test_set_head1_by_attribution.csv",
)
#let dropout_attribution_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_dropout_test_set_head1_by_attribution.csv",
)
#let dropconnect_attribution_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_dropconnect_test_set_head1_by_attribution.csv",
)
#let flipout_attribution_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_flipout_test_set_head1_by_attribution.csv",
)
#let duq_attribution_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_duq_test_set_head1_by_attribution.csv",
)

#let diagnosis_confirm_dist = csv(
  metrics_dir + "/distribution_test_set_by_diagnosis_confirm_type.csv",
  row-type: dictionary,
)

#let ensemble_diagnosis_confirm_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_ensemble_test_set_head1_by_diagnosis_confirm_type.csv",
)
#let dropout_diagnosis_confirm_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_dropout_test_set_head1_by_diagnosis_confirm_type.csv",
)
#let dropconnect_diagnosis_confirm_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_dropconnect_test_set_head1_by_diagnosis_confirm_type.csv",
)
#let flipout_diagnosis_confirm_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_flipout_test_set_head1_by_diagnosis_confirm_type.csv",
)
#let duq_diagnosis_confirm_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_duq_test_set_head1_by_diagnosis_confirm_type.csv",
)

#let ensemble_skintype_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_ensemble_test_set_head1_by_fitzpatrick_skin_type.csv",
)
#let dropout_skintype_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_dropout_test_set_head1_by_fitzpatrick_skin_type.csv",
)
#let dropconnect_skintype_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_dropconnect_test_set_head1_by_fitzpatrick_skin_type.csv",
)
#let flipout_skintype_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_flipout_test_set_head1_by_fitzpatrick_skin_type.csv",
)
#let duq_skintype_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_duq_test_set_head1_by_fitzpatrick_skin_type.csv",
)

#let image_type_dist = csv(
  metrics_dir + "/distribution_test_set_by_image_type.csv",
  row-type: dictionary,
)

#let ensemble_image_type_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_ensemble_test_set_head1_by_image_type.csv",
)
#let dropout_image_type_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_dropout_test_set_head1_by_image_type.csv",
)
#let dropconnect_image_type_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_dropconnect_test_set_head1_by_image_type.csv",
)
#let flipout_image_type_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_flipout_test_set_head1_by_image_type.csv",
)
#let duq_image_type_h1 = read-grouped-metrics(
  metrics_dir + "/metrics_duq_test_set_head1_by_image_type.csv",
)

#let influence_flipout_h1 = csv(metrics_dir + "/influence_analysis_flipout_test_set_head1.csv", row-type: dictionary)
#let influence_flipout_h2 = csv(metrics_dir + "/influence_analysis_flipout_test_set_head2.csv", row-type: dictionary)
#let influence_ensemble_h1 = csv(metrics_dir + "/influence_analysis_ensemble_test_set_head1.csv", row-type: dictionary)
#let influence_ensemble_h2 = csv(metrics_dir + "/influence_analysis_ensemble_test_set_head2.csv", row-type: dictionary)
#let influence_dropout_h1 = csv(metrics_dir + "/influence_analysis_dropout_test_set_head1.csv", row-type: dictionary)
#let influence_dropout_h2 = csv(metrics_dir + "/influence_analysis_dropout_test_set_head2.csv", row-type: dictionary)
#let influence_dropconnect_h1 = csv(
  metrics_dir + "/influence_analysis_dropconnect_test_set_head1.csv",
  row-type: dictionary,
)
#let influence_dropconnect_h2 = csv(
  metrics_dir + "/influence_analysis_dropconnect_test_set_head2.csv",
  row-type: dictionary,
)
#let influence_duq_h1 = csv(metrics_dir + "/influence_analysis_duq_test_set_head1.csv", row-type: dictionary)
#let influence_duq_h2 = csv(metrics_dir + "/influence_analysis_duq_test_set_head2.csv", row-type: dictionary)

#let predictive_entropy_rows = csv(metrics_dir + "/predictive_entropy_distribution_test_set.csv", row-type: dictionary)

#let aurc_data = csv(metrics_dir + "/risk_coverage_aurc.csv", row-type: dictionary)
#let lookup_aurc(method, head) = {
  let row = aurc_data.find(r => r.method == method and r.head == head)
  if row != none { to_float(row.aurc, decimals: 3) } else { none }
}

#let find-index(seq, needle) = {
  for (idx, item) in seq.enumerate() {
    if item == needle {
      return idx
    }
  }
  none
}

// UQ-only model configuration. Excludes baseline because single models have no meaningful entropy distribution.
// DUQ is included: entropy is computed on its normalized RBF outputs for comparable uncertainty.
#let uq_model_labels = ("Deep Ensembles", "MC Dropout", "DropConnect", "Flipout", "DUQ")
#let uq_model_run_types = ("ensemble", "dropout", "dropconnect", "flipout", "duq")
#let uq_model_palette = (
  rgb("#15803d"), // Green 700
  rgb("#b91c1c"), // Red 700
  rgb("#0369a1"), // Sky 700
  rgb("#7e22ce"), // Purple 700
  rgb("#ca8a04"), // Yellow 600
)

#let collect-entropy-distribution(rows, head, predicate: none) = {
  let grouped = uq_model_run_types.map(_ => ())
  for row in rows {
    if row.head != head {
      continue
    }
    if predicate != none and not predicate(row) {
      continue
    }
    let idx = find-index(uq_model_run_types, row.run_type)
    if idx != none and row.predictive_entropy != "" {
      grouped.at(idx).push(float(row.predictive_entropy))
    }
  }
  grouped
}

#let predictive_entropy_head1 = collect-entropy-distribution(predictive_entropy_rows, "head1")
#let predictive_entropy_head2 = collect-entropy-distribution(predictive_entropy_rows, "head2")


#let predictive_entropy_indet_rows = csv(
  metrics_dir + "/predictive_entropy_distribution_test_indeterminate_set.csv",
  row-type: dictionary,
)
#let predictive_entropy_indet_head1 = collect-entropy-distribution(predictive_entropy_indet_rows, "head1")
#let predictive_entropy_indet_head2 = collect-entropy-distribution(predictive_entropy_indet_rows, "head2")

#let extract-calibration-points(cal_data, threshold: 20) = {
  let xs_all = ()
  let ys_all = ()
  let xs_high = ()
  let ys_high = ()
  let counts = ()
  for row in cal_data {
    let count = int(row.count)
    // Skip rows with count=0 or empty confidence/accuracy values
    if count > 0 and row.avg_confidence != "" and row.avg_accuracy != "" {
      let x = float(row.avg_confidence)
      let y = float(row.avg_accuracy)
      xs_all.push(x)
      ys_all.push(y)
      counts.push(count)
      if count >= threshold {
        xs_high.push(x)
        ys_high.push(y)
      }
    }
  }
  (xs_all: xs_all, ys_all: ys_all, xs_high: xs_high, ys_high: ys_high, counts: counts)
}

#let skin_types = ("I", "II", "III", "IV", "V", "VI")

// === End Results Section Helper Functions ===

= Introduction

== The Diagnostic Challenge

Most skin lesions are benign. Even so, skin cancer is the most common form of cancer worldwide @iarc_skin_cancer. Skin cancers fall into two broad categories: non-melanoma cancers, which include basal cell carcinoma#numbered_margin_note[Basal cell carcinoma and squamous cell carcinoma are cancers of the outer skin layers. They grow slowly and rarely spread, unlike melanoma, which arises from melanocytes (pigment-producing cells) and can spread rapidly.] and squamous cell carcinoma, and melanoma. Non-melanoma cases outnumber melanoma by a wide margin, yet they are rarely fatal. Melanoma, by contrast, accounts for only a small fraction of skin cancer diagnoses but causes the majority of skin cancer deaths @caravielloMelanomaSkinCancer2025.

Melanoma incidence has risen steadily over the past several decades, driven mainly by increased UV exposure @caravielloMelanomaSkinCancer2025. The growing number of cases puts pressure on healthcare systems that already face limited dermatological capacity.

Melanoma caught early is usually curable, but caught late it is often fatal. The five-year survival rate exceeds 99% when the cancer is still localized but drops to around 35% once it has metastasized#numbered_margin_note[Metastasis is the spread of cancer cells from the original tumor to distant organs through the bloodstream or lymphatic system.] @acs_melanoma_survival. This gap is why earlier detection matters so much. The challenge, however, is that diagnosis itself is difficult.

When examining a suspicious lesion, clinicians typically apply the _ABCDE_ criteria @tsaoEarlyDetectionMelanoma2015:

#table(
  columns: (auto, 1fr),
  stroke: none,
  column-gutter: 8pt,
  inset: (x: 0pt, y: 0pt),
  row-gutter: 8pt,
  [*Asymmetry*], [One half of the lesion does not match the other],
  [*Border irregularity*], [Ragged or blurred edges rather than a smooth outline],
  [*Color variation*], [Multiple shades of brown, black, red, or blue within a single lesion],
  [*Diameter*], [Greater than 6 mm],
  [*Evolution*], [Any change in size, shape, or color over time],
)

These criteria are a useful screening guide but far from definitive: individual criteria have sensitivities between 57% and 90% @caravielloMelanomaSkinCancer2025. The main source of diagnostic confusion is the nevus#numbered_margin_note[A nevus is a benign growth of melanocytes, the cells that produce the skin pigment melanin. In everyday terms, a mole.], a benign melanocyte cluster, or in everyday terms, a mole. Most adults have between 10 and 40 nevi, and some of these develop atypical or dysplastic features (irregular color, asymmetric shape, blurred borders) that overlap with the criteria used to flag melanoma.

#pagebreak()

#margin_figure(
  image("images/dermatoscope.jpg", width: 95%),
  caption: flex-caption(
    [A handheld dermatoscope, showing the ring of LEDs that illuminates the skin for magnified examination. Photo by Abessemans94 via Wikimedia Commons (CC BY-SA 4.0).],
    [A handheld dermatoscope.],
  ),
) <dermatoscope_photo>

The primary method for evaluating these lesions beyond naked-eye inspection is dermoscopy. A dermatoscope (@dermatoscope_photo) is a handheld device that provides magnification and polarized lighting, allowing clinicians to visualize structures beneath the skin surface that are invisible to the naked eye. Among the features it reveals are pigment networks, which are the lattice-like patterns formed by melanin distribution in the upper skin layers. Dermoscopy also shows vascular patterns and structural details such as globules, streaks, and blue-white veils @caravielloMelanomaSkinCancer2025.

A systematic review by the Cochrane Library covering 104 studies and 42,788 lesions found that naked-eye examination achieved roughly 76% sensitivity at 80% specificity for melanoma detection. Adding dermoscopy raised sensitivity to approximately 92% @dinnesDermoscopyVisualInspection2018. Dermoscopy helps, but a substantial gap remains.

When dermoscopic assessment is inconclusive, the next step is biopsy: a tissue sample is surgically removed and examined under a microscope by a pathologist, a process called histopathology. This is the established reference standard for melanoma diagnosis @dinnesDermoscopyVisualInspection2018, but it is invasive and only performed on lesions that are clinically suspicious. Non-invasive alternatives such as reflectance confocal microscopy can supplement dermoscopy but are less widely available @dinnesDermoscopyVisualInspection2018.

In dermatological datasets, the method used to confirm a diagnosis is recorded as the _confirmation type_. Because histopathology is reserved for the most suspicious cases, it selects for diagnostically harder lesions.

#let pairs = ("03", "05", "06", "08", "31", "45")

#figure(
  {
    align(left, text()[*Benign*])
    v(-2mm)
    grid(
      columns: (1fr,) * pairs.len(),
      column-gutter: 2mm,
      ..pairs.map(p => layout(size => box(
        clip: true,
        width: 100%,
        height: size.width,
        image("images/similar_pairs/pair_" + p + "_benign.jpg", width: 100%, height: 100%, fit: "cover"),
      ))),
    )
    align(left, text()[*Malignant*])
    v(-2mm)
    grid(
      columns: (1fr,) * pairs.len(),
      column-gutter: 2mm,
      ..pairs.map(p => layout(size => box(
        clip: true,
        width: 100%,
        height: size.width,
        image("images/similar_pairs/pair_" + p + "_malignant.jpg", width: 100%, height: 100%, fit: "cover"),
      ))),
    )
    v(1mm)
  },
  caption: flex-caption(
    [Examples of visually similar benign–malignant lesion pairs from the ISIC archive. Each column shows a benign (top) and malignant (bottom) lesion paired by similarity in a neural network's learned feature representation. The visual diversity across columns demonstrates intra-class variation.],
    [Visually similar benign–malignant lesion pairs from the ISIC archive.],
  ),
) <fig:interclass-similarity>

Part of the difficulty is that different conditions can look nearly identical. @fig:interclass-similarity shows pairs of benign and malignant lesions that a neural network's internal representations placed close together, indicating high visual similarity. Even with dermoscopy, distinguishing melanoma from an atypical nevus can be ambiguous.

Variation within diagnostic categories adds to the problem: the same condition presents differently across skin tones, body locations, and imaging conditions. Observer experience also affects accuracy, as the Cochrane Library review found that diagnostic performance varied substantially with clinician training @dinnesDermoscopyVisualInspection2018.

Other than diagnostic accuracy, access to dermatological expertise is itself limited. An estimated three billion people worldwide lack access to dermatological care @daneshjouDisparitiesDermatologyAI2022. In regions without specialists, suspicious lesions either go unexamined or are assessed by general practitioners with less training in dermoscopy. For melanoma, where delayed diagnosis directly worsens patient outcomes, this access gap matters.

These diagnostic difficulties and the shortage of specialists make automated screening tools worth pursuing. Most recent work in this area uses deep learning.

#pagebreak()

== Deep Learning for Skin Lesion Classification

In 2017, A. Esteva et al. @esteva2017dermatologist demonstrated that a convolutional neural network could classify skin cancer at a level matching board-certified dermatologists. A systematic review of 19 reader studies (controlled experiments in which clinicians classify a set of images) found that CNN-based classifiers performed at or above clinician level in every case @haggenmullerSkinCancerClassification2021.

Large public datasets made this progress possible, particularly the ISIC Archive#numbered_margin_note[The International Skin Imaging Collaboration (ISIC) Archive is an open repository of dermoscopic and clinical skin lesion images contributed by institutions worldwide.] and HAM10000 @isic_archive @tschandl2018ham10000 @cassidyAnalysisISICImage2022. Transfer learning from ImageNet (reusing features learned on a large general-purpose image dataset) reduced the volume of labeled medical images needed for training. The systematic review noted, however, that nearly all evaluations used highly artificial settings based on single curated images, with test sets that did not represent the full range of patient populations encountered in practice @haggenmullerSkinCancerClassification2021.

The appeal of such models for clinical screening is obvious. A trained network can process essentially unlimited images, making it attractive for settings where dermatologists are scarce. Deployment on smartphones or online platforms could extend diagnostic reach to populations that currently have none.

Yet the conditions that produce strong test-set accuracy often do not hold in real-world scenarios. The 2019 ISIC Grand Challenge quantified this gap directly: the best-performing algorithm achieved 82% balanced accuracy (the average of per-class accuracies, used because classes are imbalanced) on the HAM10000 benchmark but only 59% on a test set designed to reflect realistic clinical conditions, with shifted distributions and disease categories absent from training data @combaliaValidationAISkinCancer2022. Nearly half of images from categories not seen during training were misclassified as malignant, a pattern that would trigger many unnecessary biopsies#numbered_margin_note[A biopsy is the surgical removal of a small tissue sample for microscopic examination to confirm or rule out cancer.] in clinical deployment.

Several factors cause this fragility. Malignant lesions are rare relative to benign ones in most training datasets, and this class imbalance can bias models toward the majority class @iqbalAutomatedMulticlassClassification2021. Models trained on predominantly light-skinned populations also perform worse on darker skin tones @daneshjouDisparitiesDermatologyAI2022. On top of that, data from different clinical sites varies in imaging equipment and clinical protocols, creating distribution shifts that a model trained on one source may not handle well @wangEmbracingDisharmonyMedical2022. @fig:distribution-shift illustrates this: six melanoma images from different institutions look extremely different.

#let shift_images = (
  ("ISIC_0053808", "Hosp. Clínic\nBarcelona"),
  ("ISIC_1353101", "Royal Prince\nAlfred Hosp."),
  ("ISIC_0028056", "MILK Study"),
  ("ISIC_0319701", "Imperial College\nLondon"),
  ("ISIC_9497071", "MILK Study\n(clinical)"),
  ("ISIC_1480614", "Memorial Sloan\nKettering (TBP)"),
)

#figure(
  grid(
    columns: (1fr,) * shift_images.len(),
    column-gutter: 2mm,
    row-gutter: 2mm,
    ..shift_images.map(((id, _)) => layout(size => box(
      clip: true,
      width: 100%,
      height: size.width,
      image("images/distribution_shift/" + id + ".jpg", width: 100%, height: 100%, fit: "cover"),
    ))),
    ..shift_images.map(((_, label)) => align(center, text(size: 0.65em)[#label])),
  ),
  caption: flex-caption(
    [Six melanoma images from different data sources and imaging modalities. The images differ substantially in background color, magnification, lighting, and resolution due to differences in clinical equipment and imaging protocols.],
    [Melanoma images from different data sources and imaging modalities.],
  ),
) <fig:distribution-shift>

== Model Uncertainty and Calibration

A model that achieves 90% accuracy on a held-out test set may still fail on rare conditions, underrepresented skin tones, or ambiguous lesions. Aggregate metrics hide failures on individual predictions.

Uncertainty quantification can flag individual predictions where distribution shift, class imbalance, or unfamiliar inputs make the model's output unreliable. When a wrong prediction means a missed melanoma or an unnecessary biopsy, knowing which predictions to trust is as relevant as the overall accuracy number.

This gap between aggregate accuracy and individual prediction reliability is where model uncertainty becomes important. Most neural networks output a single prediction with a softmax probability attached. That probability gives some signal of confidence, but it is not a reliable one @vandenbergUncertaintyAssessmentDeep2022. A clinician receiving such output cannot accurately tell whether the model is responding to clear diagnostic features or effectively guessing.

Modern deep networks are poorly calibrated, meaning their reported confidence does not reliably reflect how often they are correct. C. Guo et al. @pmlr-v70-guo17a showed that a prediction reported at 90% confidence may be correct far less often. In medical imaging, A. Mehrtash et al. @mehrtashConfidenceCalibrationMedical2020 found that networks trained with standard loss functions are overconfident, reporting high certainty even when their predictions are wrong. Models can also assign high confidence to inputs entirely outside their training data @gawlikowskiSurveyUncertaintyDeep2023. The confidence score attached to a prediction cannot simply be taken at face value.

The consequences in a clinical setting are concrete. @fig:false-negative shows a confirmed melanoma from our dataset that a single model classified as benign with 97.7% confidence. If a clinician relied on that prediction, the result could be a delayed diagnosis with direct consequences for the patient. When the same image was evaluated by a deep ensemble of five models, four predicted benign but one correctly identified the lesion as malignant. The resulting disagreement produced high uncertainty (measured by the entropy of the combined predictions), flagging the case for human review. A missed melanoma is the most serious failure mode, as it can lead to potentially life-threatening consequences. On the other side, unnecessary biopsies triggered by false positives waste clinical resources.

#figure(
  layout(size => box(
    clip: true,
    width: 30%,
    height: size.width * 0.3,
    image("images/ISIC_0071017.jpg", width: 100%, height: 100%, fit: "cover"),
  )),
  caption: flex-caption(
    [A confirmed melanoma classified as benign with 97.7% confidence by a single model. In a deep ensemble of five models, four predicted benign while one correctly identified it as malignant. The resulting disagreement produces higher ensemble entropy, flagging this case for human review.],
    [A melanoma classified as benign with 97.7% confidence by a single model.],
  ),
) <fig:false-negative>

== Prior Work

Models need a way to signal when their predictions are unreliable. Selective prediction provides one: a model can abstain from classifying an input when its uncertainty exceeds a threshold, deferring the case to a human expert instead @geifmanSelectiveClassificationDeep2017. The central question is how well each method's uncertainty estimates separate reliable predictions from unreliable ones. Risk-coverage analysis, explained in the Theoretical Background, provides the evaluation framework for this trade-off.

M. Abdar et al. @abdarUncertaintyQuantificationSkin2021 compared MC Dropout, Ensemble MC Dropout, and Deep Ensembles using a three-way decision framework on two skin cancer datasets, reporting performance at different referral rates. On ISIC 2018 and 2019 data, Monte Carlo sampling was shown to identify difficult cases and out-of-distribution samples @combaliaUncertaintyEstimationDeep2020. Two further studies focused on different method combinations: J. Fayyad et al. @fayyadEmpiricalValidationConformal2024 compared conformal prediction, MC Dropout, and evidential deep learning on medical imaging datasets including HAM10000, while P. Tabarisaadi et al. @tabarisaadiUncertaintyAwareSkinCancer2022 evaluated MC Dropout, Bayesian Ensembling, and a spectral-normalized Gaussian process for binary skin cancer detection.

Selective prediction has also received attention. Accuracy-rejection curves in @combaliaUncertaintyEstimationDeep2020 showed improved performance when the most uncertain samples were excluded. J. Carse et al. @carseRobustSelectiveClassification2021 proposed a cost-sensitive selective classifier for skin lesions on ISIC 2019, and a Bayesian referral workflow by A. Mobiny et al. @mobinyRiskAwareMachineLearning2019 reached almost 90% accuracy while sending 35% of cases to physicians.

These studies confirm that UQ methods can flag unreliable predictions in dermatological classification. However, each evaluates at most three methods, typically from the same family (e.g., variants of MC Dropout or ensemble approaches), and none compare methods from different UQ families on a shared architecture. Selective prediction has been applied to skin lesions, but risk-coverage trade-offs have not been compared across structurally different UQ methods. Existing work on demographic fairness in UQ is also limited to single methods @zouReviewUncertaintyEstimation2023, with no comparison of how different methods behave across Fitzpatrick skin types.

#pagebreak()

== Research Question

This thesis investigates the following research question:

#block(
  fill: rgb("#fbf9f2"),
  inset: 1em,
  radius: 4pt,
  [
    *Research Question:* Which uncertainty quantification techniques are most effective for improving the reliability of deep learning-based skin lesion classification?
  ],
)

Here, reliability covers predictive accuracy, calibration of confidence estimates, and the ability to identify cases where the model should defer to a human expert. This primary question is broken into three subquestions:

#enum(
  numbering: "A.",
  tight: false,
  [How do the UQ methods compare in terms of predictive performance, calibration, and robustness?],
  [How do input characteristics (e.g., lesion type, class imbalance, skin tone) affect the model's uncertainty?],
  [How do different UQ methods handle the most difficult samples?],
)

== Approach and Contributions

Researchers have proposed many methods for quantifying uncertainty in neural networks, and recent surveys organize these into distinct families: Bayesian approaches, ensemble methods, and single deterministic techniques @gawlikowskiSurveyUncertaintyDeep2023 @abdarReviewUncertaintyQuantification2021. The Bayesian approach treats network weights as probability distributions rather than fixed values, so that each prediction reflects uncertainty about the model's own parameters @galUncertaintyDeepLearning.

Exact Bayesian inference is too expensive for networks with millions of parameters. Practical methods approximate it in different ways: some run the network multiple times with randomized perturbations (such as randomly disabling neurons or sampling from weight distributions), others train independent model ensembles, and a third category uses architectural modifications that extract uncertainty from a single forward pass.

This thesis compares five methods selected to span this range of families. Three are Bayesian approximations: MC Dropout, DropConnect, and Flipout. Each introduces randomness at a different level of the network. MC Dropout randomly disables neuron outputs, DropConnect randomly zeroes individual connections between neurons, and Flipout samples from learned weight distributions. All three produce varied predictions across multiple stochastic forward passes.

The two non-Bayesian methods work differently. Deep Ensembles trains multiple independent networks and derives uncertainty from their disagreement, without any probabilistic treatment of individual weights. Deterministic Uncertainty Quantification (DUQ) requires only a single forward pass, estimating uncertainty by measuring how far an input's learned representation falls from class-specific reference points in a feature space @van2020uncertainty.

All five use the same EfficientNet-B3 backbone, a convolutional architecture that came out of hyperparameter search as the best trade-off between accuracy and speed. They are trained on a single dermatological dataset of over 90,000 dermoscopic and clinical images drawn from multiple institutional sources in the ISIC Archive. The dataset supports both binary (benign vs. malignant) and five-class diagnostic classification, and reflects the class imbalance typical of dermatological data, with benign lesions far outnumbering malignant ones. Using a shared dataset and architecture ensures that observed differences reflect the UQ method rather than confounding factors.

The main contribution is a systematic comparison of these five methods under identical conditions, covering predictive performance, calibration, and risk-coverage trade-offs. Beyond that, we look at how patient metadata (Fitzpatrick skin type, data source) affects uncertainty estimates, and whether the methods agree on which samples are hardest to classify.

== Thesis Outline

The remainder of this thesis is structured as follows:

*Chapter 2: Theoretical Background* introduces skin lesion classification and dermoscopy, then covers uncertainty quantification in deep learning, including the distinction between aleatoric and epistemic uncertainty and the specific methods evaluated in this study.

*Chapter 3: Experimental Setup* describes the dataset compilation and preprocessing pipeline, the network architecture, training procedure, and method-specific model configurations.

*Chapter 4: Results* compares model performance across uncertainty methods, analyzes how input characteristics such as skin type and lesion type affect uncertainty, and examines model behavior on clinically difficult samples.

*Chapter 5: Discussion & Conclusion* summarizes the findings, answers the research questions, discusses limitations, and outlines directions for future work.

= Theoretical Background

The previous chapter motivated why uncertainty quantification matters for skin lesion classification. This chapter defines the classification task, describes each UQ method evaluated in this thesis, and introduces the metrics used to compare them.

== Skin Lesion

Skin lesions are abnormal growths or areas on the skin that can result from various causes, including infections, allergies, and diseases such as skin cancer. They are broadly categorised into benign (non-cancerous) and malignant (cancerous) types. Common benign lesions include nevi (moles) and seborrheic keratoses, whereas malignant lesions include basal cell carcinoma, squamous cell carcinoma, and melanoma @cassidyAnalysisISICImage2022.

Automated skin lesion classification typically involves assigning lesions toclinically relevant categories, such as benign, malignant, or "indeterminate" lesions (those requiring further histopathological#numbered_margin_note[Histopathology is the microscopic examination of tissue samples, e.g. biopsies or surgical specimens, examining structural and cellular changes] evaluation). The number of classes depends on the dataset and clinical application. While many studies focus on binary benign/malignant classification, multi-class models with three to nine classes have also been studied @cassidyAnalysisISICImage2022. Benign and malignant lesions can look very similar, and there is substantial variation within each diagnostic category. Combined with the class imbalance described in the introduction, these factors make automated classification difficult @esteva2017dermatologist @iqbalAutomatedMulticlassClassification2021.

=== Dermoscopy

Dermoscopy is a non-invasive imaging technique used to examine skin lesions in detail. A dermatoscope provides magnification under controlled illumination, revealing surface and subsurface structures down to the papillary dermis#numbered_margin_note[The thin top layer of the dermis (the inner layer of the skin) that contains the capillary loops and nerve endings] that are not visible to the naked eye @baldiAutomatedDermoscopyImage2010. Clinical photographs, by contrast, vary in framing, lighting, and scale depending on the camera and setting. This difference carries over to automated analysis: deep learning classifiers achieve significantly higher accuracy on dermoscopic images than on clinical photographs @dascaluNonmelanomaSkinCancer2022.

#let imaging_type_samples_csv = csv(
  "../Notebooks/results/imaging_type_samples/sampled_images.csv",
  row-type: dictionary,
)
#let imaging_types = (
  ("dermoscopic", "Dermoscopic"),
  ("clinical: close-up", "Clinical close-up"),
  ("TBP tile: close-up", "TBP tile close-up"),
)

#figure(
  grid(
    columns: 3,
    column-gutter: 3mm,
    row-gutter: 1mm,
    ..imaging_types.map(((key, label)) => {
      let rows = imaging_type_samples_csv.filter(r => r.at("image_type") == key).slice(0, 4)
      stack(
        dir: ttb,
        spacing: 1mm,
        grid(
          columns: 2,
          gutter: 1mm,
          ..rows.map(r => layout(size => box(
            clip: true,
            width: 100%,
            height: size.width,
            align(center + horizon, image(r.at("image_path"), width: 100%)),
          )))
        ),
        text(size: 0.75em)[#label],
      )
    })
  ),
  caption: flex-caption(
    [Comparison of imaging modalities in the ISIC dataset. Dermoscopic images (left) are captured with a dermatoscope, providing consistent magnification and lighting. Clinical close-up photographs (center) show lesions as seen by the naked eye. TBP (total body photography) tiles (right) are cropped from wide-angle full-body images and typically have lower resolution.],
    [Imaging modality comparison.],
  ),
) <imaging_modality_comparison>

=== Fitzpatrick Skin Type Classification

#import "skintypes.typ": skin-type-colors, skin-type-order

#figure(
  {
    grid(
      columns: 6,
      gutter: 0pt,
      ..skin-type-order.map(t => {
        let text-color = if t in ("IV", "V", "VI") { white } else { black }
        box(
          width: 1fr,
          height: 2em,
          fill: skin-type-colors.at(t),
          align(center + horizon, text(fill: text-color, weight: "bold", t)),
        )
      })
    )
    v(2mm)
    grid(
      columns: 6,
      gutter: 2mm,
      ..skin-type-order.map(t => box(
        clip: true,
        radius: 2pt,
        image("images/fitzpatrick_samples/type_" + t + ".jpg", width: 100%),
      ))
    )
  },
  caption: flex-caption(
    [The six Fitzpatrick skin types with sample dermoscopic images from the dataset. Skin tone ranges from type I (very fair) to type VI (very dark).],
    [Fitzpatrick skin types with sample images.],
  ),
) <fitzpatrick_samples>

The Fitzpatrick skin type classification is a widely used dermatological scale that categorises skin tone into six types, ranging from type I (very fair) to type VI (very dark), based on the skin's response to UV exposure @fitzpatrickValidityPracticalitySunReactive1988. This classification is relevant to skin lesion analysis because skin tone can affect the visual appearance of lesions and the contrast between the lesion and surrounding skin, and models trained predominantly on lighter skin tones show reduced performance on darker skin @shahImpactSkinTone2025 @daneshjouDisparitiesDermatologyAI2022.

#pagebreak()

== Uncertainty Quantification

The introduction established that standard neural network confidence scores are unreliable, which is why dedicated uncertainty quantification methods are needed. These methods fall into two broad categories. Bayesian methods treat model parameters as distributions and use probabilistic inference, while non-Bayesian methods modify the architecture or inference process without explicitly modelling parameter distributions @gawlikowskiSurveyUncertaintyDeep2023.

J. Gawlikowski et al. @gawlikowskiSurveyUncertaintyDeep2023 refine this into four families: Bayesian neural networks, ensemble methods, test-time data augmentation, and single deterministic methods. This thesis evaluates five of these methods. Three are Bayesian approximations: MC Dropout, DropConnect, and Flipout. The fourth is Deep Ensembles, an ensemble method. The fifth is DUQ, a single deterministic method. All five are compatible with convolutional image classification backbones.

The Bayesian methods are based on Bayesian probability theory. A true Bayesian approach starts with a prior distribution $p(theta)$ that encodes initial assumptions about the model parameters.#numbered_margin_note[$theta$ denotes the model parameters (weights and biases) and $D$ the observed training data.] After observing training data $D$, we update this to the posterior distribution $p(theta|D)$, which captures what the data tells us about plausible parameter values. Computing this posterior exactly requires integrating over all possible parameter configurations, which is infeasible for networks with millions of parameters.

Due to this intractability, exact Bayesian methods are rarely used in practice, and approximations are needed instead @abdarReviewUncertaintyQuantification2021. The three Bayesian approximations evaluated in this thesis (MC Dropout, DropConnect, and Flipout) all work by running multiple stochastic forward passes through the network. Because each pass randomly perturbs the model's weights or activations, it samples from an (implicit) distribution over parameters. Collecting predictions across many passes gives an estimate of predictive uncertainty without needing exact inference.

The two non-Bayesian methods take different approaches. Deep Ensembles trains multiple copies of the same architecture from different random initializations, so that each converges to a different solution. This thesis uses five members, which makes it the most expensive method since each must be trained and stored separately. Uncertainty is then estimated from the disagreement across these independent predictions. DUQ works differently. It replaces the softmax classification layer with a distance-based system that measures how close an input's learned features lie to class-specific reference points. A single forward pass is sufficient, making it the computationally cheapest method in this comparison.

#figure(
  box(fill: rgb("#fbf9f2"), inset: (x: 16pt, y: 16pt), width: 100%, {
    let det-color = rgb("#2d1b69")
    let bayes-color = rgb("#e8683f")

    // Legend
    align(left + bottom, grid(
      columns: (auto, auto),
      column-gutter: 12pt,
      box(inset: (left: 16pt))[
        #set text(size: 0.85em)
        #grid(
          columns: (24pt, auto),
          row-gutter: 6pt,
          align(center + horizon, circle(radius: 3pt, fill: det-color)),
          align(left + horizon)[Deterministic neural network],

          align(center + horizon, box(width: 22pt, height: 8pt, {
            place(horizon + center, rect(width: 21pt, height: 7pt, fill: bayes-color.lighten(60%), radius: 4pt))
            place(horizon + center, dx: 0pt, circle(radius: 3pt, fill: det-color))
          })),
          align(left + horizon)[Bayesian neural network],

          align(center + horizon, box(width: 22pt, height: 8pt, {
            place(horizon + left, dx: 1pt, circle(radius: 3pt, fill: det-color))
            place(horizon + center, circle(radius: 3pt, fill: det-color))
            place(horizon + right, dx: -1pt, circle(radius: 3pt, fill: det-color))
          })),
          align(left + horizon)[Ensemble of neural networks],
        )
      ],
      box(inset: (left: 53pt))[
        #set text(size: 0.85em)
        #grid(
          columns: (35pt, auto),
          row-gutter: 6pt,
          align(center + horizon, line(length: 30pt, stroke: 1pt)), align(right + horizon)[Training],
          align(center + horizon, line(length: 30pt, stroke: (thickness: 1pt, dash: "dotted"))),
          align(right + horizon)[Inference],
        )
      ],
    ))
    v(6pt)

    // Loss landscape data
    let n = 150
    let xs = lq.linspace(0.3, 10.8, num: n)
    let train-fn = x => 1.8 + 1.2 * calc.cos(1.7 * x * 1rad)
    let infer-fn = x => 1.6 + 0.9 * calc.cos((1.7 * x + 0.3) * 1rad) + 0.3 * calc.sin(0.85 * x * 1rad)
    let training = xs.map(train-fn)
    let inference = xs.map(infer-fn)

    // Three local minima of training loss
    let m1 = calc.pi / 1.7
    let m2 = 3 * calc.pi / 1.7
    let m3 = 5 * calc.pi / 1.7
    let minima-x = (m1, m2, m3)
    let minima-y = minima-x.map(train-fn)

    // Bayesian bands
    let bump-w = 1.2
    let bump-a = 0.35
    let bands = ()
    for m in minima-x {
      let idx = range(n).filter(i => calc.abs(xs.at(i) - m) < bump-w)
      if idx.len() > 2 {
        let local-x = idx.map(i => xs.at(i))
        let local-train = idx.map(i => training.at(i))
        let local-env = local-x.map(x => bump-a * (0.5 + 0.5 * calc.cos(calc.pi * (x - m) / bump-w * 1rad)))
        let upper = range(local-x.len()).map(i => local-train.at(i) + local-env.at(i))
        let lower = range(local-x.len()).map(i => local-train.at(i) - local-env.at(i))
        bands.push(lq.fill-between(
          local-x,
          upper,
          y2: lower,
          fill: bayes-color.lighten(65%),
          stroke: bayes-color.lighten(20%) + 0.7pt,
          smooth: true,
          z-index: 1,
        ))
      }
    }

    lq.diagram(
      width: 100%,
      height: 45mm,
      xlim: (0, 11),
      ylim: (0, 3.5),
      xaxis: (ticks: none),
      yaxis: (ticks: none),
      xlabel: [Space of model parameters],
      ylabel: [Loss value],
      grid: none,
      legend: none,

      ..bands,
      lq.plot(xs, training, stroke: black + 1.2pt, smooth: true, mark: none),
      lq.plot(xs, inference, stroke: (paint: black, thickness: 1pt, dash: "dotted"), smooth: true, mark: none),
      lq.scatter(minima-x, minima-y, color: det-color, size: (80, 80, 80), z-index: 3),
      lq.place(m1, minima-y.at(0) - 0.25)[$theta_1^*$],
      lq.place(m2, minima-y.at(1) - 0.25)[$theta_2^*$],
      lq.place(m3, minima-y.at(2) - 0.25)[$theta_3^*$],
    )
  }),
  caption: flex-caption(
    [Loss landscape illustrating three approaches to neural network training and inference. A deterministic network converges to a single point estimate $theta_i^*$ in parameter space. Bayesian approaches maintain a distribution over parameters around each optimum (shaded regions). Deep Ensembles train multiple independent networks, each converging to different optima. DUQ is not shown because it estimates uncertainty in feature space rather than weight space. Adapted from J. Gawlikowski et al. @gawlikowskiSurveyUncertaintyDeep2023.],
    [Loss landscape: deterministic, Bayesian, and ensemble approaches.],
  ),
) <loss_landscape>

=== Monte Carlo Dropout <mc_dropout_section>

#margin_figure(
  box(fill: rgb("#fbf9f2"), inset: (x: 0pt, y: 16pt), width: 95%, diagram(spacing: (1cm, 1cm), {
    let layer_spacing = 1.8
    let node_spacing = 0.8

    // Input layer
    node((0, 0), circle(fill: default-colors.at(6), radius: 0.3cm)[#text(white, size: 8pt)[I₁]], name: <i1>)
    node((0, node_spacing), circle(fill: default-colors.at(6), radius: 0.3cm)[#text(white, size: 8pt)[I₂]], name: <i2>)
    node(
      (0, 2 * node_spacing),
      circle(fill: default-colors.at(6), radius: 0.3cm)[#text(white, size: 8pt)[I₃]],
      name: <i3>,
    )

    // Column labels (below)
    node((0, -0.7), [*Input*])

    // Hidden Dropout layer. H2 and H4 dropped out.
    node(
      (layer_spacing, -0.5 * node_spacing),
      circle(fill: default-colors.at(5), radius: 0.3cm)[#text(white, size: 8pt)[H₁]],
      name: <h1>,
    )
    node(
      (layer_spacing, 0.5 * node_spacing),
      circle(fill: default-colors.at(5).transparentize(50%), radius: 0.3cm)[#text(
        white.transparentize(50%),
        size: 8pt,
      )[H₂]],
      name: <h2>,
    ) // Dropped out
    node(
      (layer_spacing, 1.5 * node_spacing),
      circle(fill: default-colors.at(5), radius: 0.3cm)[#text(white, size: 8pt)[H₃]],
      name: <h3>,
    )
    node(
      (layer_spacing, 2.5 * node_spacing),
      circle(fill: default-colors.at(5).transparentize(50%), radius: 0.3cm)[#text(
        white.transparentize(50%),
        size: 8pt,
      )[H₄]],
      name: <h4>,
    ) // Dropped out

    node((layer_spacing, -0.7), [*Dropout*])

    // Output layer, 3 nodes for different classes
    node(
      (2 * layer_spacing, 0),
      circle(fill: default-colors.at(1), radius: 0.3cm)[#text(white, size: 8pt)[M]],
      name: <o1>,
    )
    node(
      (2 * layer_spacing, node_spacing),
      circle(fill: default-colors.at(0), radius: 0.3cm)[#text(white, size: 8pt)[B]],
      name: <o2>,
    )
    node(
      (2 * layer_spacing, 2 * node_spacing),
      circle(fill: default-colors.at(2), radius: 0.3cm)[#text(white, size: 8pt)[I]],
      name: <o3>,
    )

    node((2 * layer_spacing, -0.7), [*Output*])

    // Connections from input to hidden layer, faded for dropped neurons
    edge(<i1>, <h1>, "-|>", stroke: 0.8pt)
    edge(<i1>, <h2>, "-|>", stroke: 0.8pt + black.transparentize(80%))
    edge(<i1>, <h3>, "-|>", stroke: 0.8pt)
    edge(<i1>, <h4>, "-|>", stroke: 0.8pt + black.transparentize(80%))

    edge(<i2>, <h1>, "-|>", stroke: 0.8pt)
    edge(<i2>, <h2>, "-|>", stroke: 0.8pt + black.transparentize(80%))
    edge(<i2>, <h3>, "-|>", stroke: 0.8pt)
    edge(<i2>, <h4>, "-|>", stroke: 0.8pt + black.transparentize(80%))

    edge(<i3>, <h1>, "-|>", stroke: 0.8pt)
    edge(<i3>, <h2>, "-|>", stroke: 0.8pt + black.transparentize(80%))
    edge(<i3>, <h3>, "-|>", stroke: 0.8pt)
    edge(<i3>, <h4>, "-|>", stroke: 0.8pt + black.transparentize(80%))

    // Connections from hidden to output, all normal since the output layer is deterministic
    edge(<h1>, <o1>, "-|>", stroke: 0.8pt)
    edge(<h1>, <o2>, "-|>", stroke: 0.8pt)
    edge(<h1>, <o3>, "-|>", stroke: 0.8pt)

    edge(<h2>, <o1>, "-|>", stroke: 0.8pt + black.transparentize(80%))
    edge(<h2>, <o2>, "-|>", stroke: 0.8pt + black.transparentize(80%))
    edge(<h2>, <o3>, "-|>", stroke: 0.8pt + black.transparentize(80%))

    edge(<h3>, <o1>, "-|>", stroke: 0.8pt)
    edge(<h3>, <o2>, "-|>", stroke: 0.8pt)
    edge(<h3>, <o3>, "-|>", stroke: 0.8pt)

    edge(<h4>, <o1>, "-|>", stroke: 0.8pt + black.transparentize(80%))
    edge(<h4>, <o2>, "-|>", stroke: 0.8pt + black.transparentize(80%))
    edge(<h4>, <o3>, "-|>", stroke: 0.8pt + black.transparentize(80%))
  })),
  caption: flex-caption(
    [Monte Carlo Dropout architecture showing randomly dropped neurons (semi-transparent) in the stochastic hidden layer during inference.],
    [Monte Carlo Dropout architecture.],
  ),
) <mc_dropout_diagram>


Dropout is a technique often used for regularisation @srivastavaDropoutSimpleWay, where during training, random neuron activations are set to zero with a certain probability. This prevents the model from becoming too reliant on any single neuron, which helps the model generalize better. Monte Carlo#numbered_margin_note[According to Wikipedia, without citation: _"The name comes from the Monte Carlo Casino in Monaco, where the primary developer of the method, mathematician Stanisław Ulam, was inspired by his uncle's gambling habits."_] (MC) Dropout for uncertainty quantification extends this idea by using dropout at inference time as well, allowing the model to make multiple stochastic forward passes through the network @pmlr-v48-gal16. Y. Gal and Z. Ghahramani @pmlr-v48-gal16 showed that each dropout mask defines a different sub-network, and that running many such sub-networks is mathematically equivalent to sampling from an approximate posterior over the model's weights.

Because major deep learning frameworks already include built-in dropout layers, MC Dropout requires minimal implementation effort. It can be applied to existing models with minimal changes, or no changes at all if dropout layers are already present.

=== Monte Carlo DropConnect <dropconnect_section>

#margin_figure(
  box(fill: rgb("#fbf9f2"), inset: (x: 0pt, y: 16pt), width: 95%, diagram(spacing: (1cm, 1cm), {
    let layer_spacing = 1.8
    let node_spacing = 0.8

    // Input layer, all nodes active
    node((0, 0), circle(fill: default-colors.at(6), radius: 0.3cm)[#text(white, size: 8pt)[I₁]], name: <i1>)
    node((0, node_spacing), circle(fill: default-colors.at(6), radius: 0.3cm)[#text(white, size: 8pt)[I₂]], name: <i2>)
    node(
      (0, 2 * node_spacing),
      circle(fill: default-colors.at(6), radius: 0.3cm)[#text(white, size: 8pt)[I₃]],
      name: <i3>,
    )

    // Column labels (below)
    node((0, -0.7), [*Input*])

    // Hidden DropConnect layer. All nodes active, some connections dropped.
    node(
      (layer_spacing, -0.5 * node_spacing),
      circle(fill: default-colors.at(5), radius: 0.3cm)[#text(white, size: 8pt)[H₁]],
      name: <h1>,
    )
    node(
      (layer_spacing, 0.5 * node_spacing),
      circle(fill: default-colors.at(5), radius: 0.3cm)[#text(white, size: 8pt)[H₂]],
      name: <h2>,
    )
    node(
      (layer_spacing, 1.5 * node_spacing),
      circle(fill: default-colors.at(5), radius: 0.3cm)[#text(white, size: 8pt)[H₃]],
      name: <h3>,
    )
    node(
      (layer_spacing, 2.5 * node_spacing),
      circle(fill: default-colors.at(5), radius: 0.3cm)[#text(white, size: 8pt)[H₄]],
      name: <h4>,
    )

    node((layer_spacing, -0.7), [*DropConnect*])

    // Output layer, 3 nodes for different classes
    node(
      (2 * layer_spacing, 0),
      circle(fill: default-colors.at(1), radius: 0.3cm)[#text(white, size: 8pt)[M]],
      name: <o1>,
    )
    node(
      (2 * layer_spacing, node_spacing),
      circle(fill: default-colors.at(0), radius: 0.3cm)[#text(white, size: 8pt)[B]],
      name: <o2>,
    )
    node(
      (2 * layer_spacing, 2 * node_spacing),
      circle(fill: default-colors.at(2), radius: 0.3cm)[#text(white, size: 8pt)[I]],
      name: <o3>,
    )

    node((2 * layer_spacing, -0.7), [*Output*])

    // Connections from input to hidden layer. Some connections dropped (transparent).
    edge(<i1>, <h1>, "-|>", stroke: 0.8pt)
    edge(<i1>, <h2>, "-|>", stroke: 0.8pt + black.transparentize(80%)) // Dropped
    edge(<i1>, <h3>, "-|>", stroke: 0.8pt)
    edge(<i1>, <h4>, "-|>", stroke: 0.8pt)

    edge(<i2>, <h1>, "-|>", stroke: 0.8pt + black.transparentize(80%)) // Dropped
    edge(<i2>, <h2>, "-|>", stroke: 0.8pt)
    edge(<i2>, <h3>, "-|>", stroke: 0.8pt + black.transparentize(80%)) // Dropped
    edge(<i2>, <h4>, "-|>", stroke: 0.8pt)

    edge(<i3>, <h1>, "-|>", stroke: 0.8pt)
    edge(<i3>, <h2>, "-|>", stroke: 0.8pt)
    edge(<i3>, <h3>, "-|>", stroke: 0.8pt)
    edge(<i3>, <h4>, "-|>", stroke: 0.8pt + black.transparentize(80%)) // Dropped

    // Connections from hidden to output, all normal since the output layer is deterministic
    edge(<h1>, <o1>, "-|>", stroke: 0.8pt)
    edge(<h1>, <o2>, "-|>", stroke: 0.8pt)
    edge(<h1>, <o3>, "-|>", stroke: 0.8pt)

    edge(<h2>, <o1>, "-|>", stroke: 0.8pt)
    edge(<h2>, <o2>, "-|>", stroke: 0.8pt)
    edge(<h2>, <o3>, "-|>", stroke: 0.8pt)

    edge(<h3>, <o1>, "-|>", stroke: 0.8pt)
    edge(<h3>, <o2>, "-|>", stroke: 0.8pt)
    edge(<h3>, <o3>, "-|>", stroke: 0.8pt)

    edge(<h4>, <o1>, "-|>", stroke: 0.8pt)
    edge(<h4>, <o2>, "-|>", stroke: 0.8pt)
    edge(<h4>, <o3>, "-|>", stroke: 0.8pt)
  })),
  caption: flex-caption(
    [Monte Carlo DropConnect architecture showing randomly dropped connections (semi-transparent) in the stochastic hidden layer while keeping all neurons active.],
    [Monte Carlo DropConnect architecture.],
  ),
) <mc_dropconnect_diagram>


MC DropConnect is a technique that was proposed as a generalisation of Dropout. Instead of randomly dropping out neurons, it randomly drops out the weights, the connections between neurons @wanRegularizationNeuralNetworks2013. Like MC Dropout, DropConnect can also be used to model uncertainty @mobinyDropConnectEffectiveModeling2021.

=== Flipout <flipout_section>

#margin_figure(
  box(fill: rgb("#fbf9f2"), inset: (x: 0pt, y: 16pt), width: 95%, {
    // Helper: small Gaussian bell curve symbol with white background and ± prefix
    let bell(w: 13pt, h: 8pt, clr: black) = box(baseline: 40%, fill: rgb("#fbf9f2"), outset: 1.5pt, radius: 1.5pt, {
      text(size: 12pt)[±]
      box(width: w, height: h, clip: false, {
        place(curve(
          curve.move((0pt, h - 1pt)),
          curve.cubic((w * 0.15, h), (w * 0.3, 1pt), (w * 0.5, 1pt)),
          curve.cubic((w * 0.7, 1pt), (w * 0.85, h - 1pt), (w, h - 1pt)),
          stroke: 1pt + clr,
        ))
      })
    })

    diagram(spacing: (1cm, 1cm), {
      let layer_spacing = 1.8
      let node_spacing = 0.8

      // Input layer, all nodes active
      node((0, 0), circle(fill: default-colors.at(6), radius: 0.3cm)[#text(white, size: 8pt)[I₁]], name: <i1>)
      node(
        (0, node_spacing),
        circle(fill: default-colors.at(6), radius: 0.3cm)[#text(white, size: 8pt)[I₂]],
        name: <i2>,
      )
      node(
        (0, 2 * node_spacing),
        circle(fill: default-colors.at(6), radius: 0.3cm)[#text(white, size: 8pt)[I₃]],
        name: <i3>,
      )

      // Column labels (below)
      node((0, -0.7), [*Input*])

      // Hidden Flipout layer. All nodes active, weights are distributions.
      node(
        (layer_spacing, -0.5 * node_spacing),
        circle(fill: default-colors.at(5), radius: 0.3cm)[#text(white, size: 8pt)[H₁]],
        name: <h1>,
      )
      node(
        (layer_spacing, 0.5 * node_spacing),
        circle(fill: default-colors.at(5), radius: 0.3cm)[#text(white, size: 8pt)[H₂]],
        name: <h2>,
      )
      node(
        (layer_spacing, 1.5 * node_spacing),
        circle(fill: default-colors.at(5), radius: 0.3cm)[#text(white, size: 8pt)[H₃]],
        name: <h3>,
      )
      node(
        (layer_spacing, 2.5 * node_spacing),
        circle(fill: default-colors.at(5), radius: 0.3cm)[#text(white, size: 8pt)[H₄]],
        name: <h4>,
      )

      node((layer_spacing, -0.7), [*Flipout*])

      // Output layer, 3 nodes for different classes
      node(
        (2 * layer_spacing, 0),
        circle(fill: default-colors.at(1), radius: 0.3cm)[#text(white, size: 8pt)[M]],
        name: <o1>,
      )
      node(
        (2 * layer_spacing, node_spacing),
        circle(fill: default-colors.at(0), radius: 0.3cm)[#text(white, size: 8pt)[B]],
        name: <o2>,
      )
      node(
        (2 * layer_spacing, 2 * node_spacing),
        circle(fill: default-colors.at(2), radius: 0.3cm)[#text(white, size: 8pt)[I]],
        name: <o3>,
      )

      node((2 * layer_spacing, -0.7), [*Output*])

      // Connections from input to hidden layer, varying stroke widths represent sampled weights
      edge(<i1>, <h1>, "-|>", stroke: 1.4pt)
      edge(<i1>, <h2>, "-|>", stroke: 0.4pt)
      edge(<i1>, <h3>, "-|>", stroke: 0.8pt)
      edge(<i1>, <h4>, "-|>", stroke: 1.0pt)

      edge(<i2>, <h1>, "-|>", stroke: 0.6pt)
      edge(<i2>, <h2>, "-|>", stroke: 1.2pt)
      edge(<i2>, <h3>, "-|>", stroke: 0.4pt)
      edge(<i2>, <h4>, "-|>", stroke: 1.6pt)

      edge(<i3>, <h1>, "-|>", stroke: 0.8pt)
      edge(<i3>, <h2>, "-|>", stroke: 1.0pt)
      edge(<i3>, <h3>, "-|>", stroke: 1.4pt)
      edge(<i3>, <h4>, "-|>", stroke: 0.5pt)

      // Bell curve decorations on select connections, placed at the midpoint between input and hidden
      node((layer_spacing * 0.5, -0.25 * node_spacing), bell())
      node((layer_spacing * 0.5, 0.75 * node_spacing), bell())
      node((layer_spacing * 0.5, 1.75 * node_spacing), bell())
      node((layer_spacing * 0.5, 2.25 * node_spacing), bell())

      // Connections from hidden to output, all normal since the output layer is deterministic
      edge(<h1>, <o1>, "-|>", stroke: 0.8pt)
      edge(<h1>, <o2>, "-|>", stroke: 0.8pt)
      edge(<h1>, <o3>, "-|>", stroke: 0.8pt)

      edge(<h2>, <o1>, "-|>", stroke: 0.8pt)
      edge(<h2>, <o2>, "-|>", stroke: 0.8pt)
      edge(<h2>, <o3>, "-|>", stroke: 0.8pt)

      edge(<h3>, <o1>, "-|>", stroke: 0.8pt)
      edge(<h3>, <o2>, "-|>", stroke: 0.8pt)
      edge(<h3>, <o3>, "-|>", stroke: 0.8pt)

      edge(<h4>, <o1>, "-|>", stroke: 0.8pt)
      edge(<h4>, <o2>, "-|>", stroke: 0.8pt)
      edge(<h4>, <o3>, "-|>", stroke: 0.8pt)
    })
  }),
  caption: flex-caption(
    [Flipout architecture showing Bayesian weight distributions (bell curves) in the stochastic hidden layer. Varying connection widths represent different sampled weight values.],
    [Flipout architecture.],
  ),
) <flipout_diagram>

MC Dropout and DropConnect approximate Bayesian inference by adding randomness to a standard network architecture. Flipout is more explicit in modeling Bayesian inference. It is used in variational Bayesian neural networks, where each weight is treated as a random variable with a learned distribution. During training and inference, weights are sampled from these learned Gaussian distributions rather than from a fixed architecture with random masking. Flipout is the specific technique that makes this sampling efficient across a mini-batch @wenFlipoutEfficientPseudoIndependent2018.

Sampling a separate noise matrix for each input would give independent perturbations, but this is too computationally expensive. The way to get around this is by reusing a single noise matrix across the whole mini-batch, but this causes correlated gradients, preventing variance reduction as batch size increases @wenFlipoutEfficientPseudoIndependent2018. Without variance reduction, high gradient variance leads to unstable updates and slow convergence.

// Personal note: Normally, the point of using a mini-batch is that averaging gradients across N examples reduces variance by a factor of 1/N. But this only works if the gradients are uncorrelated. When every example in the batch shares the same weight perturbation, all gradients carry the same noise component. Averaging N copies of the same noise doesn't cancel it out. The noise floor stays constant regardless of batch size.

Flipout solves this by reusing one shared noise matrix but applying random sign flips to it for each input. The result is pseudo-independent perturbations where each input sees noise drawn from the correct distribution, but with decorrelated gradients. This means the gradient variance scales properly @wenFlipoutEfficientPseudoIndependent2018.

Concretely, each weight $w_(i j)$ in a Flipout layer is parameterised by a learnable mean $mu_(i j)$ and standard deviation $sigma_(i j)$. During each forward pass, weights are sampled as $w = mu + sigma dot.o epsilon$, where $epsilon tilde cal(N)(0, I)$. Expressing the sample this way (the reparameterisation trick) separates the learned parameters $mu$ and $sigma$ from the random noise $epsilon$, which allows gradients to flow through the sampling step during training. To apply the per-sample sign flips, two Rademacher vectors $r_"in"$ and $r_"out"$ (random $plus.minus 1$ vectors) are drawn independently for each sample. The layer output is then:

$ y = x W_mu + ((x dot.o r_"in") Delta W) dot.o r_"out" + b $

where $x$ is a single input vector, $Delta W = sigma dot.o epsilon$ is the shared perturbation, $r_"in"$ and $r_"out"$ are vectors matching the input and output dimensions respectively, and $dot.o$ denotes element-wise multiplication @wenFlipoutEfficientPseudoIndependent2018.

Training a Flipout layer means learning $mu$ and $sigma$ for each weight by maximising the evidence lower bound (ELBO) @blundellWeightUncertaintyNeural2015. The ELBO tries to do two things: fit the training data and keep the learned weight distributions close to a prior distribution $p(w)$. KL divergence quantifies how far the learned posterior $q(w | theta)$ has drifted from the prior. Minimising it prevents the distributions from collapsing to point estimates, which would remove the model's ability to express uncertainty. A scalar weight $lambda_"KL"$ controls the trade-off between data fit and prior adherence.

The prior $p(w)$ encodes assumptions about reasonable weight values before any training data is observed. A common choice is the scale mixture prior @blundellWeightUncertaintyNeural2015, which combines two zero-mean Gaussians with different variances: one broad component that permits large weights where the data supports them, and one narrow component that pulls weights toward zero. Both the mixture proportions and component variances are fixed hyperparameters chosen before training.

#pagebreak()

=== Deep Ensembles <deep_ensembles_section>

#margin_figure(
  box(fill: rgb("#fbf9f2"), inset: (x: 0pt, y: 10pt), width: 95%, diagram(spacing: (0.4cm, 0.35cm), {
    // Input image (shared across all models)
    node((-1.5, 1), image("../Datasets/images/ISIC_0002342.jpg", width: 1.0cm), name: <img>)
    node((-1.5, -1.5), [*Input*], name: <input_label>)
    node((0.5, -1.5), [*Model*], name: <predictions_label>)
    node((2.2, -1.5), [*Predictions*], name: <predictions_label>)
    node((4, -1.5), [*Ensemble\ Prediction*], name: <predictions_label>)

    // Three ensemble models, simplified and stacked vertically
    let model_width = 1.3
    let model_height = 1.4

    // Model labels above the model boxes
    node(
      (0.5, 2.8),
      [#text(size: 7pt, weight: "bold", fill: default-colors.at(0))[Model weights $W_3$]],
      name: <label1>,
    )
    node(
      (0.5, 1.4),
      [#text(size: 7pt, weight: "bold", fill: default-colors.at(2))[Model weights $W_2$]],
      name: <label2>,
    )
    node(
      (0.5, 0.0),
      [#text(size: 7pt, weight: "bold", fill: default-colors.at(4))[Model weights $W_1$]],
      name: <label3>,
    )

    // Model 1 with simplified neural network representation
    node(
      (0.5, 2.2),
      diagram(spacing: (0.3cm, 0cm), {
        // Layer boxes
        node((0.5, 0), rect(width: 0.4cm, height: 1.0cm, fill: default-colors.at(0), radius: 2pt), name: <l1>)
        node((1.1, 0), rect(width: 0.4cm, height: 1.0cm, fill: default-colors.at(0), radius: 2pt), name: <l2>)
        node((1.7, 0), rect(width: 0.4cm, height: 1.0cm, fill: default-colors.at(0), radius: 2pt), name: <l3>)
        node((2.3, 0), rect(width: 0.4cm, height: 1.0cm, fill: default-colors.at(0), radius: 2pt), name: <l4>)
      }),
      name: <model1>,
    )

    // Model 2 with simplified neural network representation
    node(
      (0.5, 0.8),
      diagram(spacing: (0.3cm, 0cm), {
        // Layer boxes
        node((0.5, 0), rect(width: 0.4cm, height: 1.0cm, fill: default-colors.at(2), radius: 2pt), name: <l1>)
        node((1.1, 0), rect(width: 0.4cm, height: 1.0cm, fill: default-colors.at(2), radius: 2pt), name: <l2>)
        node((1.7, 0), rect(width: 0.4cm, height: 1.0cm, fill: default-colors.at(2), radius: 2pt), name: <l3>)
        node((2.3, 0), rect(width: 0.4cm, height: 1.0cm, fill: default-colors.at(2), radius: 2pt), name: <l4>)
      }),
      name: <model2>,
    )

    // Model 3 with simplified neural network representation
    node(
      (0.5, -0.6),
      diagram(spacing: (0.3cm, 0cm), {
        // Layer boxes
        node((0.5, 0), rect(width: 0.4cm, height: 1.0cm, fill: default-colors.at(4), radius: 2pt), name: <l1>)
        node((1.1, 0), rect(width: 0.4cm, height: 1.0cm, fill: default-colors.at(4), radius: 2pt), name: <l2>)
        node((1.7, 0), rect(width: 0.4cm, height: 1.0cm, fill: default-colors.at(4), radius: 2pt), name: <l3>)
        node((2.3, 0), rect(width: 0.4cm, height: 1.0cm, fill: default-colors.at(4), radius: 2pt), name: <l4>)
      }),
      name: <model3>,
    )

    // Model 1 predictions
    node((2.2, 2.2), [#text(size: 6pt)[M: 0.65 \ B: 0.25 \ I: 0.10]], name: <pred1_m>)

    // Model 2 predictions
    node((2.2, 0.8), [#text(size: 6pt)[M: 0.70 \ B: 0.20 \ I: 0.10]], name: <pred2_m>)

    // Model 3 predictions
    node((2.2, -0.6), [#text(size: 6pt)[M: 0.75 \ B: 0.15 \ I: 0.10]], name: <pred3_m>)

    // Ensemble prediction box
    node(
      (4.0, 0.8),
      text(size: 6pt)[M: 0.70 \ B: 0.20 \ I: 0.10],
      name: <ensemble_pred>,
    )

    // Arrows from input to models
    edge(<img>, <model1>, "-|>", stroke: 0.8pt, bend: -30deg)
    edge(<img>, <model2>, "-|>", stroke: 0.8pt)
    edge(<img>, <model3>, "-|>", stroke: 0.8pt, bend: 30deg)

    // Arrows from models to individual predictions
    edge(<model1>, <pred1_m>, "-|>", stroke: 0.8pt + default-colors.at(0))
    edge(<model2>, <pred2_m>, "-|>", stroke: 0.8pt + default-colors.at(2))
    edge(<model3>, <pred3_m>, "-|>", stroke: 0.8pt + default-colors.at(4))

    // Arrows from individual predictions to ensemble prediction
    edge(<pred1_m>, <ensemble_pred>, "-|>", stroke: 0.8pt + default-colors.at(0))
    edge(<pred2_m>, <ensemble_pred>, "-|>", stroke: 0.8pt + default-colors.at(2))
    edge(<pred3_m>, <ensemble_pred>, "-|>", stroke: 0.8pt + default-colors.at(4))
  })),
  caption: flex-caption(
    [Deep Ensembles architecture showing multiple independently trained models whose predictions are averaged to provide both final prediction and uncertainty estimates. The class probabilities in each prediction box use the abbreviations M (Malignant), B (Benign), and I (Indeterminate).],
    [Deep Ensembles architecture.],
  ),
) <deep_ensembles_diagram>


Deep Ensembles is a method that uses multiple copies of the same model, each trained with different initializations of the model's weights. For uncertainty quantification, Deep Ensembles use the disagreement between individual models to estimate prediction uncertainty @gawlikowskiSurveyUncertaintyDeep2023.

Each model in the ensemble makes its own prediction for a given input, and the final prediction is obtained by averaging these individual predictions. The uncertainty is then estimated based on the variance or entropy of the predictions across the ensemble members. For this to work, the models need to be different enough from each other, which is usually done through different random initializations and random shuffling of the training data. Different initializations make each model converge to a different local minimum in the loss landscape, so that each model produces different predictions @lakshminarayananSimpleScalablePredictive, @gawlikowskiSurveyUncertaintyDeep2023.

=== Deterministic Uncertainty Quantification <duq_section>

#margin_figure(
  box(fill: rgb("#fbf9f2"), inset: (x: 0pt, y: 16pt), width: 95%, diagram(spacing: (0.4cm, 0cm), {
    // Small image placeholder on the left
    node((-3, 0), image("../Datasets/images/ISIC_0002342.jpg", width: 1.5cm), name: <img>)

    // Central circle with f_0(x)
    node((2, 0), circle(fill: white, stroke: 1pt, radius: 0.6cm)[$f_theta(x)$], name: <f0>)

    // Three circles around the central one at different positions and distances
    node((2.5, 3), circle(fill: rgb("#b91c1c"), radius: 0.4cm)[#text(white)[*$bold(c)_1$*]], name: <e1>)
    node((4.5, 1.5), circle(fill: rgb("#15803d"), radius: 0.4cm)[#text(white)[*$bold(c)_2$*]], name: <e2>)
    node((1.5, -4), circle(fill: rgb("#0369a1"), radius: 0.4cm)[#text(white)[*$bold(c)_3$*]], name: <e3>)

    // Labels next to each circle
    node((2.5, 3.9), [#text(fill: rgb("#b91c1c"))[Malignant]], name: <label1>)
    node((4.5, 2.4), [#text(fill: rgb("#15803d"))[Benign]], name: <label2>)
    node((1.5, -4.9), [#text(fill: rgb("#0369a1"))[Indeterminate]], name: <label3>)

    // Black arrow from image to central circle
    edge(<img>, <f0>, "-|>", stroke: 0.8pt, label: [$f_theta$])

    // |-| lines from central circle to the three circles
    edge(<f0>, <e1>, "|-|", stroke: 0.8pt)
    edge(<f0>, <e2>, "|-|", stroke: 0.8pt)
    edge(<f0>, <e3>, "|-|", stroke: 0.8pt, label: [ } Uncertainty ], label-pos: 10pt, label-side: left)
  })),
  caption: flex-caption(
    [DUQ architecture. The shared backbone $f_theta$ maps an input image to a feature vector, projection kernels then embed it into a low-dimensional space, where distances to the per-class centroids $bold(c)_1$, $bold(c)_2$, $bold(c)_3$ produce the RBF values used for both classification and uncertainty.],
    [DUQ architecture.],
  ),
) <duq_diagram>


Deterministic Uncertainty Quantification (DUQ) is a method that unlike the earlier methods, does not require multiple forward passes to estimate uncertainty. Instead, it uses a single forward pass and applies a deterministic transformation to the output features to estimate uncertainty @van2020uncertainty. DUQ is designed to produce reliable uncertainty estimates on out-of-distribution samples.

DUQ replaces the softmax classification layer (seen as the "Output" layer in @mc_dropout_diagram, @mc_dropconnect_diagram, and @flipout_diagram) with Radial Basis Function (RBF) layers (@duq_diagram). In @duq_diagram, $f_theta$ denotes the shared feature-extractor backbone (the part of the network that precedes the "Output" layer in the earlier diagrams). The RBF distance head, containing the projection kernels and per-class centroids $bold(c)_k$, is what replaces the softmax classifier. An RBF is a function that depends only on the distance from a center point, producing its highest value at the center and decaying smoothly with distance, like a bell curve in multiple dimensions. Each RBF layer contains a set of learnable projection kernels and a trainable "centroid" per class. For example, for each class (e.g. Malignant, Benign), there is a learned reference point in a feature space, the centroid. The kernels project the backbone's feature vector into an embedding space of $d$ dimensions, and the output for each class $k$ is the RBF value:

$
  "RBF"(bold(z), bold(c)_k) = exp(- (1/d dot ||bold(z) - bold(c)_k||^2) / (2 sigma^2))
$

where $bold(z)$ is the projected embedding, $bold(c)_k$ is the learned centroid for class $k$, $d$ is the embedding dimension, and $sigma$ is the length scale, a fixed parameter that controls how quickly the RBF value decays with distance from the centroid. Dividing by $d$ normalizes the squared distance so that the length scale $sigma$ has a consistent meaning regardless of the embedding dimension. This essentially means that the network maps an input image to a point in the low-dimensional embedding space, and then checks: how close is this point to each centroid. Samples close to a class centroid receive high RBF values, while samples far from all centroids receive low values. The further a sample lies from the nearest centroid, the higher its uncertainty @van2020uncertainty.

DUQ requires a gradient penalty: the model's output must change when its input changes. Without this, the model could learn to map everything to the same point in the embedding space, which the authors of DUQ call "feature collapse". If this happens, the model would assign low uncertainty to all samples, including out-of-distribution ones, defeating the purpose of uncertainty quantification.

This is enforced through a gradient penalty applied during training that penalizes deviations from a target norm in either direction @van2020uncertainty:

$
  lambda dot [ ||nabla_bold(x) sum_c K_c||^2_2 - 1]^2
$<duq_penalty_equation>

where $K_c$ is the RBF kernel value for class $c$ and $lambda$ controls the penalty strength. The target norm of 1 ensures the function is Lipschitz-continuous with constant 1, meaning the output changes at most proportionally to changes in the input. Too small a norm means the model is collapsing features, too large means it is amplifying small input differences into large output swings.

== Uncertainty Disentanglement

Uncertainty quantification in machine learning distinguishes between two types of uncertainty @valdenegro-toroDeeperLookAleatoric2022:

*#smallcaps[Aleatoric uncertainty]* captures the irreducible noise in the data that can not be reduced even with more data collection. In dermatological imaging, this includes measurement noise from imaging devices, different lighting conditions, and natural ambiguity in lesion appearance where even expert dermatologists might disagree on diagnosis.

*#smallcaps[Epistemic uncertainty]* represents uncertainty about the model itself. Unlike aleatoric uncertainty, it can be reduced by collecting more training data or improving the model architecture. A model trained primarily on lighter skin tones, for instance, may show high epistemic uncertainty when evaluating lesions on darker skin, because it has not seen enough similar examples. This signals that the training set needs better coverage of those skin tones, making epistemic uncertainty directly actionable @valdenegro-toroDeeperLookAleatoric2022.

=== Total predictive uncertainty

The overall uncertainty is quantified by the entropy of the predictive distribution. Entropy measures the spread of a probability distribution: it is zero when all probability mass is on one class (complete certainty) and maximal when probability is spread equally across all classes (complete uncertainty).

To compute this, we do multiple stochastic forward passes, which gives us a softmax probability vector for each pass. We then average these vectors to get a single mean predictive distribution vector (@mean-predictive-distribution), and compute its entropy (@entropy-of-mean-predctive-distribution). This entropy represents the total uncertainty in the model's predictions @galUncertaintyDeepLearning. Because this decomposition relies on multiple stochastic passes, it applies to MC Dropout, DropConnect, Flipout, and Deep Ensembles, but not to DUQ, which produces uncertainty from a single deterministic pass.

#grid(
  columns: (1fr, 1fr),
  rows: (auto, auto),
  column-gutter: 12pt,
  align: horizon,
  box[
    $
      overline(p)_c = 1 / T sum_(i=1)^T p^i_c
    $<mean-predictive-distribution>
  ],
  box[
    $
      H[overline(p)] = - sum_(c) overline(p)_c * log(overline(p)_c)
    $<entropy-of-mean-predctive-distribution>
  ],
)
#grid(
  columns: (1fr, 1fr),
  rows: (auto, auto),
  column-gutter: 12pt,
  align: center,
  box[
    _Mean predictive distribution_
  ],
  box[
    _Entropy of the mean predictive distribution_
  ],
)

If there is a large difference between the softmax probability vectors from different passes, this distribution becomes "smeared out" and the entropy goes up.

#pagebreak()

=== Aleatoric Uncertainty

Aleatoric uncertainty is estimated by the expected entropy of the predictive distribution @galUncertaintyDeepLearning @kendallWhatUncertaintiesWe2017. We obtain this by doing multiple stochastic forward passes, which again gives us a softmax probability vector for each pass. Now we compute the entropy for each of these vectors (@entropy-of-pass), and then average these entropy values (@mean-of-entropies). This average, the expected entropy, represents the aleatoric uncertainty.

#grid(
  columns: (1fr, 1fr),
  rows: (auto, auto),
  column-gutter: 12pt,
  align: horizon,
  box[
    $
      H[p^i] = -sum_(c) p^i_c * log(p^i_c)
    $<entropy-of-pass>
  ],
  box[
    $
      bb(E)[H(p)] = 1/T sum_(i=1)^T H[p^i]
    $<mean-of-entropies>
  ],
)
#grid(
  columns: (1fr, 1fr),
  rows: (auto, auto),
  column-gutter: 12pt,
  align: center,
  box[
    _Entropy of pass $i$_
  ],
  box[
    _Average of entropies_
  ],
)

If each model is very certain but they disagree with each other, these entropies stay low.

=== Epistemic Uncertainty

Epistemic uncertainty is captured by the mutual information between the prediction $y$ and the model parameters $theta$, conditioned on the input $x$ @galUncertaintyDeepLearning @smithUnderstandingMeasuresUncertainty2018. Mutual information measures how much knowing one variable (here, the model parameters) would reduce uncertainty about another (the prediction). It can be computed as the difference between the total predictive entropy and the expected entropy (aleatoric uncertainty):

$
  I(y; theta | x, cal(D)) = H[overline(p)] - bb(E)[H(p)]
$

When the stochastic forward passes agree, both terms are similar and the mutual information is low, indicating little epistemic uncertainty. When they disagree, the predictive entropy is high but the individual entropies remain low, resulting in high mutual information: the model is uncertain _about its own parameters_, not about inherent noise in the data.

Again, DUQ does not allow for uncertainty decomposition because it produces a single uncertainty score from one forward pass. Throughout this thesis, DUQ's uncertainty is available only as a single total predictive uncertainty score.

#pagebreak()

== Selective Prediction <selective_prediction_background>

In many applications, a model that can decline to classify uncertain inputs is more useful than one that always produces an answer. Selective prediction formalizes this idea: the model uses an uncertainty threshold to decide whether to make a prediction or skip it @geifmanSelectiveClassificationDeep2017. Inputs where the model abstains are deferred to a human expert.

Two quantities describe this trade-off. _Coverage_ is the fraction of samples that the model chooses to classify rather than defer. _Risk_ is the error rate computed only over the samples the model retains. At full coverage the model classifies everything and its risk equals its overall error rate. As coverage decreases, the model defers its most uncertain predictions first, and the risk on the retained set should fall.

A _risk-coverage curve_ plots risk against coverage. To construct it, samples are sorted by ascending uncertainty (most confident first). At each coverage level, the error rate is computed on the retained subset. If a method's uncertainty estimates are well aligned with actual errors, the curve stays low across most coverage levels and only rises as the least confident samples are included. If the estimates are poorly aligned, errors are spread across uncertainty levels and the curve rises earlier.

In medical imaging, deferring uncertain cases to a specialist is a natural workflow @dingUncertaintyAwareTrainingNeural. The cost of errors is often sharply asymmetric. In dermatology, missing a melanoma can delay treatment with life-threatening consequences, while an unnecessary biopsy caused by a false positive is costly but not dangerous @carseRobustSelectiveClassification2021. A cost-sensitive selective classifier can account for this by weighting false negatives more heavily than false positives in the deferral decision.

The risk-coverage curves used in this thesis treat all misclassifications equally, which is standard for comparing UQ methods but does not reflect this clinical asymmetry. The five methods each produce their uncertainty score differently, but all of them can be used as input to the selection function for direct comparison.

#pagebreak()

== Calibration <calibration_background>

A model's predicted confidence should match its actual accuracy: when the model assigns 80% confidence, it should be correct approximately 80% of the time. Expected Calibration Error (ECE) quantifies the discrepancy between predicted confidence and actual accuracy, with lower values indicating better calibration. It is calculated as the weighted average of the absolute difference between confidence and accuracy across several bins of predicted probabilities @pmlr-v70-guo17a.

$
  "ECE" = sum_(m=1)^M abs(B_m) / n * abs("acc"(B_m) - "conf"(B_m))
$

Where $B_m$ is the set of samples whose predicted confidence falls into bin $m$, $n$ is the total number of samples, $"acc"(B_m)$ is the accuracy of samples in bin $m$, and $"conf"(B_m)$ is the average predicted confidence for samples in bin $m$.

Post-hoc calibration techniques such as temperature scaling @pmlr-v70-guo17a can reduce ECE by rescaling the softmax outputs after training. This thesis does not apply post-hoc corrections, because the goal is to compare how well each UQ method produces calibrated uncertainty estimates on its own.

A related metric is the Area Under the Receiver Operating Characteristic curve (AUROC, abbreviated AUC in tables throughout this thesis). ECE measures whether confidence values are well-calibrated in absolute terms. AUC instead measures how well a model's confidence separates correct predictions from incorrect ones. It is computed by treating correctness as a binary label and the model's predicted confidence as the score, then calculating the area under the ROC curve. An AUC of 1.0 means the model always assigns higher confidence to correct predictions than to incorrect ones, 0.5 means confidence carries no discriminative information.

= Experimental Setup

With the methods and evaluation metrics defined, this chapter describes how the comparison was set up in practice. It covers the dataset and its known biases, the shared model architecture, the training procedure, and how each UQ method was implemented on top of it.

== Data

=== Original Dataset

The dataset used in this study is sourced from the International Skin Imaging Collaboration (ISIC) Archive @isic_archive. The ISIC Archive hosts over 500,000 public clinical and dermoscopic images for automated skin lesion analysis @isic_about. ISIC was initially focussed on early melanoma detection, but also contains non-melanoma skin cancer and inflammatory dermatoses images @isic_about.

Because the ISIC Archive uses the same metadata format across institutions, images from multiple sources can be merged into a single dataset with uniform labels and annotations.

#figure(
  full_width[
    #let images = (
      "../Datasets/images/ISIC_0002342.jpg",
      "../Datasets/images/ISIC_0003450.jpg",
      "../Datasets/images/ISIC_0007474.jpg",
      "../Datasets/images/ISIC_0012519.jpg",
      "../Datasets/images/ISIC_4547332.jpg",
      "../Datasets/images/ISIC_0031426.jpg",
      "../Datasets/images/ISIC_0053766.jpg",
      "../Datasets/images/ISIC_4457587.jpg",
      "../Datasets/images/ISIC_5289849.jpg",
      "../Datasets/images/ISIC_6307850.jpg",
      "../Datasets/images/ISIC_6442196.jpg",
      "../Datasets/images/ISIC_7474840.jpg",
      "../Datasets/images/ISIC_7617371.jpg",
      "../Datasets/images/ISIC_7633322.jpg",
      "../Datasets/images/ISIC_9024038.jpg",
      "../Datasets/images/ISIC_9654537.jpg",
    )

    #grid(
      columns: 8,
      gutter: 3pt,
      ..images.map(img => image(img, width: 100%))
    )
  ],
  caption: flex-caption(
    [Random sample of skin lesion images from the ISIC Archive dataset.],
    [Random sample from the ISIC dataset.],
  ),
) <dataset_random_sample>

The dataset is mostly dermoscopic (90%), with a smaller proportion of clinical close-up photographs and total body photography#numbered_margin_note[TBP tiles are cropped regions from full-body photographs, automatically extracted around detected lesions. They are typically lower resolution than dedicated dermoscopic or clinical close-up images.] (TBP) tiles (see @image_type_distribution for the exact distributions). Including the non-dermoscopic images means the dataset is closer to what you would see in real clinical practice.

#pagebreak()

The following metadata fields were required for dataset selection:

- *Primary diagnosis:* a high-level label indicating whether the lesion is benign, malignant, or indeterminate.

- *Secondary diagnosis:* a more fine-grained categorization of the lesion, allowing for multi-class classification.

The ISIC Archive also provides additional metadata that is not required for image selection but is used later to analyze how input characteristics affect model uncertainty (Research Question B). These include Fitzpatrick skin type, patient age and sex, anatomical site, dermoscopic imaging type, diagnosis confirmation method, and data source attribution. All images from the ISIC Archive that included both primary and secondary diagnosis were included in the dataset.

Because Fitzpatrick skin type annotations are only available for a small subset of images, this label was not used as a selection criterion. It is reserved for evaluating model performance and uncertainty across skin types.

The final dataset contains #format-int(total_dataset_images) images with varying cropping, resolution, and quality, attributed to #dataset_source_count different institutional sources plus a large set of anonymous images. These sources and their respective counts can be found in @dataset_attribution, and @dataset_random_sample shows a random sample.

As is common in dermatological datasets, the dataset is imbalanced with respect to the primary diagnosis, with the majority of images being benign lesions @cassidyAnalysisISICImage2022. This imbalance is relevant to Research Question B, since minority classes may produce systematically different uncertainty estimates. The distribution of primary diagnoses is shown in @primary_diagnosis_distribution.

#margin_figure(
  horizontal-bar-chart(primary_diagnosis_distribution_data, legend-columns: 3),
  caption: [Distribution of primary diagnoses.],
) <primary_diagnosis_distribution>

In addition to the primary diagnosis, each image also has one of 22 unique fine-grained secondary diagnoses. This data is equally imbalanced, with the majority of images being benign melanocytic proliferations. As for malignant lesions, most images are classified as malignant melanocytic proliferations (melanoma), followed by malignant adnexal epithelial proliferations (follicular), with other categories having far fewer images. The distribution of secondary diagnoses is shown in @secondary_diagnosis_distribution, with the top 5 categories displayed for clarity. The full distribution of secondary diagnoses can be found in @secondary_diagnosis_distribution_table.

#margin_figure(
  horizontal-bar-chart(secondary_diagnosis_distribution_data, legend-columns: 1, max-legend-items: 6),
  caption: [Distribution of secondary diagnoses.],
) <secondary_diagnosis_distribution>

As noted earlier, the Fitzpatrick skin type classification is only available for a subset of the dataset. This subset contains #format-int(total_fitzpatrick_annotated) images (#fitzpatrick_annotated_pct\%) with Fitzpatrick skin type annotations. The distribution of Fitzpatrick skin types in this subset is shown in @fitzpatrick_skin_type_distribution.

As @fitzpatrick_skin_type_distribution shows, even for the subset of images with Fitzpatrick skin type annotations, the distribution is imbalanced toward lighter skin types (I, II, and III), with far fewer images classified as darker skin types (IV-VI). This bias is common in dermatological datasets, which often over-represent lighter skin tones @bencevic2024understanding.

The non-annotated images are not included in this distribution, but they are likely even more heavily skewed towards lighter skin types. Nearly all images in the random sample shown in @dataset_random_sample are of lighter skin tones.

#margin_figure(
  horizontal-bar-chart(fitzpatrick_skin_type_distribution_data, legend-columns: 3, colors: (
    rgb("#e9d8c3"),
    rgb("#dec1a4"),
    rgb("#c8a485"),
    rgb("#a67859"),
    rgb("#5e3e2e"),
    rgb("#3a2b24"),
  )),
  caption: [Distribution of Fitzpatrick skin types.],
) <fitzpatrick_skin_type_distribution>

=== Modified dataset

For the purpose of this study, two major modifications were made to the original dataset: setting aside the indeterminate cases and consolidating the secondary diagnosis categories.

First, all images with an indeterminate primary diagnosis were extracted from the dataset. This decision was made to allow the primary head to focus on the binary distinction of benign and malignant lesions. The indeterminate cases were set aside as a held-out evaluation set: because these samples are difficult even for human experts, they can be used to test how different UQ methods handle the most challenging inputs (Research Question C).

Due to the extreme long tail of this data, we also consolidated the secondary diagnosis into broader categories for analysis. The consolidated categories and their distribution, after removal of all indeterminate samples, are shown in @secondary_diagnosis_distribution_cons. The mapping used to merge the original 22 secondary diagnosis categories into these consolidated categories is provided in @secondary_diagnosis_mapping.

#margin_figure(
  horizontal-bar-chart(secondary_diagnosis_distribution_data_cons, legend-columns: 1, max-legend-items: 6),
  caption: [Distribution of secondary diagnoses.],
) <secondary_diagnosis_distribution_cons>

=== Train-Test Split Methodology

The train-test split needed to ensure that all Fitzpatrick skin types have enough samples for evaluation, since darker skin tones are underrepresented, while also preserving the overall dataset composition across sources and institutions. We used a multi-step splitting approach for this.

Before any train-test splitting, all samples with an indeterminate primary diagnosis are separated into a dedicated test set. These 3,289 samples are excluded from training entirely, leaving only benign and malignant samples for the train, validation, and test sets. As a result, the first output head performs binary classification (malignant vs. non-malignant).

The remaining dataset is split with two primary objectives:

1. Ensure adequate representation of all Fitzpatrick skin types in the test set for uncertainty evaluation.
2. Maintain overall dataset diversity by sampling from the complete dataset, not just samples with skin type annotations.

The test set construction operates in two steps:

*#smallcaps[Step 1:] Minimum Skin Type Allocation*
For each available Fitzpatrick skin type (I--VI), we randomly select 100 samples and add them to the test set. This ensures representation of all skin types for uncertainty analysis.

*#smallcaps[Step 2:] Representative Sampling*
After getting the minimum skin type samples, we randomly sample from the remaining dataset to reach the target 10% test set size. This step ensures that the test set includes samples from all data sources and institutions, maintaining the representativeness of the original dataset.

#pagebreak()

The samples not selected for the test set are further divided into a training set (90%) and a validation set (10%). Dataset attribution for each sample is maintained, so that performance can later be evaluated on a per-source basis. @dataset_split_distribution shows the resulting split sizes. The benign/malignant ratio (\~70/30) is maintained consistently across the train, validation, and test splits.

#figure(
  horizontal-bar-chart(dataset_split_distribution_data, legend-columns: 2, show-counts: true, show-percentages: true),
  caption: [Distribution of samples across dataset splits.],
) <dataset_split_distribution>

This splitting algorithm results in the following skin type distribution in the test set:

#figure(
  horizontal-bar-chart(dist_skin_type, legend-columns: 3, show-counts: true, show-percentages: true, colors: (
    rgb("#e9d8c3"),
    rgb("#dec1a4"),
    rgb("#c8a485"),
    rgb("#a67859"),
    rgb("#5e3e2e"),
    rgb("#3a2b24"),
  )),
  caption: [Distribution of samples across Fitzpatrick skin types in the test set.],
) <distribution_skin_type_test_set>

#pagebreak()

== Network Architecture

The core architecture is a convolutional neural network, called the backbone, used as a feature extractor, with weights pre-trained on ImageNet#numbered_margin_note[Transfer learning reuses a network trained on a large general-purpose dataset. The pre-trained convolutional layers already encode general visual features that transfer well to other tasks, reducing the labelled data needed. Fine-tuning then adapts these features to our target domain.]. On top of this backbone, two separate custom layers are added: one for the binary primary diagnosis (malignant vs. non-malignant), and another for the secondary diagnosis (fine-grained lesion category). Each uncertainty estimation method is implemented within these custom layers. The network architecture is shown in @model_architecture.


#let spacing = 0.4;
#let input_size = 7em;
#let branch_size = 8em;
#let backbone_width = 18em;
#let base_color = rgb("#333333");

#let spacing = 0.4;
#let base_color = rgb("#333333");

#margin_figure(
  box(fill: rgb("#fbf9f2"), inset: (x: 0pt, y: 16pt), width: 95%, diagram(
    // Global styles for nodes
    node-inset: 0.75em,
    node-defocus: 0.1,
    spacing: (2em, 2em),
    edge-stroke: 1pt,
    crossing-thickness: 5,
    mark-scale: 70%,
    node-outset: 2pt,

    // --- Layer 1: Input ---
    node(
      (0, 0),
      width: input_size,
      height: input_size,
      fill: base_color.transparentize(80%),
      text(base_color.darken(20%), align(center)[
        _Input_  \
        #text(0.8em)[$[3 times 300 times 300]$]
      ]),
    ),

    edge((0, 0), (0, 1), "-|>", stroke: base_color.lighten(10%)),

    // --- Layer 2: Backbone ---
    node(
      (0, 1),
      fill: default-colors.at(2).transparentize(80%),
      text(default-colors.at(2).darken(20%), align(center)[
        _Feature Extraction Backbone_
      ]),
      width: backbone_width,
    ),

    // Edges splitting to branches
    edge((0, 1), (-spacing, 2), "-|>", stroke: base_color.lighten(10%)),
    edge((0, 1), (spacing, 2), "-|>", stroke: base_color.lighten(10%)),

    // --- Layer 3: Flipout Linear Layers ---
    // Left Branch
    node(
      (-spacing, 2),
      width: branch_size,
      fill: default-colors.at(1).transparentize(80%),
      text(default-colors.at(1).darken(20%), align(center)[
        _Custom Layer_  \
        #text(0.8em)[$[1536]$]
      ]),
    ),

    // Right Branch
    node(
      (spacing, 2),
      width: branch_size,
      fill: default-colors.at(1).transparentize(80%),
      text(default-colors.at(1).darken(20%), align(center)[
        _Custom Layer_  \
        #text(0.8em)[$[1536]$]
      ]),
    ),

    edge((-spacing, 2), (-spacing, 3), "-|>", stroke: base_color.lighten(10%)),
    edge((spacing, 2), (spacing, 3), "-|>", stroke: base_color.lighten(10%)),

    // --- Layer 4: Outputs ---
    // Left Output
    node(
      (-spacing, 3),
      width: branch_size,
      fill: base_color.transparentize(80%),
      text(base_color.darken(20%), align(center)[
        _Dense_  \
        #text(0.8em)[Primary Class, $[1]$]
      ]),
    ),

    // Right Output
    node(
      (spacing, 3),
      width: branch_size,
      fill: base_color.transparentize(80%),
      text(base_color.darken(20%), align(center)[
        _Dense_  \
        #text(0.8em)[Secondary Class, $[5]$]
      ]),
    ),
  )),
  caption: flex-caption(
    [Dual-head classification model architecture. A shared feature extraction backbone feeds into a binary head (H1, malignant vs. benign) and a multiclass head (H2, five diagnostic categories).],
    [Dual-head classification model architecture.],
  ),
) <model_architecture>

To address the class imbalance, both classification heads are trained together using weighted cross-entropy loss. Each head receives its own set of class weights based on the number of samples per class. The two heads are combined through a loss-balance parameter $alpha$, so that the more challenging secondary diagnosis can more strongly influence optimisation. The overall loss function $L$ is defined as follows:

$
  L = L_"primary" + alpha * L_"secondary"
$

Hyperparameters learning rate, batch size, and L2 regularisation strength were optimized using Ray Tune @RayTuneHyperparameter.

#pagebreak()

=== Hyperparameter search space

Different backbones require different hyperparameter ranges to balance training speed and stability. Smaller models can use larger batch sizes and higher learning rates, while heavier architectures are trained with smaller batches and lower learning rates. The common hyperparameter search space across all backbones is listed in @hyperparameter_search_space_common, while backbone-specific search spaces are detailed in @hyperparameter_search_space_backbone.

#figure(
  table(
    columns: (3fr, 2fr),
    inset: (x, y) => if x == 0 { (left: 0pt, right: 8pt, top: 5pt, bottom: 5pt) } else { 5pt },
    stroke: none,
    align: left,
    table.hline(y: 1),
    table.header([_Hyperparameter_], [_Search Space_]),
    [Momentum], [$0.85$ to $0.99$],
    [L2 Regularization], [$10^(-6)$ to $10^1$],
    [Loss weight $alpha$], [$1$ to $5$],
    table.hline(),
  ),
  caption: [Common hyperparameter search space across all backbones.],
) <hyperparameter_search_space_common>

// #full_width[
#figure(
  table(
    columns: (0.7fr, 1.3fr, 1fr, 0.7fr),
    inset: (x, y) => if x == 0 { (left: 0pt, right: 8pt, top: 5pt, bottom: 5pt) } else { 5pt },
    stroke: none,
    align: left,
    table.hline(y: 1),
    table.header([_Category_], [_Backbone_], [_Learning Rate_], [_Batch Size_]),

    [*Small*],
    [
      MobileNetV3-Small @howardSearchingMobileNetV32019 \
      RegNetY-400MF @radosavovicDesigningNetworkDesign2020
    ],
    [$e^(-6)$ to $e^(-2)$],
    [$[48, 64]$],

    table.hline(stroke: 0.5pt),

    [*Medium*],
    [
      ResNet-18 @heDeepResidualLearning2016 \
      ResNet-50 @heDeepResidualLearning2016 \
      EfficientNet-B0 @tanEfficientNetRethinkingModel2019 \
      EfficientNet-B3 @tanEfficientNetRethinkingModel2019 \
      EfficientNet-V2-S @tanEfficientNetV2SmallerModels2021 \
      DenseNet-121 @huangDenselyConnectedConvolutional2017
    ],
    [$e^(-7)$ to $e^(-3)$],
    [$[24, 32, 48]$],

    table.hline(stroke: 0.5pt),

    [*Large*],
    [
      EfficientNet-V2-M @tanEfficientNetV2SmallerModels2021 \
      EfficientNet-V2-L @tanEfficientNetV2SmallerModels2021
    ],
    [$e^(-8)$ to $e^(-4)$],
    [$[12, 16, 24]$],
  ),
  caption: [Backbone-specific hyperparameter search space.],
) <hyperparameter_search_space_backbone>
// ];

=== Model Selection

The best configuration was selected by averaging the validation F1-scores of the primary and secondary diagnosis tasks. F1-score accounts for both precision and recall, which is preferable over accuracy for imbalanced datasets where majority-class dominance can make accuracy misleading. The resulting hyperparameters are listed in @tuned_hyperparameters.

The selected backbone, EfficientNet-B3, belongs to a family of convolutional architectures that scale network depth, width, and input resolution simultaneously using a single compound coefficient @tanEfficientNetRethinkingModel2019. The baseline of this family (EfficientNet-B0) was designed through neural architecture search. Higher variants are obtained by increasing the compound coefficient. EfficientNet-B3 has 12M parameters and a native input resolution of $300 times 300$ @tanEfficientNetRethinkingModel2019.

#figure(
  table(
    columns: (2fr, 3fr),
    inset: (x, y) => if x == 0 { (left: 0pt, right: 8pt, top: 5pt, bottom: 5pt) } else { 5pt },
    stroke: none,
    align: (left, right),
    table.hline(y: 1),
    [_Hyperparameter_], [_Tuned value_],
    [Backbone], [EfficientNet-B3],
    [Learning rate], [0.005686],
    [Batch size], [32],
    [Momentum], [0.930],
    [L2 regularization], [0.0001],
    [Loss weight $alpha$], [1.930],
  ),
  caption: [Tuned hyperparameters for the standard model.],
) <tuned_hyperparameters>

== Data augmentation


All images are standardized to a fixed input size before any model sees them. The exact input size depends on the backbone architecture used, and is based on the original implementation of each architecture. The standardized input sizes for each backbone are listed in @input_sizes_per_backbone.

#figure(
  table(
    columns: (3fr, 3fr),
    inset: (x, y) => if x == 0 { (left: 0pt, right: 8pt, top: 5pt, bottom: 5pt) } else { 5pt },
    stroke: none,
    align: (left, right),
    table.hline(y: 1),
    [_Backbone_], [_Input size_],
    [ResNet-18 \ 
    ResNet-50 \
      DenseNet-121 \
      MobileNetV3 \
      RegNetY-400MF \
      EfficientNet-B0],
    [$224 times 224$],
    [EfficientNet-B3], [$300 times 300$],
    [EfficientNetV2-S], [$384 times 384$],
    [EfficientNetV2-M], [$480 times 480$],
    [EfficientNetV2-L], [$512 times 512$],
  ),
  caption: [Standardized input resolution per backbone architecture.],
) <input_sizes_per_backbone>

Each sample is first resized and then center-cropped to the appropriate input size for the selected backbone. Validation and test examples skip any random augmentation steps and are only resized.

Training batches use the same resizing, but with the additional random augmentation step that samples per-image perturbations. The augmentation pipeline was adapted from the first-place solution of the SIIM-ISIC Melanoma Classification competition#numbered_margin_note[SIIM-ISIC Melanoma Classification, Kaggle 2020. The winning solution by Ha, Liu, and Liu used an augmentation strategy that proved effective for dermoscopic image classification on a similar ISIC dataset @haIdentifyingMelanomaImages2020.], implemented using the Albumentations library @AlbumentationsFastFlexible. The transforms include geometric changes (transposition, flips, affine transforms), brightness and contrast shifts, blur or noise, and optical distortions. It also applies contrast-limited adaptive histogram equalisation (CLAHE) and partial occlusion (CoarseDropout). @augmentation_examples shows the same lesion image after six independent passes through this pipeline.

#figure(
  full_width[
    #grid(
      columns: 7,
      gutter: 3pt,
      align: bottom,
      stack(dir: ttb, spacing: 2pt, image("images/augmentation_examples/original.jpg", width: 100%), align(center, text(
        size: 8pt,
        weight: "bold",
        [Original],
      ))),
      ..range(1, 7).map(i => image("images/augmentation_examples/augmented_" + str(i) + ".jpg", width: 100%)),
    )
  ],
  caption: flex-caption(
    [A single lesion image (left) alongside six augmented versions produced by the training augmentation pipeline. Each version is the result of an independent random pass that may include geometric transforms, brightness and contrast shifts, blur or noise, optical distortions, contrast-limited adaptive histogram equalisation, and partial occlusion (CoarseDropout).],
    [Augmentation pipeline applied to a single lesion image.],
  ),
) <augmentation_examples>

== Training Procedure

All models were implemented in PyTorch and trained on a single NVIDIA GPU with CUDA acceleration. Automatic mixed-precision training @micikevicius2018MixedPrecision was enabled through PyTorch's native AMP module with gradient scaling, reducing memory use and speeding up training.

Standard models were optimised using stochastic gradient descent (SGD) with momentum, while the Flipout and DUQ models used the Adam optimiser @kingmaAdamMethodStochastic2015. To prevent training instabilities, gradient norms were clipped to a maximum value of 1.0. L2 regularisation was applied to all applicable model parameters except for the Flipout model, and all models used early stopping based on validation loss, retaining the checkpoint with the lowest validation loss.

Hyperparameter optimisation was conducted using the Asynchronous Successive Halving Algorithm (ASHA) scheduler provided by Ray Tune @liSystemMassivelyParallel2020. The scheduler was configured with a grace period of 10 epochs, a reduction factor of 2, and a maximum budget of 100 epochs per trial. For each model variant, 100 trial configurations were sampled from the search spaces defined in @hyperparameter_search_space_common and @hyperparameter_search_space_backbone, and underperforming trials were stopped early based on validation loss.

For the DUQ model, the shared hyperparameters (learning rate, batch size, L2 regularisation) were adopted from the standard model's tuning results where applicable. Because DUQ introduces two additional parameters (the RBF length scale $sigma$ and the gradient penalty coefficient $lambda$) a separate grid search was conducted over these two parameters (@duq_grid_search). Each combination was trained for 30 epochs with the backbone frozen to the weights of the trained base model (already fine-tuned on the full skin lesion dataset) to reduce training time.

#figure(
  table(
    columns: (3fr, 2fr),
    inset: (x, y) => if x == 0 { (left: 0pt, right: 8pt, top: 5pt, bottom: 5pt) } else { 5pt },
    stroke: none,
    align: left,
    table.hline(y: 1),
    table.header([_Hyperparameter_], [_Grid Values_]),
    [Length scale $sigma$], [${ 0.05, 0.1, 0.2, 0.5 }$],
    [Gradient penalty $lambda$], [${ 0.1, 0.25, 0.5, 1.0 }$],
    table.hline(),
  ),
  caption: [DUQ-specific hyperparameter grid search values.],
) <duq_grid_search>

#pagebreak()

== Method-Specific Model Descriptions

=== Baseline Model

The baseline model uses the network architecture described above without any uncertainty quantification modifications. It consists of the EfficientNet-B3 backbone followed by two fully connected classification heads, trained with the tuned hyperparameters listed in @tuned_hyperparameters. At inference time, a single deterministic forward pass is performed.

=== Monte Carlo Dropout Model

The MC Dropout variant (@mc_dropout_section) modifies the base architecture by replacing the first linear layer with a dropout layer after the feature extractor, using PyTorch's `torch.nn.functional.dropout` @TorchnnfunctionaldropoutPyTorch210. Dropout is applied with a fixed probability $p = 0.5$ during both training and inference. Uncertainty is estimated by performing $T = 5$ stochastic forward passes through the model.

=== DropConnect Model

Where MC Dropout masks neuron outputs, DropConnect (@dropconnect_section) applies stochastic masking to individual weights instead. In this implementation, the first linear layer in each classification head is replaced by a custom DropConnect layer with keep probability $p = 0.5$. Uncertainty is again estimated by aggregating predictions from $T = 5$ stochastic forward passes.

=== Flipout Model

Flipout (@flipout_section) samples weights from learned distributions using per-example sign perturbations. The Flipout model replaces the first linear layer in each classification head with a custom Flipout layer, implemented in PyTorch based on the Keras implementation from the `keras-uncertainty` library @kerasUncertainty. Its KL weight is set to $lambda_"KL" = B / N$, where $B$ is the batch size and $N$ the number of training samples. The KL divergence term already regularises the weights through the prior, so L2 regularisation is not used for this model. The model is optimised using Adam with a learning rate of 0.001. At inference time, $T = 5$ stochastic forward passes are performed to estimate predictive uncertainty. The remaining Flipout-specific parameters are listed in @flipout_parameters.

#figure(
  table(
    columns: (3fr, 2fr),
    inset: (x, y) => if x == 0 { (left: 0pt, right: 8pt, top: 5pt, bottom: 5pt) } else { 5pt },
    stroke: none,
    align: left,
    table.hline(y: 1),
    table.header([_Parameter_], [_Value_]),
    [Prior $sigma_1$], [$1.5$],
    [Prior $sigma_2$], [$0.1$],
    [Mixture weights $pi_1, pi_2$], [$0.5, 0.5$],
    [Learned $sigma$ clamp range], [$[10^(-5), 10]$],
    table.hline(),
  ),
  caption: [Flipout-specific parameters.],
) <flipout_parameters>

#pagebreak()

=== Deep Ensembles Model

Deep Ensembles (@deep_ensembles_section) derives uncertainty from the disagreement between independently trained models. The ensemble consists of $N = 5$ instances of the base EfficientNet-B3 architecture, following Lakshminarayanan et al. @lakshminarayananSimpleScalablePredictive. Each member is initialized with different random weights but trained using identical hyperparameters and the same augmentation pipeline.

=== DUQ Model

Unlike the other models, the DUQ model replaces both fully connected classification heads with RBF layers as described in @duq_section. It was implemented in PyTorch, also based on the Keras implementation from the `keras-uncertainty` library @kerasUncertainty. A two-sided gradient penalty (@duq_penalty_equation) is applied during training to enforce the Lipschitz constraint described in @duq_section. The DUQ model uses the same pre-trained EfficientNet-B3 backbone as the other methods and is optimised using Adam with a learning rate of 0.001. Unlike the stochastic methods, DUQ requires only a single deterministic forward pass at inference time. Its specific parameters are listed below in @duq_parameters.

Note that the original DUQ paper updates centroids using an exponential moving average (EMA) of the feature vectors assigned to each class @van2020uncertainty, whereas our implementation trains the centroids directly via gradient descent for improved training speed.

#figure(
  table(
    columns: (3fr, 2fr),
    inset: (x, y) => if x == 0 { (left: 0pt, right: 8pt, top: 5pt, bottom: 5pt) } else { 5pt },
    stroke: none,
    align: left,
    table.hline(y: 1),
    table.header([_Parameter_], [_Value_]),
    [Embedding dimensionality $d$], [$2$],
    [Length scale $sigma$], [$0.5$],
    [Gradient penalty $lambda$], [$0.5$],
    table.hline(),
  ),
  caption: [DUQ-specific parameters.],
) <duq_parameters>

#pagebreak()

= Results

== Model Comparison

=== Overall Performance

The predictive performance of all models on the test set is reported in @overall_performance_head1 and @overall_performance_head2. Two classification heads are evaluated: the binary head (H1) distinguishes malignant from benign, while the multiclass head (H2) classifies samples across the five consolidated diagnostic categories.

==== Binary Head

#figure(
  {
    let accuracy_data = (
      (
        to_float(baseline_test_head1.accuracy),
        to_float(baseline_test_head1.ece),
        to_float(baseline_test_head1.auroc_confidence),
      ),
      (
        to_float(ensemble_test_head1.accuracy),
        to_float(ensemble_test_head1.ece),
        to_float(ensemble_test_head1.auroc_confidence),
      ),
      (
        to_float(dropout_test_head1.accuracy),
        to_float(dropout_test_head1.ece),
        to_float(dropout_test_head1.auroc_confidence),
      ),
      (
        to_float(dropconnect_test_head1.accuracy),
        to_float(dropconnect_test_head1.ece),
        to_float(dropconnect_test_head1.auroc_confidence),
      ),
      (
        to_float(flipout_test_head1.accuracy),
        to_float(flipout_test_head1.ece),
        to_float(flipout_test_head1.auroc_confidence),
      ),
      (
        to_float(duq_test_head1.accuracy),
        to_float(duq_test_head1.ece),
        to_float(duq_test_head1.auroc_confidence),
      ),
    )

    color-table(
      accuracy_data,
      model_labels,
      ("Accuracy", "ECE", "AUC"),
      (0.75, 0.00, 0.82),
      (0.93, 0.08, 0.90),
      color-fn: (white-to-green-color, white-to-red-color, white-to-green-color),
    )
  },
  caption: flex-caption(
    [Model performance on test set for the binary head (H1).],
    [Model performance on test set for the binary head (H1).],
  ),
) <overall_performance_head1>

==== Multiclass Head

#figure(
  {
    let accuracy_data = (
      (
        to_float(baseline_test_head2.accuracy),
        to_float(baseline_test_head2.ece),
        to_float(baseline_test_head2.auroc_confidence),
      ),
      (
        to_float(ensemble_test_head2.accuracy),
        to_float(ensemble_test_head2.ece),
        to_float(ensemble_test_head2.auroc_confidence),
      ),
      (
        to_float(dropout_test_head2.accuracy),
        to_float(dropout_test_head2.ece),
        to_float(dropout_test_head2.auroc_confidence),
      ),
      (
        to_float(dropconnect_test_head2.accuracy),
        to_float(dropconnect_test_head2.ece),
        to_float(dropconnect_test_head2.auroc_confidence),
      ),
      (
        to_float(flipout_test_head2.accuracy),
        to_float(flipout_test_head2.ece),
        to_float(flipout_test_head2.auroc_confidence),
      ),
      (
        to_float(duq_test_head2.accuracy),
        to_float(duq_test_head2.ece),
        to_float(duq_test_head2.auroc_confidence),
      ),
    )

    color-table(
      accuracy_data,
      model_labels,
      ("Accuracy", "ECE", "AUC"),
      (0.75, 0.00, 0.82),
      (0.93, 0.08, 0.90),
      color-fn: (white-to-green-color, white-to-red-color, white-to-green-color),
    )
  },
  caption: flex-caption(
    [Model performance on test set for the multiclass head (H2).],
    [Model performance on test set for the multiclass head (H2).],
  ),
) <overall_performance_head2>

#pagebreak()

Four of the five UQ methods match or exceed the baseline in accuracy on both heads. MC Dropout, DropConnect, and Deep Ensembles perform best, while DUQ stays close to the baseline. Flipout is the outlier as it is four points below the baseline on binary classification and more than ten on multiclass classification. Training with the Flipout layer proved unstable, which may partly explain the gap.

Deep Ensembles leads on all three metrics across both heads, with the lowest ECE by a large difference. DropConnect is different: it has strong accuracy but the highest ECE on both heads. AUC values are more similar across methods than accuracy is.

=== Calibration Analysis

Calibration curves show the relationship between predicted confidence and actual accuracy, computed with 15 equal-width confidence bins. A perfectly calibrated model would lie on the diagonal.

#full_width[
  #figure(
    {
      let cal_data = (
        (cal_baseline_test_head1, cal_baseline_test_head2, 0),
        (cal_ensemble_test_head1, cal_ensemble_test_head2, 1),
        (cal_dropout_test_head1, cal_dropout_test_head2, 2),
        (cal_dropconnect_test_head1, cal_dropconnect_test_head2, 3),
        (cal_flipout_test_head1, cal_flipout_test_head2, 4),
        (cal_duq_test_head1, cal_duq_test_head2, 5),
      )

      let plot_h = 48mm

      // Legend above the grid
      align(center, pad(bottom: 2mm, text()[
        #box(baseline: -3pt, line(length: 12pt, stroke: black)) H1 (Binary)
        #h(8mm)
        #box(baseline: -3pt, line(length: 12pt, stroke: (dash: "dashed", paint: black))) H2 (Multiclass)
        #h(8mm)
        #box(baseline: -3pt, line(length: 12pt, stroke: (dash: "dashed", paint: gray))) Perfect calibration
      ]))

      grid(
        columns: (1.2fr, 1fr, 1fr),
        column-gutter: 2mm,
        row-gutter: 4mm,
        ..cal_data
          .enumerate()
          .map(((i, entry)) => {
            let h1_pts = extract-calibration-points(entry.at(0))
            let h2_pts = extract-calibration-points(entry.at(1))
            let color_idx = entry.at(2)
            let is_left = calc.rem(i, 3) == 0
            let is_bottom = i >= 3

            lq.diagram(
              height: plot_h,
              width: 100%,
              title: text(weight: "bold", model_labels.at(color_idx)),
              xlabel: "Predicted Confidence",
              ylabel: if is_left { "Accuracy" } else { none },
              xlim: (0, 1),
              ylim: (0, 1),
              yaxis: if not is_left { (format-ticks: none) } else { (:) },
              lq.plot(
                (0, 1),
                (0, 1),
                stroke: (dash: "dashed", paint: gray),
              ),
              lq.plot(
                h1_pts.xs_high,
                h1_pts.ys_high,
                color: model_palette.at(color_idx),
                mark: "o",
                mark-size: 3pt,
              ),
              lq.plot(
                h2_pts.xs_high,
                h2_pts.ys_high,
                color: model_palette.at(color_idx),
                mark: "s",
                mark-size: 3pt,
                stroke: (dash: "dashed", paint: model_palette.at(color_idx)),
              ),
            )
          })
          .flatten()
      )
    },
    caption: flex-caption(
      [Calibration curves for each model, showing the binary head (H1, solid) and multiclass head (H2, dashed). Each plot compares predicted confidence against actual accuracy. A perfectly calibrated model follows the diagonal. Points shown only for bins with at least 20 samples.],
      [Calibration curves per model, binary head (H1) and multiclass head (H2).],
    ),
  ) <calibration_curves>
]

// #full_width[
//   #figure(
//     {
//       let all_cal_h1 = (
//         ("Baseline", cal_baseline_test_head1),
//         ("Deep Ensembles", cal_ensemble_test_head1),
//         ("MC Dropout", cal_dropout_test_head1),
//         ("DropConnect", cal_dropconnect_test_head1),
//         ("Flipout", cal_flipout_test_head1),
//         ("DUQ", cal_duq_test_head1),
//       )
//       let all_cal_h2 = (
//         ("Baseline", cal_baseline_test_head2),
//         ("Deep Ensembles", cal_ensemble_test_head2),
//         ("MC Dropout", cal_dropout_test_head2),
//         ("DropConnect", cal_dropconnect_test_head2),
//         ("Flipout", cal_flipout_test_head2),
//         ("DUQ", cal_duq_test_head2),
//       )
//
//       let total_n = 5920
//
//       // Show bins 5-14 (confidence >= 0.33), which covers all non-empty bins
//       let bin_start = 5
//       let bin_end = 15  // exclusive
//       let n_bins = bin_end - bin_start
//
//       let bin_label(idx) = {
//         let lo = calc.round(idx / 15 * 100, digits: 0)
//         let hi = calc.round((idx + 1) / 15 * 100, digits: 0)
//         [#lo\u{2013}#hi%]
//       }
//
//       let max_pct = 100  // for color scaling
//
//       let make_rows(cal_list) = {
//         cal_list.map(((name, cal_data)) => {
//           let cells = ()
//           cells.push([*#name*])
//           for bin_idx in range(bin_start, bin_end) {
//             let row = cal_data.at(bin_idx)
//             let count = int(row.count)
//             let pct = count / total_n * 100
//             let bg = if pct > 0 {
//               white.mix((rgb("#2563eb"), calc.min(pct / 50 * 100, 100)))
//             } else {
//               white
//             }
//             let fg = if pct > 25 { white } else { black }
//             cells.push(
//               table.cell(fill: bg)[
//                 #set text(fill: fg, size: 0.8em)
//                 #if pct >= 1 [#calc.round(pct, digits: 0)%] else if count > 0 [#sym.lt 1%] else []
//               ]
//             )
//           }
//           cells
//         }).flatten()
//       }
//
//       table(
//         columns: (auto,) + (1fr,) * n_bins,
//         align: (left,) + (center,) * n_bins,
//         stroke: none,
//         row-gutter: 0pt,
//         table.hline(),
//         table.header(
//           table.cell(rowspan: 2)[*Model*],
//           table.cell(colspan: n_bins, align: center)[*Confidence bin*],
//           ..range(bin_start, bin_end).map(i => {
//             table.cell(align: center)[#text(size: 0.70em)[#bin_label(i)]]
//           }),
//         ),
//         table.hline(stroke: 0.5pt),
//         table.cell(colspan: n_bins + 1)[#text(size: 0.85em, weight: "bold")[H1 (Binary)]],
//         table.hline(stroke: 0.3pt),
//         ..make_rows(all_cal_h1),
//         table.hline(stroke: 0.5pt),
//         table.cell(colspan: n_bins + 1)[#text(size: 0.85em, weight: "bold")[H2 (Multiclass)]],
//         table.hline(stroke: 0.3pt),
//         ..make_rows(all_cal_h2),
//         table.hline(),
//       )
//     },
//     caption: flex-caption(
//       [Distribution of test predictions across confidence bins for each model and head. Cell values show the percentage of the 5920 test samples falling in each bin. Darker shading indicates higher concentration. Most models concentrate predictions in the highest confidence bin, but the degree varies substantially.],
//       [Prediction distribution across confidence bins],
//     ),
//   ) <bin_distribution_table>
// ]

@calibration_curves shows that all models deviate from perfect calibration in the same direction: their curves fall below the diagonal, meaning predicted confidence is consistently larger than actual accuracy. How much overconfidence there is varies between methods.

Deep Ensembles tracks the diagonal most closely on both heads. Its curve stays within a few percentage points of perfect calibration across the full range. Flipout follows a similar pattern on binary classification, but its multiclass curve deviates more in the middle bins.

DropConnect shows the most severe overconfidence. On multiclass classification, its mid-range points fall 20 to 30 percentage points below the diagonal: the model predicts 70--80% confidence for bins where actual accuracy is closer to 50%. MC Dropout behaves similarly, though less extreme. Both methods show jagged curves in the middle confidence range and a smaller number of points.

The smaller number of points in these mid-range curves is because of how predictions are distributed. MC Dropout and DropConnect put 88--94% of binary classification predictions in the highest confidence bin, leaving few samples for the mid-range curve. Deep Ensembles and Flipout spread predictions more broadly (57--74% in the top bin on binary classification), which is why their curves appear smoother and better-sampled across the full range.

On multiclass classification the difference is even larger: Flipout places just 46% in the top bin, while DropConnect still places 93% in that bin.

Baseline and DUQ produce very similar curves on both heads. Both are single-pass deterministic models, and DUQ's distance-based uncertainty does not change the confidence distribution much compared to the baseline's softmax output.

Every model's multiclass classification curve (dashed) deviates further from the diagonal than its binary classification curve (solid). With five target classes instead of two, the model has to spread probability across more categories, so small errors in each class add up to larger calibration error.

=== Uncertainty Decomposition

Calibration tells us whether a model's confidence matches its accuracy, but not where the uncertainty comes from. As introduced in the theoretical background, stochastic UQ methods can decompose total predictive entropy into an aleatoric component and an epistemic component. The "Epistemic %" column shows the fraction of total predictive entropy attributable to epistemic uncertainty, computed as mutual information divided by predictive entropy. Normalizing by predictive entropy makes it possible to compare methods that have different entropy ranges.

#pagebreak()

==== Test Set Uncertainty

#full_width[
  #figure(
    {
      let epist_pct(mi, pe) = [#calc.round(mi / pe * 100, digits: 1)%]
      let uncertainty_data = (
        (
          to_float(ensemble_test_head1.mean_predictive_entropy),
          to_float(ensemble_test_head1.mean_mutual_information),
          to_float(ensemble_test_head1.mean_expected_entropy),
          epist_pct(to_float(ensemble_test_head1.mean_mutual_information), to_float(
            ensemble_test_head1.mean_predictive_entropy,
          )),
        ),
        (
          to_float(dropout_test_head1.mean_predictive_entropy),
          to_float(dropout_test_head1.mean_mutual_information),
          to_float(dropout_test_head1.mean_expected_entropy),
          epist_pct(to_float(dropout_test_head1.mean_mutual_information), to_float(
            dropout_test_head1.mean_predictive_entropy,
          )),
        ),
        (
          to_float(dropconnect_test_head1.mean_predictive_entropy),
          to_float(dropconnect_test_head1.mean_mutual_information),
          to_float(dropconnect_test_head1.mean_expected_entropy),
          epist_pct(to_float(dropconnect_test_head1.mean_mutual_information), to_float(
            dropconnect_test_head1.mean_predictive_entropy,
          )),
        ),
        (
          to_float(flipout_test_head1.mean_predictive_entropy),
          to_float(flipout_test_head1.mean_mutual_information),
          to_float(flipout_test_head1.mean_expected_entropy),
          epist_pct(to_float(flipout_test_head1.mean_mutual_information), to_float(
            flipout_test_head1.mean_predictive_entropy,
          )),
        ),
      )

      color-table(
        uncertainty_data,
        model_labels_uq,
        ("Predictive Entropy", "Epistemic", "Aleatoric", "Epistemic %"),
        0.00,
        1.00,
        use-cell-colors: false,
      )
    },
    caption: flex-caption(
      [Uncertainty decomposition on test set for the binary head (H1).],
      [Uncertainty decomposition, binary head (H1).],
    ),
  ) <uncertainty_test_head1>
]

#full_width[#figure(
  {
    let epist_pct(mi, pe) = [#calc.round(mi / pe * 100, digits: 1)%]
    let uncertainty_data = (
      (
        to_float(ensemble_test_head2.mean_predictive_entropy),
        to_float(ensemble_test_head2.mean_mutual_information),
        to_float(ensemble_test_head2.mean_expected_entropy),
        epist_pct(to_float(ensemble_test_head2.mean_mutual_information), to_float(
          ensemble_test_head2.mean_predictive_entropy,
        )),
      ),
      (
        to_float(dropout_test_head2.mean_predictive_entropy),
        to_float(dropout_test_head2.mean_mutual_information),
        to_float(dropout_test_head2.mean_expected_entropy),
        epist_pct(to_float(dropout_test_head2.mean_mutual_information), to_float(
          dropout_test_head2.mean_predictive_entropy,
        )),
      ),
      (
        to_float(dropconnect_test_head2.mean_predictive_entropy),
        to_float(dropconnect_test_head2.mean_mutual_information),
        to_float(dropconnect_test_head2.mean_expected_entropy),
        epist_pct(to_float(dropconnect_test_head2.mean_mutual_information), to_float(
          dropconnect_test_head2.mean_predictive_entropy,
        )),
      ),
      (
        to_float(flipout_test_head2.mean_predictive_entropy),
        to_float(flipout_test_head2.mean_mutual_information),
        to_float(flipout_test_head2.mean_expected_entropy),
        epist_pct(to_float(flipout_test_head2.mean_mutual_information), to_float(
          flipout_test_head2.mean_predictive_entropy,
        )),
      ),
    )

    color-table(
      uncertainty_data,
      model_labels_uq,
      ("Predictive Entropy", "Epistemic", "Aleatoric", "Epistemic %"),
      0.00,
      1.50,
      use-cell-colors: false,
    )
  },
  caption: flex-caption(
    [Uncertainty decomposition on test set for the multiclass head (H2).],
    [Uncertainty decomposition, multiclass head (H2).],
  ),
) <uncertainty_test_head2>]

==== Analysis of Uncertainty Disentanglement

The uncertainty decomposition shows large differences in how methods split total uncertainty into epistemic and aleatoric components. Flipout produces near-zero mutual information (epistemic uncertainty ≈ 0.00006 for the binary head), so almost all of its entropy comes from aleatoric uncertainty.

Dropout and DropConnect both show similar levels of aleatoric uncertainty in their expected entropy measurements, but DropConnect captures almost zero mutual information, so it does not capture epistemic uncertainty well either.

=== Predictive Entropy Distributions

The violin plots in @entropy_violin_h1 and @entropy_violin_h2 show the full predictive entropy distribution for each method, so that differences in shape, not just mean, are visible.

DUQ is deterministic and does not perform stochastic forward passes, so its entropy cannot be computed by averaging over multiple runs (see @duq_section). For cross-method comparison, these kernel outputs are normalized to sum to one and then passed through the same Shannon entropy formula used for the other methods. This produces values on the same 0-to-$ln(K)$ scale.

#pagebreak()

#margin_note([
  #pad(
    top: 11mm,
    uq_model_labels
      .rev()
      .enumerate()
      .map(((i, label)) => (
        box(
          fill: uq_model_palette.rev().at(i).transparentize(70%),
          stroke: uq_model_palette.rev().at(i),
          width: 0.8em,
          height: 0.8em,
          baseline: 15%,
        )
          + h(0.4em)
          + label
      ))
      .join([\  ]),
  )])

#pad(
  left: 1mm,
  grid(columns: (53mm, 53mm), gutter: 8mm)[
    #figure(
      {
        let ys = range(uq_model_labels.len())
        let plots = ()
        for (idx, label) in uq_model_labels.enumerate() {
          let values = predictive_entropy_head1.at(idx)
          if values.len() > 0 {
            plots.push(
              lq.hviolin(
                values,
                y: (ys.at(idx),),
                color: uq_model_palette.at(idx),
                width: 0.8,
              ),
            )
          }
        }

        lq.diagram(
          height: 55mm,
          width: 53mm,
          xlabel: "Predictive Entropy",
          xlim: (-0.1, 1.0),
          ylim: (-0.5, uq_model_labels.len() - 0.5),
          yaxis: (format-ticks: none),
          ..plots,
        )
      },
      caption: [Predictive entropy, binary head (H1) - Test Set.],
    ) <entropy_violin_h1>
  ][
    #figure(
      {
        let ys = range(uq_model_labels.len())
        let plots = ()
        for (idx, label) in uq_model_labels.enumerate() {
          let values = predictive_entropy_head2.at(idx)
          if values.len() > 0 {
            plots.push(
              lq.hviolin(
                values,
                y: (ys.at(idx),),
                color: uq_model_palette.at(idx),
                width: 0.8,
              ),
            )
          }
        }

        lq.diagram(
          height: 55mm,
          width: 53mm,
          xlabel: "Predictive Entropy",
          xlim: (-0.1, 2.0),
          ylim: (-0.5, uq_model_labels.len() - 0.5),
          yaxis: (format-ticks: none),
          ..plots,
        )
      },
      caption: [Predictive entropy, multiclass head (H2) - Test Set.],
    ) <entropy_violin_h2>
  ],
)

All methods produce heavily left-skewed entropy distributions concentrated near zero, since most samples are classified confidently. The methods differ in how far their tails extend. Flipout produces the widest spread with the highest entropy values, while DropConnect and MC Dropout are more tightly concentrated at low entropy. Deep Ensembles and DUQ fall in between.

==== Indeterminate Set Entropy Distribution

The indeterminate test set contains samples that were flagged as clinically ambiguous during labeling. A well-calibrated uncertainty quantification method should show higher entropy on these difficult samples than on the main test set.

#margin_note([
  #pad(
    top: 11mm,
    uq_model_labels
      .rev()
      .enumerate()
      .map(((i, label)) => (
        box(
          fill: uq_model_palette.rev().at(i).transparentize(70%),
          stroke: uq_model_palette.rev().at(i),
          width: 0.8em,
          height: 0.8em,
          baseline: 15%,
        )
          + h(0.4em)
          + label
      ))
      .join([\  ]),
  )])

#pad(
  left: 1mm,
  grid(columns: (53mm, 53mm), gutter: 8mm)[
    #figure(
      {
        let ys = range(uq_model_labels.len())
        let plots = ()
        for (idx, label) in uq_model_labels.enumerate() {
          let values = predictive_entropy_indet_head1.at(idx)
          if values.len() > 0 {
            plots.push(
              lq.hviolin(
                values,
                y: (ys.at(idx),),
                color: uq_model_palette.at(idx),
              ),
            )
          }
        }
        lq.diagram(
          height: 55mm,
          width: 53mm,
          xlabel: "Predictive Entropy",
          xlim: (-0.1, 1.0),
          ylim: (-0.5, uq_model_labels.len() - 0.5),
          yaxis: (format-ticks: none),
          ..plots,
        )
      },
      caption: [Predictive entropy, binary head (H1) - Indeterminate Set.],
    ) <entropy_violin_indet_h1>
  ][
    #figure(
      {
        let ys = range(uq_model_labels.len())
        let plots = ()
        for (idx, label) in uq_model_labels.enumerate() {
          let values = predictive_entropy_indet_head2.at(idx)
          if values.len() > 0 {
            plots.push(
              lq.hviolin(
                values,
                y: (ys.at(idx),),
                color: uq_model_palette.at(idx),
              ),
            )
          }
        }

        lq.diagram(
          height: 55mm,
          width: 53mm,
          xlabel: "Predictive Entropy",
          xlim: (-0.1, 2.0),
          ylim: (-0.5, uq_model_labels.len() - 0.5),
          yaxis: (format-ticks: none),
          ..plots,
        )
      },
      caption: [Predictive entropy, multiclass head (H2) - Indeterminate Set.],
    ) <entropy_violin_indet_h2>
  ],
)

Comparing the test set (@entropy_violin_h1, @entropy_violin_h2) with the indeterminate set (@entropy_violin_indet_h1, @entropy_violin_indet_h2) shows differences in uncertainty calibration. Every UQ method shows higher entropy on the indeterminate set than on the test set, so all approaches show sensitivity to sample difficulty. However, the methods differ in absolute entropy values. Detailed analysis shows that DropConnect and MC Dropout have lower absolute entropy on difficult samples, but they show the largest relative increase from the test set to the indeterminate set (see @entropy_growth_appendix). So even though their absolute uncertainty estimates are lower, both methods are still sensitive to sample difficulty.

To show what high-entropy indeterminate samples look like, @indeterminate_highest_entropy displays the five samples with the highest multiclass-head entropy under Deep Ensembles. For the analogous test-set view from the binary head, @entropy_samples_appendix shows fifteen low-entropy ($approx 0.05$) and fifteen high-entropy ($approx 0.65$) samples under the same model.

#let indet_sample_ids = ("ISIC_2630907", "ISIC_4581129", "ISIC_0054081", "ISIC_7314033", "ISIC_7341225")

#full_width[#figure(
  grid(
    columns: (1fr,) * 5,
    column-gutter: 3mm,
    ..indet_sample_ids.map(id => layout(size => box(
      clip: true,
      width: 100%,
      height: size.width,
      image("images/indeterminate_samples/" + id + ".jpg", width: 100%, height: 100%, fit: "cover"),
    ))),
  ),
  kind: image,
  caption: flex-caption(
    [Five indeterminate-set samples with the highest predictive entropy on the multiclass head, ranked by Deep Ensembles.],
    [Highest-entropy indeterminate samples.],
  ),
) <indeterminate_highest_entropy>]

Looking at all these results, there is a clear ranking. Deep Ensembles lead on accuracy, calibration, and uncertainty decomposition. MC Dropout and DropConnect match its accuracy but calibrate worse and produce narrower entropy distributions.

DUQ performs near the baseline with no uncertainty decomposition. Flipout is worse on accuracy and produces near-zero epistemic uncertainty, though it still responds to sample difficulty through total entropy.

#pagebreak()

== Effect of Input Characteristics on Uncertainty

Which input characteristics affect model uncertainty, and how much do they matter for clinical use (Research Question B)? The following analyses quantify the effect of available metadata variables on predictive entropy using both univariate (ANOVA) and multivariate regression.

=== Statistical Influence Summary

To quantify how strongly each metadata variable influences model uncertainty, we use one-way ANOVA, which tests whether the mean predictive entropy differs across levels of a categorical variable, like skin type or data source. The effect size is reported as eta-squared (η²), which is the proportion of variance in entropy explained by that variable (ranging from 0 to 1). By convention, η² values around 0.01 are considered small, 0.06 medium, and 0.14 large. Because the test set contains over 5900 samples, all non-zero effects reach $p < 0.001$. At this sample size, p-values are not very informative, so the focus is on effect sizes instead.

#full_width[
  #figure(
    {
      let influence_data = influence_flipout_h1.sorted(key: row => -float(row.at("effect_size")))

      let ensemble_lookup = influence_ensemble_h1.fold((:), (acc, row) => {
        acc.insert(row.at("column"), row)
        acc
      })
      let dropout_lookup = influence_dropout_h1.fold((:), (acc, row) => {
        acc.insert(row.at("column"), row)
        acc
      })
      let dropconnect_lookup = influence_dropconnect_h1.fold((:), (acc, row) => {
        acc.insert(row.at("column"), row)
        acc
      })
      let duq_lookup = influence_duq_h1.fold((:), (acc, row) => {
        acc.insert(row.at("column"), row)
        acc
      })

      let all_effects = (
        influence_flipout_h1.map(r => float(r.at("effect_size")))
          + influence_ensemble_h1.map(r => float(r.at("effect_size")))
          + influence_dropout_h1.map(r => float(r.at("effect_size")))
          + influence_dropconnect_h1.map(r => float(r.at("effect_size")))
          + influence_duq_h1.map(r => float(r.at("effect_size")))
      )
      let min_effect = calc.min(..all_effects)
      let max_effect = calc.max(..all_effects)

      table(
        columns: (1fr, auto, auto, auto, auto, auto, auto),
        align: (left, right, right, right, right, right, right),
        stroke: none,
        inset: (x, y) => if x == 0 { (left: 0pt, right: 4pt, top: 5pt, bottom: 5pt) } else { 4pt },
        table.hline(y: 2),
        table.header(
          table.cell(rowspan: 2, [_Characteristic_], align: bottom),
          table.cell(rowspan: 2, [_N_], align: bottom),
          table.cell(colspan: 5, [_Effect Size (η²)_], align: center),
          [_Flipout_], [_Ensemble_], [_DropOut_], [_DropConnect_], [_DUQ_],
        ),
        ..influence_data
          .map(row => {
            let col = row.at("column")
            let flipout_effect = float(row.at("effect_size"))
            let ensemble_effect = float(ensemble_lookup.at(col).at("effect_size"))
            let dropout_effect = float(dropout_lookup.at(col).at("effect_size"))
            let dropconnect_effect = float(dropconnect_lookup.at(col).at("effect_size"))
            let duq_effect = float(duq_lookup.at(col).at("effect_size"))
            (
              metadata-label(col),
              row.at("n_samples"),
              table.cell(fill: white-to-green-color(flipout_effect, min_effect, max_effect))[#fmt(
                flipout_effect,
                decimals: 3,
              )],
              table.cell(fill: white-to-green-color(ensemble_effect, min_effect, max_effect))[#fmt(
                ensemble_effect,
                decimals: 3,
              )],
              table.cell(fill: white-to-green-color(dropout_effect, min_effect, max_effect))[#fmt(
                dropout_effect,
                decimals: 3,
              )],
              table.cell(fill: white-to-green-color(dropconnect_effect, min_effect, max_effect))[#fmt(
                dropconnect_effect,
                decimals: 3,
              )],
              table.cell(fill: white-to-green-color(duq_effect, min_effect, max_effect))[#fmt(
                duq_effect,
                decimals: 3,
              )],
            )
          })
          .flatten(),
      )
    },
    caption: flex-caption(
      [ANOVA effect sizes (η²) for the influence of metadata variables on predictive entropy, binary head (H1).],
      [ANOVA effect sizes, binary head (H1).],
    ),
  ) <influence_summary_main>]

#full_width[
  #figure(
    {
      let influence_data = influence_flipout_h2.sorted(key: row => -float(row.at("effect_size")))

      let ensemble_lookup = influence_ensemble_h2.fold((:), (acc, row) => {
        acc.insert(row.at("column"), row)
        acc
      })
      let dropout_lookup = influence_dropout_h2.fold((:), (acc, row) => {
        acc.insert(row.at("column"), row)
        acc
      })
      let dropconnect_lookup = influence_dropconnect_h2.fold((:), (acc, row) => {
        acc.insert(row.at("column"), row)
        acc
      })
      let duq_lookup = influence_duq_h2.fold((:), (acc, row) => {
        acc.insert(row.at("column"), row)
        acc
      })

      let all_effects = (
        influence_flipout_h2.map(r => float(r.at("effect_size")))
          + influence_ensemble_h2.map(r => float(r.at("effect_size")))
          + influence_dropout_h2.map(r => float(r.at("effect_size")))
          + influence_dropconnect_h2.map(r => float(r.at("effect_size")))
          + influence_duq_h2.map(r => float(r.at("effect_size")))
      )
      let min_effect = calc.min(..all_effects)
      let max_effect = calc.max(..all_effects)

      table(
        columns: (1fr, auto, auto, auto, auto, auto, auto),
        align: (left, right, right, right, right, right, right),
        stroke: none,
        inset: (x, y) => if x == 0 { (left: 0pt, right: 4pt, top: 5pt, bottom: 5pt) } else { 4pt },
        table.hline(y: 2),
        table.header(
          table.cell(rowspan: 2, [_Characteristic_], align: bottom),
          table.cell(rowspan: 2, [_N_], align: bottom),
          table.cell(colspan: 5, [_Effect Size (η²)_], align: center),
          [_Flipout_], [_Ensemble_], [_DropOut_], [_DropConnect_], [_DUQ_],
        ),
        ..influence_data
          .map(row => {
            let col = row.at("column")
            let flipout_effect = float(row.at("effect_size"))
            let ensemble_effect = float(ensemble_lookup.at(col).at("effect_size"))
            let dropout_effect = float(dropout_lookup.at(col).at("effect_size"))
            let dropconnect_effect = float(dropconnect_lookup.at(col).at("effect_size"))
            let duq_effect = float(duq_lookup.at(col).at("effect_size"))
            (
              metadata-label(col),
              row.at("n_samples"),
              table.cell(fill: white-to-green-color(flipout_effect, min_effect, max_effect))[#fmt(
                flipout_effect,
                decimals: 3,
              )],
              table.cell(fill: white-to-green-color(ensemble_effect, min_effect, max_effect))[#fmt(
                ensemble_effect,
                decimals: 3,
              )],
              table.cell(fill: white-to-green-color(dropout_effect, min_effect, max_effect))[#fmt(
                dropout_effect,
                decimals: 3,
              )],
              table.cell(fill: white-to-green-color(dropconnect_effect, min_effect, max_effect))[#fmt(
                dropconnect_effect,
                decimals: 3,
              )],
              table.cell(fill: white-to-green-color(duq_effect, min_effect, max_effect))[#fmt(
                duq_effect,
                decimals: 3,
              )],
            )
          })
          .flatten(),
      )
    },
    caption: flex-caption(
      [ANOVA effect sizes (η²) for the influence of metadata variables on predictive entropy, multiclass head (H2).],
      [ANOVA effect sizes, multiclass head (H2).],
    ),
  ) <influence_summary_main_h2>]

A few patterns appear on both heads. Diagnosis confirmation type has the largest effect on entropy for all models (η² = 0.12--0.32 on the binary head), because histopathologically confirmed cases are usually harder to diagnose. Fitzpatrick skin type shows a strong effect (η² = 0.07--0.18 on the binary head), though this is measured on the labeled subset only ($N$~=~893). Data source (attribution) and age also produce moderate effects, while sex has essentially no influence (η²~≈~0 for all models).

The effect sizes are consistently larger for Flipout and Deep Ensembles than for the MC methods, meaning their entropy changes more based on input characteristics.

#pagebreak()

=== Multivariate Regression

The univariate ANOVA tests above show the marginal #numbered_margin_note[A marginal effect is the individual effect of a single variable in isolation, without accounting for the influence of other variables.] effect of each variable, but metadata variables can be correlated: for example, histopathologically confirmed cases could be disproportionately malignant, and data source is related to imaging protocols and patient demographics. To separate these effects, we fit a multivariate linear model with all available metadata variables as simultaneous predictors.

Type II sums of squares test each variable's contribution after controlling for all others. The effect size is reported as partial η² (the variance explained by that variable alone, with the other predictors held constant). The overall model fit is reported as R², the total proportion of entropy variance explained by all predictors together.

#let multivariate_regression = csv(metrics_dir + "/multivariate_regression_entropy.csv", row-type: dictionary)

The model includes primary diagnosis, secondary diagnosis, diagnosis confirmation type, age, data source, image type, sex, and anatomical site. Fitzpatrick skin type is excluded due to low coverage (15%) which would result in unstable estimates. Its effects are analysed separately in the following section. Dermoscopic imaging subtype (contact/non-contact, polarised/non-polarised) is also excluded as it is only recorded for 24% of samples. Note that the Image Type variable included in the regression refers to the image category (e.g. dermoscopic vs clinical), not the dermoscopic subtype. The final sample size is $N = 3617$. Detailed per-model regression tables are provided in @multivariate_regression_appendix.

#let mv_get_row(run_type, head, term) = {
  multivariate_regression.find(r => r.at("run_type") == run_type and r.at("head") == head and r.at("term") == term)
}

#let mv_terms = (
  "diagnosis_confirm_type",
  "diagnosis_2",
  "attribution",
  "image_type",
  "anatom_site_general",
  "age_approx",
  "diagnosis_1",
  "sex",
)
#let mv_labels = (
  [Confirmation type],
  [Secondary diagnosis],
  [Attribution],
  [Image type],
  [Anatomical site],
  [Age],
  [Primary diagnosis],
  [Sex],
)
#let mv_models = ("flipout", "ensemble", "dropout", "dropconnect", "duq")

#full_width[
  #figure(
    {
      let all_effects = mv_models
        .map(m => mv_terms.map(t => {
          let row = mv_get_row(m, "head1", t)
          if row != none and row.at("partial_eta_sq") != "" { float(row.at("partial_eta_sq")) } else { 0.0 }
        }))
        .flatten()
      let min_effect = calc.min(..all_effects)
      let max_effect = calc.max(..all_effects)

      table(
        columns: (1fr, auto, auto, auto, auto, auto),
        align: (left, right, right, right, right, right),
        stroke: none,
        inset: (x, y) => if x == 0 { (left: 0pt, right: 4pt, top: 5pt, bottom: 5pt) } else { 4pt },
        table.hline(y: 2),
        table.header(
          table.cell(rowspan: 2, [_Variable_], align: bottom),
          table.cell(colspan: 5, [_Partial η²_], align: center),
          [_Flipout_], [_Ensemble_], [_DropOut_], [_DropConnect_], [_DUQ_],
        ),
        ..mv_terms
          .enumerate()
          .map(((i, term)) => {
            (
              mv_labels.at(i),
              ..mv_models.map(m => {
                let row = mv_get_row(m, "head1", term)
                if row == none or row.at("partial_eta_sq") == "" {
                  [—]
                } else {
                  let v = float(row.at("partial_eta_sq"))
                  table.cell(fill: white-to-green-color(v, min_effect, max_effect))[#fmt(v, decimals: 3)]
                }
              }),
            )
          })
          .flatten(),
        table.hline(),
        [_Model $R^2$_],
        ..mv_models.map(m => {
          let row = mv_get_row(m, "head1", "Model (total)")
          if row != none { [_#fmt(float(row.at("eta_sq")), decimals: 3)_] } else { [—] }
        }),
      )
    },
    caption: flex-caption(
      [Partial η² from multivariate regression of predictive entropy on metadata variables (Type II SS), binary head (H1). Each value shows the unique variance explained by that variable after controlling for all others.],
      [Multivariate regression of predictive entropy, binary head (H1).],
    ),
  ) <multivariate_regression_h1>
]

#full_width[
  #figure(
    {
      let all_effects = mv_models
        .map(m => mv_terms.map(t => {
          let row = mv_get_row(m, "head2", t)
          if row != none and row.at("partial_eta_sq") != "" { float(row.at("partial_eta_sq")) } else { 0.0 }
        }))
        .flatten()
      let min_effect = calc.min(..all_effects)
      let max_effect = calc.max(..all_effects)

      table(
        columns: (1fr, auto, auto, auto, auto, auto),
        align: (left, right, right, right, right, right),
        stroke: none,
        inset: (x, y) => if x == 0 { (left: 0pt, right: 4pt, top: 5pt, bottom: 5pt) } else { 4pt },
        table.hline(y: 2),
        table.header(
          table.cell(rowspan: 2, [_Variable_], align: bottom),
          table.cell(colspan: 5, [_Partial η²_], align: center),
          [_Flipout_], [_Ensemble_], [_DropOut_], [_DropConnect_], [_DUQ_],
        ),
        ..mv_terms
          .enumerate()
          .map(((i, term)) => {
            (
              mv_labels.at(i),
              ..mv_models.map(m => {
                let row = mv_get_row(m, "head2", term)
                if row == none or row.at("partial_eta_sq") == "" {
                  [—]
                } else {
                  let v = float(row.at("partial_eta_sq"))
                  table.cell(fill: white-to-green-color(v, min_effect, max_effect))[#fmt(v, decimals: 3)]
                }
              }),
            )
          })
          .flatten(),
        table.hline(),
        [_Model $R^2$_],
        ..mv_models.map(m => {
          let row = mv_get_row(m, "head2", "Model (total)")
          if row != none { [_#fmt(float(row.at("eta_sq")), decimals: 3)_] } else { [—] }
        }),
      )
    },
    caption: flex-caption(
      [Partial η² from multivariate regression of predictive entropy on metadata variables (Type II SS), multiclass head (H2). Each value shows the unique variance explained by that variable after controlling for all others.],
      [Multivariate regression of predictive entropy, multiclass head (H2).],
    ),
  ) <multivariate_regression_h2>
]

The multivariate models explain between 9% (DropConnect) and 46% (Flipout) of the variance in predictive entropy for the binary head, as shown in @multivariate_regression_h1. For the multiclass head (@multivariate_regression_h2), the range is 9% to 35%. The results show:

Diagnosis confirmation type is the strongest independent predictor across all models, with partial η² ranging from 0.026 (DropConnect/Dropout) to 0.283 (Flipout) for the binary head. Primary diagnosis is non-significant across all models once secondary diagnosis is included, which is expected: secondary diagnosis is a refinement of primary diagnosis (benign maps to benign. All others map to malignant), so primary diagnosis carries no additional information. Attribution also has a significant independent effect across all models, meaning that imaging differences still influence uncertainty even after controlling for clinical variables.

Flipout and Deep Ensembles produce entropy that correlates more strongly with metadata: when the input comes from a different hospital or involves a harder lesion type, their entropy increases more noticeably, which produces larger partial η² values. DropConnect and Dropout show weaker correlations, but this is probably because their entropy varies less overall, not because they handle input variation better. As shown in the entropy distributions above, these methods produce narrower distributions with less variance for metadata to explain.

The three strongest independent predictors are examined below: diagnosis confirmation type, lesion type (secondary diagnosis), and data source attribution in more detail. The remaining variables (image type, anatomical site, age) have much smaller independent effects, and sex is consistently non-significant. Per-modality accuracy, entropy, and ECE tables for image type are provided in @image_type_performance_appendix, with sample images by modality in @image_type_samples_appendix.

#pagebreak()

=== Diagnosis Confirmation Type

Diagnosis confirmation type is the method used to establish ground truth labels. The multivariate regression (@multivariate_regression_h1, @multivariate_regression_h2) identifies it as the strongest independent predictor of entropy across all UQ methods. The full test-set distribution of confirmation types is given in @diagnosis_confirm_distribution_appendix. Detailed performance metrics by confirmation type are provided in @diagnosis_confirm_performance_appendix, and visual examples in @diagnosis_confirm_samples_appendix.

94.5% of malignant samples in the test set were confirmed by histopathology. The remaining are 83 with no recorded confirmation type (4.7%) and 14 confirmed by confocal microscopy with consensus dermoscopy (0.8%).

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, right, right, right),
    stroke: none,
    inset: 4pt,
    table.hline(y: 1),
    table.header([_Confirmation Type_], [_N_], [_% Malignant_], [_% Benign_]),
    ..diagnosis_by_confirm
      .map(row => {
        (
          row.at("group_value"),
          str(int(float(row.at("n")))),
          fmt(float(row.at("pct_malignant"))) + "%",
          fmt(float(row.at("pct_benign"))) + "%",
        )
      })
      .flatten(),
    table.hline(),
  ),
  caption: flex-caption(
    [Diagnosis distribution (malignant vs. benign) by confirmation type in the test set.],
    [Diagnosis distribution by confirmation type.],
  ),
) <diagnosis_by_confirmation_type>

@diagnosis_by_confirmation_type shows a strong relationship between confirmation type and diagnosis: histopathology cases are 56% malignant, confocal microscopy with consensus dermoscopy 17% malignant, and the remaining three methods contain exclusively benign cases. So maybe the confirmation type effect on entropy just comes from the different malignancy rates. The multivariate regression controls for both primary and secondary diagnosis simultaneously, and confirmation type still retains the largest independent effect, so the effect is not driven by diagnosis composition alone.

The split between aleatoric and epistemic uncertainty across confirmation types (see @diagnosis_confirm_uncertainty_decomposition) helps explain this. Histopathology cases show higher total entropy than other confirmation types, but the epistemic proportion remains stable across all groups. The higher uncertainty reflects case difficulty rather than a lack of model knowledge: cases referred for histopathological examination are more diagnostically ambiguous, and the model's predictions reflect this ambiguity regardless of the final diagnosis.

If confirmation type is a proxy for case severity (histopathology cases were suspicious enough to warrant biopsy) then methods that respond more strongly to this variable are producing more useful uncertainty estimates. Flipout, Deep Ensembles, and to a lesser extent DUQ show this pattern: their entropy increases noticeably from clinically-confirmed to histopathology cases. DropConnect and Dropout barely shift their entropy between these groups, suggesting weaker sensitivity to diagnostic difficulty. This is a limitation of these methods.

#pagebreak()

=== Lesion Type (Secondary Diagnosis)

The secondary diagnosis is the fine-grained lesion label that the multiclass head is trained to predict. The test set distribution (see @secondary_diagnosis_distribution_cons) and model performance vary across categories. Detailed accuracy, entropy, and calibration tables are provided in @lesion_type_performance_appendix, and visual examples of each lesion type in @lesion_type_samples_appendix.

#let lesion_type_order = ("Benign", "Malignant_NonEpidermal", "Malignant_Epidermal", "Melanoma", "Other")
#let lesion_type_labels = (
  "Benign": [Benign \ ],
  "Malignant_NonEpidermal": [Malignant \ Non-Epidermal],
  "Malignant_Epidermal": [Malignant \ Epidermal],
  "Melanoma": [Melanoma \ ],
  "Other": [Other \ ],
)
#let lesion_sample_csv = csv("../Notebooks/results/lesion_type_samples/sampled_images.csv", row-type: dictionary)

#full_width[#figure(
  grid(
    columns: 5,
    column-gutter: 3mm,
    row-gutter: 1mm,
    ..lesion_type_order.map(lt => {
      let rows = lesion_sample_csv.filter(r => r.at("lesion_type") == lt).slice(0, 4)
      stack(
        dir: ttb,
        spacing: 1mm,
        grid(
          columns: 2,
          gutter: 1mm,
          ..rows.map(r => layout(size => box(
            clip: true,
            width: 100%,
            height: size.width,
            align(center + top, image(r.at("image_path"), width: 100%)),
          )))
        ),
        align(center, text(size: 1em, lesion_type_labels.at(lt))),
      )
    })
  ),
  caption: flex-caption(
    [Representative dermoscopic images for each lesion type (secondary diagnosis category) in the test set.],
    [Sample images by lesion type.],
  ),
) <lesion_type_samples>]

All models achieve high accuracy on Benign, Malignant Epidermal, and Malignant Non-Epidermal categories. These have clear diagnostic patterns. Melanoma proves more challenging, with accuracy ranging from 76% to 81%, consistent with the diagnostic difficulty of this category. The "Other" category shows the lowest accuracy (58--76%) across all models, consistent with the inclusion of ambiguous cases such as indeterminate epidermal and melanocytic proliferations. This makes sense, because melanoma is hard to tell apart from atypical nevi @esteva2017dermatologist.

Predictive entropy increases with diagnostic difficulty across all methods: Benign cases show the lowest entropy, followed by Malignant Non-Epidermal and Malignant Epidermal, with Melanoma and the "Other" category producing the highest uncertainty. The magnitude of this response varies between methods. Flipout and Deep Ensembles again show the strongest entropy increase from easy to difficult categories, for example, Flipout's mean entropy increases from Benign (0.240) to Melanoma (0.392), and Deep Ensembles show a similar increase from 0.133 to 0.290.

DUQ again is similar to Ensembles (0.107 to 0.260). In contrast, DropConnect's entropy absolute values barely shift (0.028 to 0.075), and Dropout shows a similar response (0.047 to 0.132). Their relative increase is large due to the low baseline, but the absolute values remain low.

Calibration differences between methods are clearest for Melanoma. DropConnect shows an ECE of 0.206 on melanoma cases, while Dropout also shows poor calibration at 0.182. In contrast, Flipout achieves the best melanoma calibration (ECE = 0.055) despite having lower overall accuracy, and Deep Ensembles maintain good calibration (ECE = 0.079) while achieving the highest melanoma accuracy (81.1%).

#pagebreak()

=== Data Source (Attribution)

The dataset aggregates samples from multiple clinical sources (see @dataset_attribution for full breakdown). Data source has a moderate effect on model uncertainty (see @influence_summary_main), likely because imaging equipment and protocols differ across institutions. Detailed performance metrics by data source for all UQ methods are provided in @attribution_performance_appendix, and visual examples from each source are shown in @attribution_samples_appendix.

One outlier is the Royal Prince Alfred Hospital dataset, which shows both low accuracy and high uncertainty across all UQ methods, while not being the smallest data source. Some characteristic of this dataset likely explains the poor performance. Looking at a sample of images from each data source (see @attribution_samples_appendix), shows a clear difference in image quality for the Royal Prince Alfred Hospital images, which have a white background, as opposed to the black background in all other datasets.

Deep Ensembles achieve the highest accuracy and lowest uncertainty across data sources. Even for the challenging Royal Prince Alfred Hospital dataset, the ensemble's 0.72 accuracy outperforms other methods by a large margin (next best is DUQ at 0.63). Deep Ensembles handle the differences between data sources better. Despite being the most accurate method on this dataset, it still shows the second highest uncertainty, which suggests a better-calibrated response to genuine difficulty. Dropout and DropConnect perform particularly poorly, with low accuracy and low uncertainty. These methods are worse at estimating uncertainty when the data source changes.

#let img_tile(path) = box(
  width: 100%,
  stroke: 0.5pt + gray,
  inset: 0pt,
  clip: true,
  image(path, width: 100%, height: auto),
)

#figure(
  grid(
    columns: 5,
    gutter: 2mm,
    ..("ISIC_0062129", "ISIC_0056740", "ISIC_0066432", "ISIC_0066329", "ISIC_0053475").map(id => img_tile(
      "images/attribution_samples/other/" + id + ".jpg",
    )),
  ),
  caption: flex-caption(
    [Random sample images from various data sources, showing the typical black background.],
    [Other data source samples.],
  ),
) <other_source_samples>

#figure(
  grid(
    columns: 5,
    gutter: 2mm,
    ..("ISIC_8184620", "ISIC_9543045", "ISIC_6586433", "ISIC_7576704", "ISIC_1727295").map(id => img_tile(
      "images/attribution_samples/prince_alfred/" + id + ".jpg",
    )),
  ),
  caption: flex-caption(
    [Sample images from Royal Prince Alfred Hospital, showing the distinctive white background with circular crop.],
    [Royal Prince Alfred Hospital samples.],
  ),
) <prince_alfred_samples>

#pagebreak()

To test whether the white background is a contributing factor to the higher uncertainty on these images, we selected 16 Prince Alfred images with the characteristic white-background circular crop and replaced the background with black. We tested two variants: one with only the background replaced (@prince_alfred_black_samples), and one that additionally removes the measurement markers visible in the original images (@prince_alfred_black_manual_samples). Five representative samples are shown above, all 16 were used for the analysis. @bg_entropy_comparison_h1 and @bg_entropy_comparison_h2 show the mean predictive entropy and accuracy changes for the binary and multiclass heads respectively, comparing both variants against the original.

#figure(
  grid(
    columns: 5,
    gutter: 2mm,
    ..("ISIC_8184620", "ISIC_9543045", "ISIC_6586433", "ISIC_7576704", "ISIC_1727295").map(id => img_tile(
      "images/attribution_samples/prince_alfred_black/" + id + ".jpg",
    )),
  ),
  caption: flex-caption(
    [The same Royal Prince Alfred Hospital images with the white background replaced by black.],
    [Royal Prince Alfred Hospital samples with black background.],
  ),
) <prince_alfred_black_samples>

#figure(
  grid(
    columns: 5,
    gutter: 2mm,
    ..("ISIC_8184620", "ISIC_9543045", "ISIC_6586433", "ISIC_7576704", "ISIC_1727295").map(id => img_tile(
      "images/attribution_samples/prince_alfred_black_manual/" + id + ".jpg",
    )),
  ),
  caption: flex-caption(
    [The same Royal Prince Alfred Hospital images with the white background replaced by black and measurement markers removed.],
    [Royal Prince Alfred Hospital samples with black background, markers removed.],
  ),
) <prince_alfred_black_manual_samples>

#let bg_entropy_csv = csv(
  "../Notebooks/results/metrics/entropy_comparison_prince_alfred_black_summary.csv",
  row-type: dictionary,
)

#let model_display_names = (
  ensemble: "Deep Ensembles",
  dropout: "MC Dropout",
  dropconnect: "DropConnect",
  flipout: "Flipout",
  duq: "DUQ",
)

#let model_order = ("ensemble", "dropout", "dropconnect", "flipout", "duq")

// Color for entropy delta: negative = red, positive = green
// Uses same color endpoints as uncertainty-color/inverted-uncertainty-color
#let delta-color(val, max-abs: 0.4) = {
  let v = float(val)
  let t = 1.0 - calc.min(calc.abs(v) / max-abs, 1.0)
  if v < 0 {
    rgb(
      int(255 * t + 185 * (1 - t)),
      int(255 * t + 28 * (1 - t)),
      int(255 * t + 28 * (1 - t)),
    )
  } else if v > 0 {
    rgb(
      int(255 * t + 21 * (1 - t)),
      int(255 * t + 128 * (1 - t)),
      int(255 * t + 61 * (1 - t)),
    )
  } else {
    white
  }
}

#let bg_fmt_delta(val) = {
  let v = calc.round(float(val), digits: 3)
  let s = if v >= 0 { "+" } else { "" }
  s + str(v)
}

#let bg_entropy_manual_csv = csv(
  "../Notebooks/results/metrics/entropy_comparison_prince_alfred_black_manual_summary.csv",
  row-type: dictionary,
)

#let fmt_acc_delta(v) = {
  let pct = calc.round(v * 100, digits: 1)
  let s = if pct >= 0 { "+" } else { "" }
  s + str(pct) + "%"
}

#full_width[
  #figure(
    {
      show table.cell: it => {
        if it.x == 0 or it.y == 0 {
          set text(style: "italic")
          it
        } else {
          it
        }
      }

      table(
        columns: (auto, 1fr, 1fr, 1fr, 1fr, 1fr),
        stroke: none,
        align: (left, right, right, right, right, right),
        inset: (x, y) => if x == 0 { (left: 0pt, right: 8pt, top: 5pt, bottom: 5pt) } else { 5pt },
        table.hline(y: 1),
        [],
        [Orig. entropy],
        [Black bg \ Δ entropy],
        [No markers \ Δ entropy],
        [Black bg \ Δ accuracy],
        [No markers \ Δ accuracy],
        ..model_order
          .map(m => {
            let row_auto = bg_entropy_csv.find(r => r.at("model") == m)
            let row_manual = bg_entropy_manual_csv.find(r => r.at("model") == m)
            let h1_orig = calc.round(float(row_auto.at("head1_orig_mean")), digits: 3)
            let h1_auto_diff = row_auto.at("head1_diff_mean")
            let h1_manual_diff = row_manual.at("head1_diff_mean")
            let h1_acc_auto = float(row_auto.at("h1_acc_diff"))
            let h1_acc_manual = float(row_manual.at("h1_acc_diff"))
            (
              table.cell()[#model_display_names.at(m)],
              table.cell()[#h1_orig],
              table.cell(fill: delta-color(h1_auto_diff))[#bg_fmt_delta(h1_auto_diff)],
              table.cell(fill: delta-color(h1_manual_diff))[#bg_fmt_delta(h1_manual_diff)],
              table.cell(fill: delta-color(str(h1_acc_auto), max-abs: 0.3))[#fmt_acc_delta(h1_acc_auto)],
              table.cell(fill: delta-color(str(h1_acc_manual), max-abs: 0.3))[#fmt_acc_delta(h1_acc_manual)],
            )
          })
          .flatten(),
      )
    },
    caption: flex-caption(
      [Binary head (H1): mean predictive entropy and accuracy changes on 16 Royal Prince Alfred Hospital images after background replacement. "Black bg" = white background replaced with black, "No markers" = black background with measurement markers also removed. Δ = change from original. Green shading indicates improvement (lower entropy or higher accuracy), red indicates degradation.],
      [Binary head (H1) entropy and accuracy changes after background replacement.],
    ),
  ) <bg_entropy_comparison_h1>
]

#full_width[
  #figure(
    {
      show table.cell: it => {
        if it.x == 0 or it.y == 0 {
          set text(style: "italic")
          it
        } else {
          it
        }
      }

      table(
        columns: (auto, 1fr, 1fr, 1fr, 1fr, 1fr),
        stroke: none,
        align: (left, right, right, right, right, right),
        inset: (x, y) => if x == 0 { (left: 0pt, right: 8pt, top: 5pt, bottom: 5pt) } else { 5pt },
        table.hline(y: 1),
        [],
        [Orig. entropy],
        [Black bg \ Δ entropy],
        [No markers \ Δ entropy],
        [Black bg \ Δ accuracy],
        [No markers \ Δ accuracy],
        ..model_order
          .map(m => {
            let row_auto = bg_entropy_csv.find(r => r.at("model") == m)
            let row_manual = bg_entropy_manual_csv.find(r => r.at("model") == m)
            let h2_orig = calc.round(float(row_auto.at("head2_orig_mean")), digits: 3)
            let h2_auto_diff = row_auto.at("head2_diff_mean")
            let h2_manual_diff = row_manual.at("head2_diff_mean")
            let h2_acc_auto = float(row_auto.at("h2_acc_diff"))
            let h2_acc_manual = float(row_manual.at("h2_acc_diff"))
            (
              table.cell()[#model_display_names.at(m)],
              table.cell()[#h2_orig],
              table.cell(fill: delta-color(h2_auto_diff))[#bg_fmt_delta(h2_auto_diff)],
              table.cell(fill: delta-color(h2_manual_diff))[#bg_fmt_delta(h2_manual_diff)],
              table.cell(fill: delta-color(str(h2_acc_auto), max-abs: 0.3))[#fmt_acc_delta(h2_acc_auto)],
              table.cell(fill: delta-color(str(h2_acc_manual), max-abs: 0.3))[#fmt_acc_delta(h2_acc_manual)],
            )
          })
          .flatten(),
      )
    },
    caption: flex-caption(
      [Multiclass head (H2): mean predictive entropy and accuracy changes on 16 Royal Prince Alfred Hospital images after background replacement. "Black bg" = white background replaced with black, "No markers" = black background with measurement markers also removed. Δ = change from original. Green shading indicates improvement (lower entropy or higher accuracy), red indicates degradation.],
      [Multiclass head (H2) entropy and accuracy changes after background replacement.],
    ),
  ) <bg_entropy_comparison_h2>
]

Replacing the white background reduces predictive entropy for the binary head across all models, and for four of five models on the multiclass head. The exception is Deep Ensembles, whose multiclass entropy slightly increases after background replacement. Despite the overall reduction in uncertainty, accuracy changes are mixed and show no clear trend in either direction, though the small sample size (n=16, where a single changed prediction shifts accuracy by 6.3 percentage points) limits the conclusions that can be drawn from the accuracy results. The increased uncertainty on this data source is not just because of the white background or measurement markers. Other differences in imaging equipment and clinical protocol likely also play a role.

=== Skin Type Analysis

Fitzpatrick skin type shows a large marginal effect on model uncertainty in the univariate ANOVA (η² = 0.182), though it was excluded from the multivariate regression due to low coverage (15% of samples). All subsequent conditioning analyses in this section were restricted to this subset. While sufficient for statistical analysis, the limited coverage may affect generalizability to the full dataset.

As @skintype_entropy_violin_h1 and @skintype_entropy_violin_h2 show, darker skin types (V--VI) show lower predictive entropy than lighter types (I--IV). This is counter-intuitive given that darker skin is known to be more challenging for deep learning methods @grohEvaluatingDeepNeural2021. The violin plots show only Deep Ensembles for clarity; per-method versions of the same plots, confirming that the pattern holds for all five UQ methods, are in @skintype_entropy_per_method_appendix. Detailed performance metrics are provided in @skintype_performance_appendix and visual examples in @skintype_samples_appendix.

#pagebreak()

#margin_note([
  #pad(
    top: 11mm,
    skin_types
      .rev()
      .enumerate()
      .map(((i, label)) => (
        box(
          fill: skin_palette.rev().at(i).transparentize(70%),
          stroke: skin_palette.rev().at(i),
          width: 0.8em,
          height: 0.8em,
          baseline: 15%,
        )
          + h(0.4em)
          + label
      ))
      .join([\  ]),
  )])

#pad(
  left: 1mm,
  grid(columns: (53mm, 53mm), gutter: 8mm)[
    #figure(
      {
        let ys = range(skin_types.len())
        let plots = ()
        for (idx, label) in skin_types.enumerate() {
          let values = distributions_head1.at(idx)
          if values.len() == 0 {
            continue
          }
          plots.push(
            lq.hviolin(
              values,
              y: (ys.at(idx),),
              width: 0.6,
              color: skin_palette.at(idx),
            ),
          )
        }

        lq.diagram(
          height: 55mm,
          width: 53mm,
          xlabel: "Predictive Entropy",
          xlim: (-0.1, 1.0),
          yaxis: (format-ticks: none),
          ..plots,
        )
      },
      caption: [Predictive entropy by Fitzpatrick skin type, binary head (H1), Ensemble.],
    ) <skintype_entropy_violin_h1>
  ][
    #figure(
      {
        let ys = range(skin_types.len())
        let plots = ()
        let ys = range(skin_types.len())
        let plots = ()
        for (idx, label) in skin_types.enumerate() {
          let values = distributions_head2.at(idx)
          if values.len() == 0 {
            continue
          }
          plots.push(
            lq.hviolin(
              values,
              y: (ys.at(idx),),
              width: 0.6,
              color: skin_palette.at(idx),
            ),
          )
        }

        lq.diagram(
          height: 55mm,
          width: 53mm,
          xlabel: "Predictive Entropy",
          xlim: (-0.1, 2.0),
          yaxis: (format-ticks: none),
          ..plots,
        )
      },
      caption: [Predictive entropy by Fitzpatrick skin type, multiclass head (H2), Ensemble.],
    ) <skintype_entropy_violin_h2>
  ],
)

==== Class Distribution by Skin Type

Every Fitzpatrick group contributes more than one hundred lesions (see @distribution_skin_type_test_set), so the pattern is not simply an artifact of small sample sizes in the test set. However, the class composition within each skin tone varies widely: as @h1_distribution_skintype shows, darker skin types have far fewer malignant samples, with skin type VI having zero malignant cases. Exact counts are provided in the Appendix in @skintype_summary_table. This difference fits with known epidemiological data on skin cancer incidence by skin type (1.0 per 100,000 for dark skin tones, compared to 23.5 per 100,000 for light skin tones) @collinsRacialDifferencesSurvival2011.

#figure(
  {
    let malignant_pct = h1_pct.map(row => calc.round(float(row.at("Malignant", default: "0")), digits: 1))
    color-table(
      (malignant_pct,),
      ("Malignant %",),
      skin_types,
      0.0,
      55.0,
      color-fn: white-to-green-color,
    )
  },
  caption: [Malignant rate by Fitzpatrick skin type, binary head (H1).],
)<h1_distribution_skintype>

The correlation between malignant sample rate and mean predictive entropy per skin type is near-perfect ($r = 0.98$ for both heads, though computed on only six skin types). This suggests that entropy differences are mostly driven by malignant prevalence rather than skin type itself.

Regression analysis (now performed with skin type data, so $N = 821$ samples) shows that `diagnosis_confirm_type` is the strongest confound. For the binary head, controlling for confirmation type alone reduces skin type's partial $eta^2$ from 0.03--0.19 to below 0.025 for all models, an 82--98% reduction. For the multiclass head, the reduction is similarly large for most models (92--99% for DropConnect, Dropout, and Deep Ensembles) but weaker for DUQ (67%) and Flipout (77%), suggesting these architectures capture additional skin-type-related variance beyond what confirmation type explains.

Adding the class label (`diagnosis_1`) instead shows more variable results: reductions range from 33% (Flipout) to 90% (Dropout), with most models in the 49--59% range.

#figure(
  {
    let models = ("ensemble", "dropout", "dropconnect", "flipout", "duq")
    let model_labels = ([Deep Ensembles], [MC Dropout], [DropConnect], [Flipout], [DUQ])
    let xs = range(skin_types.len())
    let offsets = (-0.32, -0.16, 0, 0.16, 0.32)
    let bar_width = 0.14

    let get_benign_entropy = model => {
      skin_types.map(st => {
        let row = entropy_within_diag.find(r => (
          r.at("model") == model and r.at("skin_type") == st and r.at("diagnosis") == "benign"
        ))
        if row != none { float(row.at("mean_entropy")) } else { 0 }
      })
    }

    pad(left: 3.8cm)[
      #lq.diagram(
        height: 50mm,
        width: 100mm,
        legend: (position: left + top, dx: 103%, dy: -1mm, stroke: none),
        ylabel: "Mean Predictive Entropy",
        xlabel: "Fitzpatrick Skin Type (Benign Only)",
        xaxis: (
          ticks: skin_types
            .enumerate()
            .map(((i, st)) => {
              let row = entropy_within_diag.find(r => (
                r.at("model") == "ensemble" and r.at("skin_type") == st and r.at("diagnosis") == "benign"
              ))
              let n = if row != none { row.at("n_samples") } else { "0" }
              (i, [#st \ #text(size: 0.8em, fill: gray)[N=#n]])
            }),
          subticks: none,
        ),
        ..models
          .enumerate()
          .map(((mi, model)) => {
            let vals = get_benign_entropy(model)
            lq.bar(
              xs,
              vals,
              offset: offsets.at(mi),
              width: bar_width,
              label: model_labels.at(mi),
              fill: uq_model_palette.at(mi),
            )
          })
          .flatten(),
      )
    ]
  },
  caption: flex-caption(
    [Mean predictive entropy by Fitzpatrick skin type for benign-only samples across all UQ methods. Types V and VI consistently show the lowest entropy.],
    [Benign-only entropy by skin type.],
  ),
) <benign_entropy_by_skintype>

If class distribution were the only reason for entropy differences across skin types, controlling for diagnosis should remove the pattern. As @benign_entropy_by_skintype shows, this is not entirely the case: within benign-only samples, types V and VI still show the _lowest_ entropy across all five UQ methods, while type II shows the highest. The pattern is consistent across all methods, though absolute entropy values differ. Flipout and Deep Ensembles show higher entropy overall than MC Dropout and DropConnect, consistent with earlier findings.

This pattern does not by itself prove shortcut learning (the network learning that _dark skin = benign_). If darker skin types contain a higher proportion of visually distinctive or easier-to-classify benign lesions, lower entropy could arise without any direct reliance on skin tone. Differences in acquisition conditions, clinical workflow, or dataset composition across skin types could also contribute.

But since entropy differences remain even after conditioning on diagnosis, class prevalence alone does not fully explain the effect. Other possible explanations include subtype imbalance and visual differences that affect classification difficulty. The model may also have learned associations between skin appearance and diagnostic categories.

Controlling for diagnosis confirmation type removes most of skin type's statistical effect, but since confirmation type is not an input to the model, this adjustment on its own cannot tell us whether the model relies on skin-related visual cues.

#pagebreak()

==== Validation on Indeterminate Samples

To further verify that models are not relying on a skin-color shortcut, we compare entropy between the main test set and the indeterminate set#numbered_margin_note[There were no indeterminate samples for skin type VI, so for this skin type no analysis could be done.] (clinically ambiguous cases) per skin type. If the models were associating dark skin with benign predictions instead of looking at lesion features, they should remain confident even on indeterminate dark-skinned samples.

// All skin types. VI has no indeterminate samples and will render as a dash.
#let indet_skin_types = ("I", "II", "III", "IV", "V", "VI")

#margin_figure(
  {
    let models = ("ensemble", "dropout", "dropconnect", "flipout", "duq")
    let model_labels = ("ENS", "DO", "DC", "FLP", "DUQ")
    let threshold = 1.0
    let max-green = 10.0

    // Style headers as italic (matching color-table)
    show table.cell: it => {
      if it.y <= 1 or it.x == 0 {
        set text(style: "italic")
        it
      } else {
        it
      }
    }

    table(
      columns: (auto,) + (1.04cm,) * 10,
      align: (x, _) => if x == 0 { left } else { right },
      stroke: none,
      inset: (x, y) => if x == 0 { (left: 0pt, right: 8pt, top: 5pt, bottom: 5pt) } else { 5pt },
      // Top header row: model names spanning 2 columns each
      table.cell(rowspan: 2, align: bottom)[],
      ..model_labels.map(m => table.cell(colspan: 2, align: bottom)[#text(style: "italic")[#m]]).flatten(),
      // Second header row: H1/H2 (binary/multiclass) for each model
      ..(("H1", "H2") * 5).map(h => [#h]),
      table.hline(),
      // Data rows
      ..indet_skin_types
        .map(st => {
          let row_data = ([#st],)
          for model in models {
            let data_row = cross_model_ratio.find(r => r.at("model") == model and r.at("skin_type") == st)
            let h1_val = if data_row != none { to_float(data_row.at("h1_ratio")) } else { none }
            let h2_val = if data_row != none { to_float(data_row.at("h2_ratio")) } else { none }

            if h1_val != none {
              row_data.push(table.cell(fill: ratio-color(h1_val, threshold, max-green))[#calc.round(h1_val, digits: 1)])
            } else {
              row_data.push(table.cell()[—])
            }
            if h2_val != none {
              row_data.push(table.cell(fill: ratio-color(h2_val, threshold, max-green))[#calc.round(h2_val, digits: 1)])
            } else {
              row_data.push(table.cell()[—])
            }
          }
          row_data
        })
        .flatten(),
    )
  },
  caption: flex-caption(
    [
      Entropy ratio (indeterminate / test) by skin type across all models.

      Values above 1.0 (green) mean higher uncertainty on difficult cases. Values below 1.0 (red) suggest overconfidence.
    ],
    [Entropy ratio (indeterminate / test) by skin type across all models.],
  ),
) <indet_entropy_ratio>

As @indet_entropy_ratio shows, entropy ratios are above 1.0 for all skin types and models where adequate sample sizes exist, and models increase uncertainty on difficult cases. The one exception is DropConnect on skin type V for the multiclass head (ratio 0.4×). For skin types I--III, where indeterminate sample sizes are sufficient ($n = 35$, $217$, and $108$ respectively), all models consistently show elevated entropy on difficult cases.

For darker skin types, however, the indeterminate sample sizes are very small (type IV: $n = 13$, type V: $n = 3$) or entirely absent (type VI: $n = 0$), meaning that for the populations where this test matters most, we cannot draw firm conclusions. For example, the DropConnect ratio of 0.4× for skin type V is based on only three indeterminate samples, so it is unclear whether this reflects a genuine overconfidence issue or random variation due to small sample size.

Despite this limitation, for skin types with enough data, all models do increase uncertainty on indeterminate cases. If models relied primarily on skin tone as a shortcut, indeterminate dark-skinned samples would show limited entropy increases. The observed increases for types IV and V, while based on small samples, are consistent with difficulty-driven rather than shortcut-driven behavior.

The near-absence of malignant dark-skinned cases and the small indeterminate samples for these populations mean that detection performance and uncertainty calibration for darker skin types have not been tested well enough. Together with the conditioning analysis (where controlling for confirmation type removes most of skin type's univariate effect), the evidence suggests that entropy differences across skin types primarily reflect case characteristics rather than a skin-color shortcut, but this conclusion cannot be confirmed for the underrepresented populations.

#pagebreak()

== Difficult Sample Analysis <sample_difficulty>

#let difficulty_tier_dist = csv(metrics_dir + "/sample_difficulty_tier_distribution.csv", row-type: dictionary)
#let difficulty_metrics = csv(metrics_dir + "/sample_difficulty_metrics_by_tier.csv", row-type: dictionary)
#let difficulty_correlation = csv(metrics_dir + "/sample_difficulty_entropy_rank_correlation.csv", row-type: dictionary)
#let risk_coverage_curves = csv(metrics_dir + "/risk_coverage_curves.csv", row-type: dictionary)
#let risk_coverage_aurc = csv(metrics_dir + "/risk_coverage_aurc.csv", row-type: dictionary)


How do different UQ methods handle the most difficult individual cases? Population-level calibration does not guarantee good behavior on the hardest samples.

=== Identifying Difficult Samples

We define sample difficulty using cross-model misclassification. For each sample, we aggregate predictions from each of the five UQ methods (averaging across their 5 runs each), compute the predicted class, and compare against the ground truth. The _difficulty tier_ is the number of methods (0--5) that misclassify the sample. Tier~0 means all methods classify correctly, tier~5 means all methods fail.

#figure(
  {
    let test_h1 = difficulty_tier_dist.filter(r => r.at("dataset") == "test_set" and r.at("head") == "head1")
    let test_h2 = difficulty_tier_dist.filter(r => r.at("dataset") == "test_set" and r.at("head") == "head2")

    table(
      columns: (auto, 1fr, 1fr),
      align: (left, right, right),
      stroke: none,
      inset: 5pt,
      [_Tier_], [_Binary (H1)_], [_Multiclass (H2)_],
      table.hline(),
      ..range(6)
        .map(tier => {
          let t_h1 = test_h1.find(r => r.at("tier") == str(tier))
          let t_h2 = test_h2.find(r => r.at("tier") == str(tier))
          (
            [#tier],
            if t_h1 != none [#t_h1.at("n_samples") (#fmt(to_float(t_h1.at("fraction")) * 100, decimals: 1)%)] else [—],
            if t_h2 != none [#t_h2.at("n_samples") (#fmt(to_float(t_h2.at("fraction")) * 100, decimals: 1)%)] else [—],
          )
        })
        .flatten(),
    )
  },
  caption: flex-caption(
    [Difficulty tier distribution on the test set. Each tier represents the number of UQ methods (out of 5) that misclassify the sample.],
    [Difficulty tier distribution on the test set.],
  ),
) <difficulty_tier_dist>

@difficulty_tier_dist shows the distribution of samples across difficulty tiers. The test set is dominated by easy samples: 79.9% are in tier~0 for the binary head (all methods correct) and 69.0% for the multiclass head. At the other extreme, only 2.4% and 3.5% of samples are universally misclassified (tier~5).

@difficult_extreme_samples and @easy_extreme_samples show what these two extremes look like in practice on the binary head. The difficult row holds tier-5 samples (universally misclassified), one per consolidated lesion type, picked from the highest-entropy band. The easy row holds tier-0 samples, the lowest-entropy correct prediction in each class.

#figure(
  grid(
    columns: 5,
    gutter: 2mm,
    ..("ISIC_0013337", "ISIC_0059994", "ISIC_0031852", "ISIC_5534730", "ISIC_0777268").map(id => img_tile(
      "images/difficulty_extreme_samples/difficult/" + id + ".jpg",
    )),
  ),
  caption: flex-caption(
    [Binary head (H1) difficult samples (tier~5): one per lesion type, picked from the highest-entropy band. Left to right: Benign, Malignant Non-Epidermal, Malignant Epidermal, Melanoma, Other.],
    [Difficult samples, binary head (H1).],
  ),
) <difficult_extreme_samples>

#figure(
  grid(
    columns: 5,
    gutter: 2mm,
    ..("ISIC_0008747", "ISIC_6362082", "ISIC_9308533", "ISIC_0070463", "ISIC_4190398").map(id => img_tile(
      "images/difficulty_extreme_samples/easy/" + id + ".jpg",
    )),
  ),
  caption: flex-caption(
    [Binary head (H1) easy samples (tier~0): the lowest-entropy correct prediction in each lesion type. Left to right: Benign, Malignant Non-Epidermal, Malignant Epidermal, Melanoma, Other.],
    [Easy samples, binary head (H1).],
  ),
) <easy_extreme_samples>

=== Method Comparison on Difficult Samples

==== Metrics by Difficulty Tier

The question is whether UQ methods increase their uncertainty on harder samples. To avoid circularity where a method's own predictions influence the tier definition used to evaluate it, we use _leave-one-model-out_ (LOMO) tiers: when evaluating method~$X$, each sample's tier is the number of the _other_ four methods that misclassify it (range 0--4). For instance, when evaluating Deep Ensembles, each sample's difficulty tier is computed from the other four methods' predictions only.

This removes the direct self-reference, though as the entropy rank correlations in @difficulty_entropy_correlation will show, prediction patterns are highly correlated across methods, so the remaining four methods are not fully independent. The leave-one-model-out approach reduces circularity but does not fully eliminate it.

@difficulty_metrics_by_tier shows mean entropy and the overconfidence rate (fraction of misclassified samples with confidence > 0.9) stratified by LOMO difficulty tier.

#margin_note([
  #pad(
    top: 11mm,
    uq_model_labels
      .rev()
      .enumerate()
      .map(((i, label)) => (
        box(
          fill: uq_model_palette.rev().at(i).transparentize(70%),
          stroke: uq_model_palette.rev().at(i),
          width: 0.8em,
          height: 0.8em,
          baseline: 15%,
        )
          + h(0.4em)
          + label
      ))
      .join([\  ]),
  )])

#figure(
  {
    let methods = uq_model_run_types
    let tiers = range(5)
    let marks = ("o", "s", "^", "d", "x")
    let tier_ticks = tiers.map(t => (t, str(t)))

    let make_plots = (metric, scale: 1.0) => {
      methods
        .enumerate()
        .map(((idx, method)) => {
          lq.plot(
            tiers,
            tiers.map(tier => {
              let row = difficulty_metrics.find(r => (
                r.at("method") == method and r.at("head") == "head1" and r.at("tier") == str(tier)
              ))
              if row != none { to_float(row.at(metric)) * scale } else { 0 }
            }),
            mark: marks.at(idx),
            mark-size: 3pt,
            color: uq_model_palette.at(idx),
            stroke: uq_model_palette.at(idx) + 1pt,
          )
        })
    }

    grid(
      columns: (53mm, 53mm),
      column-gutter: 8mm,
      row-gutter: 6mm,
      lq.diagram(
        height: 40mm,
        width: 40mm,
        ylabel: "Mean Entropy",
        xlabel: "LOMO Difficulty Tier",
        xlim: (-0.3, 4.3),
        xaxis: (ticks: tier_ticks, subticks: none),
        ..make_plots("mean_entropy"),
      ),
      lq.diagram(
        height: 40mm,
        width: 40mm,
        ylabel: "OC Rate (%)",
        xlabel: "LOMO Difficulty Tier",
        xlim: (-0.3, 4.3),
        ylim: (-5, 105),
        xaxis: (ticks: tier_ticks, subticks: none),
        ..make_plots("overconfidence_rate", scale: 100),
      ),
    )
  },
  caption: flex-caption(
    [Binary head (H1) mean entropy and overconfidence rate (OC) by leave-one-method-out difficulty tier per UQ method. OC is the fraction of predictions that are confidently wrong.],
    [Binary head (H1) metrics by difficulty tier.],
  ),
) <difficulty_metrics_by_tier>

#pagebreak()

Mean entropy increases with tier across all methods, indicating that methods generally assign higher uncertainty to cases that more approaches fail on. Low entropy in itself is not necessarily bad if the network is correctly confident, but the overconfidence rate measures how often models are confidently wrong.

Deep Ensembles and DUQ show the strongest absolute entropy response to difficulty, while MC~Dropout and DropConnect operate at much lower absolute levels, which is consistent with the entropy distributions shown earlier in @entropy_violin_indet_h1. Flipout's entropy is less responsive in relative terms because its baseline is already high.

Entropy drops at tier~4 for all methods despite these being the hardest cases. This probably happens because tier-3 and tier-4 cases fail for different reasons: tier-3 cases show ambiguity (one other method still succeeds), while tier-4 cases are those where a strong misleading signal causes all other methods to fail. As shown in @difficulty_entropy_correlation, entropy rankings are highly correlated across methods, so tier~4 selects for systematically misleading samples rather than ambiguous ones. The overconfidence rates support this, since they peak at tier~4. Models are not uncertain on these cases, but confidently wrong.

DropConnect and Dropout are still very overconfident even at high difficulty tiers, while Deep Ensembles and Flipout maintain substantially lower rates. Deep Ensembles again performs well: its entropy responds to difficulty while maintaining lower overconfidence rates at the hardest tiers. The full per-method, per-tier breakdown, including sample counts, accuracy, and mean confidence in addition to the entropy and overconfidence values plotted above, is given in @difficulty_metrics_by_tier_appendix.

==== Selective Prediction (Risk-Coverage Analysis)

A practical question remains: _"If we use each method's entropy to decide which cases to defer to a human expert, which method reduces errors the most?"_

This is captured by the risk-coverage curve (@risk_coverage_head1 and @risk_coverage_head2). For each method, samples are sorted by ascending entropy (most confident first). At each coverage level (the fraction of samples the model retains rather than deferring) we compute the error rate on the retained set. At low coverage only the most confident predictions are kept, so the error rate should be near zero. As coverage increases and less-confident samples are included, the error rate rises. If a method's uncertainty is well-calibrated, errors are concentrated among the high-entropy samples and the curve rises slowly, meaning the model can retain most cases before errors appear. When calibration is poor, errors are spread across entropy levels and the curve rises faster.

#pad(
  left: 0mm,
  grid(columns: (1fr, 1fr), gutter: 8mm)[
    #figure(
      pad(
        left: -9mm,
        {
          let methods = uq_model_run_types
          lq.diagram(
            height: 43mm,
            width: 53mm,
            ylabel: "Error Rate",
            xlabel: "Coverage",
            xlim: (0, 1.05),
            ylim: (-0.01, 0.25),
            ..methods
              .enumerate()
              .map(((idx, method)) => {
                let curve_data = risk_coverage_curves.filter(r => (
                  r.at("method") == method and r.at("head") == "head1"
                ))
                lq.plot(
                  curve_data.map(r => float(r.at("coverage"))),
                  curve_data.map(r => float(r.at("error_rate"))),
                  mark: none,
                  color: uq_model_palette.at(idx),
                  stroke: uq_model_palette.at(idx) + 1pt,
                )
              })
              .flatten(),
          )
        },
      ),
      caption: [Risk-coverage, binary head (H1).],
    ) <risk_coverage_head1>
  ][
    #figure(
      pad(
        left: 43mm,
        top: 1mm,
        {
          let methods = uq_model_run_types
          lq.diagram(
            height: 43mm,
            width: 53mm,
            legend: (position: left + top, dx: 110%, dy: -1mm, stroke: none),
            ylabel: none,
            xlabel: "Coverage",
            xlim: (0, 1.05),
            ylim: (-0.01, 0.25),
            yaxis: (format-ticks: none),
            ..methods
              .enumerate()
              .map(((idx, method)) => {
                let curve_data = risk_coverage_curves.filter(r => (
                  r.at("method") == method and r.at("head") == "head2"
                ))
                lq.plot(
                  curve_data.map(r => float(r.at("coverage"))),
                  curve_data.map(r => float(r.at("error_rate"))),
                  mark: none,
                  color: uq_model_palette.at(idx),
                  stroke: uq_model_palette.at(idx) + 1pt,
                  label: uq_model_labels.at(idx),
                )
              })
              .flatten(),
          )
        },
      ),
      caption: [Risk-coverage, multiclass head (H2).],
    ) <risk_coverage_head2>
  ],
)

The Area Under the Risk-Coverage Curve (AURC) summarizes this in a single number: lower AURC means better alignment between the method's uncertainty and its errors. Two methods can have identical accuracy and identical average entropy, yet very different AURCs. The one with lower AURC is better at using its entropy to separate correct from incorrect predictions.

#figure(
  {
    let methods = uq_model_run_types
    let aurc_data = methods.map(method => {
      ("head1", "head2").map(head => {
        let row = risk_coverage_aurc.find(r => (
          r.at("method") == method and r.at("head") == head
        ))
        if row != none { calc.round(float(row.at("aurc")), digits: 4) } else { none }
      })
    })

    color-table(
      aurc_data,
      uq_model_labels,
      ("Binary (H1)", "Multiclass (H2)"),
      0.00,
      0.08,
      color-fn: white-to-red-color,
    )
  },
  caption: flex-caption(
    [Area Under the Risk-Coverage Curve (AURC) per method for both classification heads. Lower values (lighter) indicate better alignment between the method's uncertainty and its errors.],
    [AURC per UQ method.],
  ),
) <risk_coverage>

As @risk_coverage shows, method ranking depends on the classification head. For the binary head (H1), Deep Ensembles achieve the lowest AURC (0.012), followed closely by DropConnect (0.014) and MC Dropout (0.014). DUQ is moderately worse (0.017), and Flipout is far worse (0.034). For the multiclass head (H2), DropConnect and MC Dropout lead (both \~0.02), with Deep Ensembles slightly behind (0.022). DUQ (0.031) and Flipout (0.075) fall further behind. Flipout's poor AURC on both heads means its entropy signal is least useful for triage.

==== Entropy Rank Correlation

If different UQ methods assign high entropy to the same samples, this suggests the difficulty is in the samples themselves and not a method-specific artifact. @difficulty_entropy_correlation shows the Spearman rank correlation of per-sample entropy between all method pairs.

#figure(
  {
    let methods = ("dropconnect", "dropout", "duq", "ensemble", "flipout")
    let method_labels = ("DC", "DO", "DUQ", "ENS", "FLP")

    let matrix_data = methods
      .enumerate()
      .map(((i, m_row)) => {
        methods
          .enumerate()
          .map(((j, m_col)) => {
            if i == j {
              1.0
            } else {
              let row = difficulty_correlation.find(r => (
                r.at("head") == "head1"
                  and (
                    (r.at("method_a") == m_row and r.at("method_b") == m_col)
                      or (r.at("method_a") == m_col and r.at("method_b") == m_row)
                  )
              ))
              if row != none {
                to_float(row.at("spearman_rho"), decimals: 2)
              } else {
                none
              }
            }
          })
      })

    color-table(
      matrix_data,
      method_labels,
      method_labels,
      0.5,
      1.0,
      color-fn: white-to-green-color,
    )
  },
  caption: flex-caption(
    [Spearman rank correlation of per-sample predictive entropy between UQ method pairs, binary head (H1). All correlations are positive and statistically significant ($p < 0.001$). Methods largely agree on which samples are difficult. The strongest agreement is between DUQ and Deep Ensembles ($rho = 0.91$).],
    [Entropy rank correlation between method pairs, binary head (H1).],
  ),
) <difficulty_entropy_correlation>

All pairwise correlations are positive and highly significant ($p < 0.001$), ranging from 0.54 (DropConnect--Flipout) to 0.91 (DUQ--Ensembles). The strong agreement suggests that sample difficulty is largely a property of the samples themselves, not a method-specific artifact. All methods find roughly the same samples hard. Flipout and DropConnect have somewhat lower correlations with other methods, which suggests they pick up on slightly different signals.

=== Qualitative Examples (Appendix)

This thesis does not provide expert dermatologic interpretation of individual lesions. For transparency, @difficulty_visual_examples_appendix provides image grids for (i) universally misclassified samples (tier~5), (ii) dangerous overconfidence cases (wrong with high confidence), and (iii) appropriately cautious cases (right with high uncertainty), annotated with the dataset labels and recorded confirmation types.

The recorded confirmation types provide additional context for interpreting these qualitative examples. Among the tier~5 benign samples shown in the appendix grids, 87% were confirmed by histopathology, nearly triple the 32% base rate for benign samples in the test set overall.

In the "dangerous overconfidence" category, all benign samples were histopathology-confirmed. Even when the final label is benign, many of these lesions were clinically suspicious enough to warrant biopsy, which fits with these being challenging cases.

For per-class context, @per_class_entropy_appendix in the appendix shows, for each lesion type, the highest- and lowest-entropy samples side by side. Readers with dermatology expertise can use these to judge whether the model's uncertainty corresponds to visual ambiguity in each class.

The figures can also surface non-clinical patterns. Every sample in the Benign low-entropy row, for example, contains a clinical measurement marker. The model may have learned to associate markers with "benign" rather than lesion features alone.

#pagebreak()

== Chapter Summary <results_summary>

The tables and figure below consolidate the per-method, per-head numbers from this chapter.

=== Predictive Metrics

@summary_metrics_head1 and @summary_metrics_head2 collect the predictive metrics from section 4.1: accuracy, Expected Calibration Error (ECE), AUROC of confidence (AUC), and Area Under the Risk--Coverage Curve (AURC). The first three metrics are from @overall_performance_head1 and @overall_performance_head2, AURC comes from @risk_coverage.

#figure(
  {
    let summary_data = (
      (
        to_float(baseline_test_head1.accuracy),
        to_float(baseline_test_head1.ece),
        to_float(baseline_test_head1.auroc_confidence),
        lookup_aurc("baseline", "head1"),
      ),
      (
        to_float(ensemble_test_head1.accuracy),
        to_float(ensemble_test_head1.ece),
        to_float(ensemble_test_head1.auroc_confidence),
        lookup_aurc("ensemble", "head1"),
      ),
      (
        to_float(dropout_test_head1.accuracy),
        to_float(dropout_test_head1.ece),
        to_float(dropout_test_head1.auroc_confidence),
        lookup_aurc("dropout", "head1"),
      ),
      (
        to_float(dropconnect_test_head1.accuracy),
        to_float(dropconnect_test_head1.ece),
        to_float(dropconnect_test_head1.auroc_confidence),
        lookup_aurc("dropconnect", "head1"),
      ),
      (
        to_float(flipout_test_head1.accuracy),
        to_float(flipout_test_head1.ece),
        to_float(flipout_test_head1.auroc_confidence),
        lookup_aurc("flipout", "head1"),
      ),
      (
        to_float(duq_test_head1.accuracy),
        to_float(duq_test_head1.ece),
        to_float(duq_test_head1.auroc_confidence),
        lookup_aurc("duq", "head1"),
      ),
    )

    color-table(
      summary_data,
      model_labels,
      ("Accuracy", "ECE", "AUC", "AURC"),
      (0.85, 0.00, 0.82, 0.00),
      (0.93, 0.08, 0.91, 0.04),
      color-fn: (
        white-to-green-color,
        white-to-red-color,
        white-to-green-color,
        white-to-red-color,
      ),
    )
  },
  caption: flex-caption(
    [Summary of test-set metrics for the binary head (H1). AUC is the AUROC of confidence (@overall_performance_head1). AURC is the Area Under the Risk--Coverage Curve (@risk_coverage). It is undefined for the baseline.],
    [Summary of test-set metrics, binary head (H1).],
  ),
) <summary_metrics_head1>

#figure(
  {
    let summary_data = (
      (
        to_float(baseline_test_head2.accuracy),
        to_float(baseline_test_head2.ece),
        to_float(baseline_test_head2.auroc_confidence),
        lookup_aurc("baseline", "head2"),
      ),
      (
        to_float(ensemble_test_head2.accuracy),
        to_float(ensemble_test_head2.ece),
        to_float(ensemble_test_head2.auroc_confidence),
        lookup_aurc("ensemble", "head2"),
      ),
      (
        to_float(dropout_test_head2.accuracy),
        to_float(dropout_test_head2.ece),
        to_float(dropout_test_head2.auroc_confidence),
        lookup_aurc("dropout", "head2"),
      ),
      (
        to_float(dropconnect_test_head2.accuracy),
        to_float(dropconnect_test_head2.ece),
        to_float(dropconnect_test_head2.auroc_confidence),
        lookup_aurc("dropconnect", "head2"),
      ),
      (
        to_float(flipout_test_head2.accuracy),
        to_float(flipout_test_head2.ece),
        to_float(flipout_test_head2.auroc_confidence),
        lookup_aurc("flipout", "head2"),
      ),
      (
        to_float(duq_test_head2.accuracy),
        to_float(duq_test_head2.ece),
        to_float(duq_test_head2.auroc_confidence),
        lookup_aurc("duq", "head2"),
      ),
    )

    color-table(
      summary_data,
      model_labels,
      ("Accuracy", "ECE", "AUC", "AURC"),
      (0.75, 0.00, 0.82, 0.00),
      (0.91, 0.08, 0.91, 0.08),
      color-fn: (
        white-to-green-color,
        white-to-red-color,
        white-to-green-color,
        white-to-red-color,
      ),
    )
  },
  caption: flex-caption(
    [Summary of test-set metrics for the multiclass head (H2). Column definitions match @summary_metrics_head1.],
    [Summary of test-set metrics, multiclass head (H2).],
  ),
) <summary_metrics_head2>

#pagebreak()

=== Uncertainty Behavior

@summary_uq_behavior_head1 and @summary_uq_behavior_head2 describe how each method's uncertainty behaves: its magnitude, its growth on ambiguous samples, and the share that is epistemic. The baseline is excluded since these metrics all require multi-pass predictive entropy.

#let model_labels_uq_with_duq = ("Deep Ensembles", "MC Dropout", "DropConnect", "Flipout", "DUQ")
#let uq_method_keys = ("ensemble", "dropout", "dropconnect", "flipout", "duq")
#let test_metric_dicts = (
  ("head1": ensemble_test_head1, "head2": ensemble_test_head2),
  ("head1": dropout_test_head1, "head2": dropout_test_head2),
  ("head1": dropconnect_test_head1, "head2": dropconnect_test_head2),
  ("head1": flipout_test_head1, "head2": flipout_test_head2),
  ("head1": duq_test_head1, "head2": duq_test_head2),
)
#let indet_metric_dicts = (
  ("head1": ensemble_test_indet_head1, "head2": ensemble_test_indet_head2),
  ("head1": dropout_test_indet_head1, "head2": dropout_test_indet_head2),
  ("head1": dropconnect_test_indet_head1, "head2": dropconnect_test_indet_head2),
  ("head1": flipout_test_indet_head1, "head2": flipout_test_indet_head2),
  ("head1": duq_test_indet_head1, "head2": duq_test_indet_head2),
)

#let uq_behavior_row(idx, head_str) = {
  let test_dict = test_metric_dicts.at(idx).at(head_str)
  let indet_dict = indet_metric_dicts.at(idx).at(head_str)
  let key = uq_method_keys.at(idx)
  let mean_h = to_float(test_dict.mean_predictive_entropy)
  let mean_h_indet = to_float(indet_dict.mean_predictive_entropy)
  let ratio = if mean_h > 0 { calc.round(mean_h_indet / mean_h, digits: 2) } else { none }
  // Epistemic % uses mutual_information / predictive_entropy, undefined for DUQ
  let epist_pct = if key == "duq" {
    none
  } else {
    let mi = to_float(test_dict.mean_mutual_information)
    if mean_h > 0 { calc.round(mi / mean_h * 100, digits: 1) } else { none }
  }
  (mean_h, mean_h_indet, ratio, epist_pct)
}

#full_width[
  #figure(
    {
      let data = range(5).map(i => uq_behavior_row(i, "head1"))
      color-table(
        data,
        model_labels_uq_with_duq,
        ("Mean Entropy", "Indeterminate\nMean Entropy", "Indeterminate ratio", "Epistemic %"),
        (0.00, 0.00, 1.00, 0.00),
        (0.30, 0.50, 5.00, 25.00),
        col-label-max-chars: none,
        color-fn: (
          white-to-green-color,
          white-to-green-color,
          white-to-green-color,
          white-to-green-color,
        ),
      )
    },
    caption: flex-caption(
      [Uncertainty behavior summary for the binary head (H1). Mean Entropy is the mean predictive entropy on the test set. Indeterminate Mean Entropy is the mean on the indeterminate set. Indeterminate ratio is the second divided by the first. Values $> 1$ mean the method is more uncertain on ambiguous samples. Epistemic % is the mutual-information share of total predictive entropy. It is undefined for DUQ.],
      [Uncertainty behavior summary, binary head (H1).],
    ),
  ) <summary_uq_behavior_head1>
]

#full_width[
  #figure(
    {
      let data = range(5).map(i => uq_behavior_row(i, "head2"))
      color-table(
        data,
        model_labels_uq_with_duq,
        ("Mean Entropy", "Indeterminate\nMean Entropy", "Indeterminate ratio", "Epistemic %"),
        (0.00, 0.00, 1.00, 0.00),
        (0.50, 0.90, 5.00, 25.00),
        col-label-max-chars: none,
        color-fn: (
          white-to-green-color,
          white-to-green-color,
          white-to-green-color,
          white-to-green-color,
        ),
      )
    },
    caption: flex-caption(
      [Uncertainty behavior summary for the multiclass head (H2). Column definitions match @summary_uq_behavior_head1.],
      [Uncertainty behavior summary, multiclass head (H2).],
    ),
  ) <summary_uq_behavior_head2>
]

= Discussion & Conclusion

The previous chapter evaluated five UQ methods on classification performance, calibration, uncertainty decomposition, and their response to input characteristics and difficult samples. This chapter summarizes those results, interprets them in the context of existing work, and answers the research questions from the introduction.

== Summary of Findings

=== Model Comparison (Question A)

The five UQ methods show clear trade-offs across predictive performance, calibration, uncertainty estimation, and risk coverage (@overall_performance_head1, @overall_performance_head2). Deep Ensembles, MC Dropout, and DropConnect achieve the highest accuracy on both heads. On the binary task, DUQ performs near the baseline but falls further behind on the multiclass task. Flipout falls behind on both heads.

DUQ's accuracy gap relative to the best-performing method grows from 1.8 percentage points on the binary head to 2.6 on the multiclass head. One possible explanation is that DUQ maps features into a two-dimensional embedding space ($d = 2$), and five centroids sharing this space may leave less room for class separation than two, though alternative embedding dimensions were not tested. The other methods also have a learnable linear layer between the backbone and the output that DUQ lacks. On CIFAR-10 (10 classes), van Amersfoort et al. reported a similar pattern: DUQ's accuracy (93.2%, with gradient penalty) fell below that of Deep Ensembles (95.2%) @van2020uncertainty.

Deep Ensembles are best-calibrated overall, while DropConnect and MC Dropout, despite strong accuracy, show the highest miscalibration (@calibration_curves). DUQ achieves moderate calibration, and Flipout calibrates well on the binary head but degrades on the multiclass head.

MC Dropout and DropConnect perturb a single trained network, so all forward passes explore a region around one local optimum of the loss landscape. Gawlikowski et al. describe this as single-mode evaluation @gawlikowskiSurveyUncertaintyDeep2023. Deep Ensembles trains independent networks from different random initializations, and these can converge to different local optima @gawlikowskiSurveyUncertaintyDeep2023 @lakshminarayananSimpleScalablePredictive. Across multiple benchmarks, studies have found that ensembles produce better-calibrated predictions than MC Dropout @gawlikowskiSurveyUncertaintyDeep2023, and Lakshminarayanan et al. showed that MC Dropout can produce overconfident predictions while deep ensembles are significantly more robust @lakshminarayananSimpleScalablePredictive.

MC Dropout's approximate posterior also has calibration limitations by design. Gal @galUncertaintyDeepLearning notes that the choice of non-linearities and prior over the weights defines an implicit covariance function that may not match the data, and that calibrated estimates require tuning the dropout probability on validation data. In this thesis, the dropout probability ($p = 0.5$) was fixed rather than tuned for calibration, which probably explains some of the miscalibration.

Methods differ in absolute entropy magnitude (@entropy_violin_h1, @entropy_violin_h2) but show consistent relative patterns across input characteristics. All methods appropriately increase entropy on the indeterminate test set (@entropy_violin_indet_h1, @entropy_violin_indet_h2).

For uncertainty disentanglement (@uncertainty_test_head1, @uncertainty_test_head2), DUQ and Flipout are limited. DUQ is deterministic and cannot decompose entropy, though its raw kernel distances do carry out-of-distribution information (see Limitations). Flipout and DropConnect produce near-zero epistemic uncertainty. Deep Ensembles and MC Dropout are the methods with meaningful epistemic and aleatoric separation.

Risk-coverage analysis shows that Deep Ensembles, DropConnect, and MC Dropout all produce uncertainty rankings well-suited for selective prediction (@risk_coverage_head1, @risk_coverage_head2, @risk_coverage). Flipout's ranking is far less useful on both heads. DUQ occupies a middle position. Prior work on skin lesion classification found that uncertainty-based referral can improve accuracy to 90% by deferring just 25% of uncertain cases @mobinyRiskAwareMachineLearning2019, and that removing the most uncertain samples monotonically improves balanced accuracy @combaliaUncertaintyEstimationDeep2020. Our risk-coverage results confirm these findings across a broader set of UQ methods.

Across all evaluated criteria, Deep Ensembles are the most balanced method. It achieves the highest accuracy, the best calibration, meaningful epistemic uncertainty decomposition, and the strongest risk-coverage profile. Comparative evaluations in other domains support this: deep ensembles outperform approximate Bayesian methods across multiple benchmarks @gawlikowskiSurveyUncertaintyDeep2023 @lakshminarayananSimpleScalablePredictive. On skin lesion data specifically, Abdar et al. found that deep ensembles outperformed MC Dropout on one of two evaluated datasets @abdarUncertaintyQuantificationSkin2021.

DUQ's single-pass efficiency comes at the cost of lower accuracy and no uncertainty decomposition, which limits its usefulness when reliability is the priority.

Flipout's near-zero epistemic uncertainty has been reported before. M. Valdenegro-Toro and D. Saromo Mori @valdenegro-toroDeeperLookAleatoric2022 observed the same pattern in both regression and classification tasks, and attributed it to Flipout's variance reduction effect. In our checkpoint, σ is close to its starting value: median 0.056 across all 4.7 M Flipout kernel weights, and none of them collapsed. The Flipout layer really is stochastic, with hidden activations varying by about ±0.1 across forward passes.

Yet predictions across those passes are nearly identical, and Flipout cannot flag samples where the model is confidently wrong. Why the layer's stochasticity does not translate to varying predictions is not clear.

=== Effect of Input Characteristics (Question B)

Multivariate regression identifies diagnosis confirmation type as the strongest independent predictor of entropy, followed by data source attribution and secondary diagnosis (@multivariate_regression_h1, @multivariate_regression_h2). Confirmation type is a proxy for case severity: histopathology-confirmed cases show higher entropy than clinically confirmed cases, and this effect persists after controlling for diagnosis. Methods with wider entropy distributions (Flipout, Deep Ensembles) show the strongest response to confirmation type (@influence_summary_main, @influence_summary_main_h2), while DropConnect and MC Dropout barely shift in absolute values, their relative ranking still changes significantly and thus they still show a proper response to this important case characteristic.

Entropy scales consistently with diagnostic difficulty across all methods, with benign lesions showing the lowest entropy and melanoma the highest. Calibration differences between methods become most pronounced on melanoma, where DropConnect and MC Dropout show substantial miscalibration while Flipout and Deep Ensembles maintain better calibration.

Regarding demographic fairness: Fitzpatrick skin type shows a large univariate effect on entropy, but controlling for diagnosis confirmation type removes the majority of this effect. Prior work has documented that dermatology AI models perform substantially worse on darker skin tones @daneshjouDisparitiesDermatologyAI2022, and that models are most accurate on skin types similar to those they were trained on @grohEvaluatingDeepNeural2021.

In our case, darker skin types show lower entropy (@benign_entropy_by_skintype), which correlates strongly with malignant sample rate (@h1_distribution_skintype) rather than indicating a skin-color shortcut. Indeterminate-sample validation confirms that all models appropriately increase uncertainty on ambiguous cases for skin types I--III (@indet_entropy_ratio). For darker skin types, however, indeterminate sample sizes are too small or entirely absent to draw conclusions, so we have the least evidence for the populations that need it most.

=== Difficult Sample Analysis (Question C)

The difficult-sample analysis examines how UQ methods behave on the hardest cases: inputs where multiple methods predict incorrectly. All methods increase entropy with difficulty tier (@difficulty_metrics_by_tier), confirming that uncertainty scales with consensus difficulty, but DropConnect and MC Dropout again show much lower absolute entropy on hard samples than the other methods, consistent with their narrower uncertainty response observed throughout the evaluation.

Pairwise entropy rank correlations range from 0.54 to 0.91 across all method pairs (@difficulty_entropy_correlation). This is a high level of agreement given that the five methods use different uncertainty estimation approaches and four of them fine-tune their own backbone independently. The lowest correlation is between DropConnect and Flipout (0.54), the two methods that also show the weakest epistemic uncertainty decomposition. For practical purposes, this agreement means the choice of UQ method matters less for identifying difficult cases than for calibration quality and uncertainty decomposition, where the methods differ substantially.

The risk-coverage rankings mirror those from Question A, with one addition: Flipout's weaker ranking persists even though it produces higher absolute entropy values, confirming that entropy magnitude alone does not determine ranking quality.

== Answering the Research Question

This thesis set out to answer: _"Which uncertainty quantification techniques are most effective for improving the reliability of deep learning-based skin lesion classification?"_

Combining the findings across all three subquestions, *Deep Ensembles are the most effective method overall*. It performs best on accuracy, calibration, and selective referral. It achieves accuracy among the highest of all methods and the lowest calibration error on both classification heads. Its risk-coverage profile is the strongest for selective referral. Unlike Flipout and DUQ, its epistemic-aleatoric decomposition is meaningful, which means it can distinguish cases where the model lacks knowledge from cases where the data itself is ambiguous.

No other method matches this combination. MC Dropout and DropConnect achieve comparable accuracy and risk coverage but show weaker calibration, while Flipout's entropy ranking is less useful for selective referral. DUQ is the weakest on accuracy and lacks uncertainty decomposition entirely. Its single-pass efficiency does not compensate when reliability is the priority. Deep Ensembles does require training and storing five independent models, the highest computational cost of the evaluated methods, but the extra cost seems worth it when reliability matters most.

#pagebreak()

== Limitations

This evaluation has several limitations:

*Dataset Representation:* The largest limitation is severe class imbalance for darker skin types. With zero malignant samples for skin type VI and only 3-6 for types IV-V (see @skintype_summary_appendix for the full per-skin-type breakdown), it is impossible to meaningfully evaluate malignant detection performance for these populations. The reported 83.3% sensitivity for skin type IV (n=6) is statistically unreliable, as a single additional misclassification would change it dramatically.

*Single Architecture:* All UQ methods were evaluated on an EfficientNet-B3 backbone. Results may differ for other architectures such as vision transformers or larger EfficientNet variants. The review of UQ methods should be validated across multiple architectures before generalizing conclusions to all model architectures.

*Flipout training instability:* Training with the Flipout layer proved unstable, with a large proportion of hyperparameter search runs failing to converge. Because the other methods could be tuned more thoroughly across a wider range of configurations, Flipout likely ended up with a less optimized set of hyperparameters. Its poor accuracy may therefore partly reflect insufficient optimization rather than a fundamental limitation of this method.

*DUQ entropy conversion:* To compare all methods on the same scale, DUQ's RBF kernel outputs were normalized and passed through Shannon entropy. This discards the absolute kernel magnitude, which is DUQ's primary uncertainty signal: samples far from all centroids receive uniformly low kernel values, and the original method uses the maximum kernel value directly for out-of-distribution detection @van2020uncertainty. After normalization, a sample equidistant from two nearby centroids (genuinely ambiguous) looks identical to a sample far from all centroids (out-of-distribution). The entropy-based comparison therefore understates DUQ's out-of-distribution detection capability relative to its intended use.

*Imaging-artifact shortcuts:* @per_class_entropy_appendix shows clinical measurement markers in every Benign low-entropy sample. This may mean the model treats marker presence as a class signal. Confirming this would require systematically labeling markers across the dataset and testing whether model confidence depends on it.

#pagebreak()

== Future Work

*Expert validation of uncertainty rankings:* This study validates uncertainty estimates indirectly, through metadata-based statistical analyses, model consensus and behavioral checks on indeterminate samples. A next step is to have a dermatology professional review the images that models flag as high- and low-uncertainty and verify whether the assigned difficulty aligns with clinical judgment. This would show more directly whether the uncertainty scores pick up on real diagnostic difficulty or just reflect patterns in the metadata or dataset composition.

*Extended demographic representation:* Priority should be given to curating or collecting datasets with balanced malignant case representation across all Fitzpatrick skin types. Without such data, claims about model fairness cannot be supported.

*Feature attribution analysis:* Although the results suggest UQ methods function appropriately across skin types, applying methods such as Grad-CAM @selvarajuGradCAMVisualExplanations2020 to compare model attention would provide more confirmation that models look at lesion features rather than surrounding skin characteristics.

*Out-of-distribution evaluation:* This thesis evaluates uncertainty on in-distribution test data and indeterminate samples, but does not include a dedicated OOD test set such as non-dermatological images or images from unseen imaging devices. Such an evaluation would test whether models reliably assign high uncertainty to inputs outside their training domain, and whether DUQ's native kernel distance measure outperforms entropy-based methods for OOD detection, given that its design specifically targets this use case.

Until datasets with adequate representation of darker skin types exist, uncertainty estimates for these populations cannot be validated, and we cannot yet confirm that these models are safe to deploy across diverse patient populations.

#set heading(numbering: "1.1")
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  text(weight: "bold", size: 1.2em)[#it.body]
  line(length: 100%, stroke: 1pt + gray)
  v(0.5em)
}

#heading(level: 1, outlined: true)[Appendix]

// Reset heading counter and set numbering for appendix subsections
#counter(heading).update((1, 0))
#set heading(numbering: "A.1", supplement: [Appendix])

== Dataset Attribution <dataset_attribution>

#full_width[#data-table(
  dataset_attribution_data,
  show-total: false,
)]

#pagebreak()

== Image Type Distribution <image_type_distribution>

#data-table(
  image_type_distribution_data,
  show-total: false,
)

#pagebreak()

== Secondary Diagnosis Distribution <secondary_diagnosis_distribution_table>

#full_width[
  #data-table(
    secondary_diagnosis_distribution_data,
    show-total: false,
  )
]

#pagebreak()

== Secondary Diagnosis Mapping <secondary_diagnosis_mapping>

#full_width[
  #table(
    columns: (3fr, 1.5fr),
    stroke: none,
    align: left,
    inset: (x, y) => if x == 0 { (left: 0pt, right: 8pt, top: 5pt, bottom: 5pt) } else { 5pt },
    table.hline(y: 1),
    [Original category], [Consolidated class],
    [Benign melanocytic proliferations], [Benign],
    [Benign epidermal proliferations], [Benign],
    [Benign - Other], [Benign],
    [Benign soft tissue proliferations - Fibro-histiocytic], [Benign],
    [Benign soft tissue proliferations - Vascular], [Benign],
    [Benign soft tissue proliferations - Neural], [Benign],
    [Benign adnexal epithelial proliferations - Sebaceous], [Benign],
    [Benign adnexal epithelial proliferations - Follicular], [Benign],
    [Benign adnexal epithelial proliferations - Apocrine or Eccrine], [Benign],
    [Cysts], [Benign],
    [Hemorrhagic lesions], [Benign],
    [Mast cell proliferations], [Benign],
    [Malignant melanocytic proliferations (Melanoma)], [Melanoma],
    [Malignant epidermal proliferations], [Malignant_Epidermal],
    [Malignant adnexal epithelial proliferations - Follicular], [Malignant_NonEpidermal],
    [Malignant adnexal epithelial proliferations - Apocrine or Eccrine], [Malignant_NonEpidermal],
    [Malignant soft tissue proliferations - Fibro-histiocytic], [Malignant_NonEpidermal],
    [Malignant soft tissue proliferations - Vascular], [Malignant_NonEpidermal],
    [Indeterminate epidermal proliferations], [Other],
    [Indeterminate melanocytic proliferations], [Other],
    [Flat melanotic pigmentations - not melanocytic nevus], [Other],
    [Inflammatory or infectious diseases], [Other],
    [Collision - Only benign proliferations], [Other],
    [Collision - At least one malignant proliferation], [Other],
    [Exogenous], [Other],
  ),
]

#pagebreak()

== Entropy Growth: Test vs Indeterminate Set <entropy_growth_appendix>

The tables below show the relative increase in predictive entropy from the test set to the indeterminate set (clinically ambiguous samples).

#full_width[#figure(
  {
    let median(arr) = {
      let sorted = arr.sorted()
      let n = sorted.len()
      if calc.rem(n, 2) == 1 {
        sorted.at(int(n / 2))
      } else {
        (sorted.at(int(n / 2) - 1) + sorted.at(int(n / 2))) / 2
      }
    }
    let fmt(val) = calc.round(val, digits: 3)
    let pct_growth(test, indet) = {
      let growth = (indet - test) / test * 100
      [#calc.round(growth, digits: 1)%]
    }

    let table_data = ()
    for (idx, label) in uq_model_labels.enumerate() {
      let test_h1 = predictive_entropy_head1.at(idx)
      let indet_h1 = predictive_entropy_indet_head1.at(idx)
      let test_h2 = predictive_entropy_head2.at(idx)
      let indet_h2 = predictive_entropy_indet_head2.at(idx)

      if test_h1.len() > 0 and indet_h1.len() > 0 and test_h2.len() > 0 and indet_h2.len() > 0 {
        let med_test_h1 = median(test_h1)
        let med_indet_h1 = median(indet_h1)
        let med_test_h2 = median(test_h2)
        let med_indet_h2 = median(indet_h2)
        table_data.push((
          fmt(med_test_h1),
          fmt(med_indet_h1),
          pct_growth(med_test_h1, med_indet_h1),
          fmt(med_test_h2),
          fmt(med_indet_h2),
          pct_growth(med_test_h2, med_indet_h2),
        ))
      } else {
        table_data.push((none, none, none, none, none, none))
      }
    }

    color-table(
      table_data,
      uq_model_labels,
      ("Binary Test", "Binary Indet", "Binary Δ%", "Multi Test", "Multi Indet", "Multi Δ%"),
      0.0,
      100.0,
      use-cell-colors: false,
    )
  },
  caption: flex-caption(
    [Median predictive entropy for test and indeterminate sets, with relative increase (Δ%). A larger Δ% means the method responds more to sample difficulty.],
    [Median entropy: test vs indeterminate],
  ),
) <entropy_growth_test_indet_median>]

#full_width[
  #figure(
    {
      let mean(arr) = arr.sum() / arr.len()
      let fmt(val) = calc.round(val, digits: 3)
      let pct_growth(test, indet) = {
        let growth = (indet - test) / test * 100
        [#calc.round(growth, digits: 1)%]
      }

      let table_data = ()
      for (idx, label) in uq_model_labels.enumerate() {
        let test_h1 = predictive_entropy_head1.at(idx)
        let indet_h1 = predictive_entropy_indet_head1.at(idx)
        let test_h2 = predictive_entropy_head2.at(idx)
        let indet_h2 = predictive_entropy_indet_head2.at(idx)

        if test_h1.len() > 0 and indet_h1.len() > 0 and test_h2.len() > 0 and indet_h2.len() > 0 {
          let mean_test_h1 = mean(test_h1)
          let mean_indet_h1 = mean(indet_h1)
          let mean_test_h2 = mean(test_h2)
          let mean_indet_h2 = mean(indet_h2)
          table_data.push((
            fmt(mean_test_h1),
            fmt(mean_indet_h1),
            pct_growth(mean_test_h1, mean_indet_h1),
            fmt(mean_test_h2),
            fmt(mean_indet_h2),
            pct_growth(mean_test_h2, mean_indet_h2),
          ))
        } else {
          table_data.push((none, none, none, none, none, none))
        }
      }

      color-table(
        table_data,
        uq_model_labels,
        ("Binary Test", "Binary Indet", "Binary Δ%", "Multi Test", "Multi Indet", "Multi Δ%"),
        0.0,
        100.0,
        use-cell-colors: false,
      )
    },
    caption: flex-caption(
      [Mean predictive entropy for test and indeterminate sets, with relative increase (Δ%). A larger Δ% means the method responds more to sample difficulty.],
      [Mean entropy: test vs indeterminate],
    ),
  ) <entropy_growth_test_indet_mean>
]

#pagebreak()

== Visual Examples: Entropy Samples <entropy_samples_appendix>

The following image grids show samples at different entropy levels.

#let entropy_sample_raw = csv("data/entropy_sample_ids.csv", row-type: dictionary)
#let low_entropy_samples = entropy_sample_raw.filter(row => row.at("band") == "low").slice(0, 15)
#let high_entropy_samples = entropy_sample_raw.filter(row => row.at("band") == "high").slice(0, 15)

#let sample_tile(id) = box(
  width: 100%,
  stroke: 0.5pt + gray,
  inset: 0pt,
)[
  #image(
    "../Datasets/images/" + str(id) + ".jpg",
    width: 100%,
    height: auto,
    fit: "cover",
  )
]

#figure(
  grid(
    columns: (1fr,) * 5,
    gutter: 2mm,
    ..low_entropy_samples.map(row => sample_tile(row.at("isic_id"))),
  ),
  caption: flex-caption(
    [Low-entropy samples from the Deep Ensembles binary head (H1) on the test set (predictive entropy ≈ 0.05).],
    [Low-entropy samples, Deep Ensembles binary head (H1).],
  ),
) <low_entropy_grid>

#figure(
  grid(
    columns: (1fr,) * 5,
    gutter: 2mm,
    ..high_entropy_samples.map(row => sample_tile(row.at("isic_id"))),
  ),
  caption: flex-caption(
    [High-entropy samples from the Deep Ensembles binary head (H1) on the test set (predictive entropy ≈ 0.65).],
    [High-entropy samples, Deep Ensembles binary head (H1).],
  ),
) <high_entropy_grid>

#pagebreak()

== Visual Examples: Difficult Samples <difficulty_visual_examples_appendix>

The image grids below are from the Sample Difficulty Analysis. They are included for transparency and context, as the thesis does not attempt to explain why a specific lesion is difficult from a dermatologic perspective.

#let difficulty_samples = csv("../Notebooks/results/difficulty_samples/sampled_images.csv", row-type: dictionary)

#let format_confirm(c) = {
  if c == "" or c == none { "n/a" }
  else if c == "single image expert consensus" { "expert consensus" }
  else if c == "confocal microscopy with consensus dermoscopy" { "confocal microscopy" }
  else { c }
}

#let diff_tile(row) = stack(
  dir: ttb,
  spacing: 1mm,
  layout(size => box(
    clip: true,
    width: 100%,
    height: size.width,
    align(center + horizon, image(row.at("image_path"), width: 100%)),
  )),
  text()[#row.at("diagnosis_2", default: row.at("diagnosis_1", default: "")).replace("_", "\n")],
  text(size: 7pt, style: "italic")[#format_confirm(row.at("diagnosis_confirm_type", default: ""))],
)

#let tier5_h1_samples = (
  difficulty_samples
    .filter(r => r.at("category") == "tier5_h1")
    .slice(0, calc.min(18, difficulty_samples.filter(r => r.at("category") == "tier5_h1").len()))
)

#full_width[#figure(
    grid(
      columns: (1fr,) * 6,
      column-gutter: 2mm,
      row-gutter: 2mm,
      ..tier5_h1_samples.map(row => diff_tile(row)),
    ),
    caption: flex-caption(
      [Universally misclassified samples (tier 5), binary head (H1). These are cases where all five UQ methods predict the wrong binary class. Each tile is labeled with the dataset diagnosis and the recorded confirmation type.],
      [Universally misclassified samples (tier 5), binary head (H1).],
    ),
  ) <tier5_grid>
]

#let overconf_samples = difficulty_samples.filter(r => r.at("category") == "dangerous_overconfidence")

#full_width[#figure(
    grid(
      columns: (1fr,) * 6,
      column-gutter: 2mm,
      row-gutter: 2mm,
      ..overconf_samples.map(row => diff_tile(row)),
    ),
    caption: flex-caption(
      [Dangerous overconfidence: samples misclassified by 3+ methods with high mean confidence among the incorrect methods. Each tile is labeled with the dataset diagnosis and the recorded confirmation type.],
      [Dangerous overconfidence: high-confidence misclassifications.],
    ),
  ) <overconfident_failures_grid>
]

#let cautious_samples = difficulty_samples.filter(r => r.at("category") == "appropriate_caution")

#full_width[#figure(
    grid(
      columns: (1fr,) * 6,
      column-gutter: 2mm,
      row-gutter: 2mm,
      ..cautious_samples.map(row => diff_tile(row)),
    ),
    caption: flex-caption(
      [Appropriately cautious predictions: samples correctly classified by all methods but with high uncertainty (top 10% entropy). Each tile is labeled with the dataset diagnosis and the recorded confirmation type.],
      [Appropriately cautious: correct predictions with high uncertainty.],
    ),
  ) <cautious_grid>
]

=== Per-class Entropy Examples <per_class_entropy_appendix>

For each consolidated lesion class, the figures below show the six samples
with the highest and the six with the lowest predictive entropy on the
multiclass head (Deep Ensembles ranking). Low-entropy samples are
restricted to those the ensemble classifies correctly, avoiding overlap
with @overconfident_failures_grid (which already shows confident-but-wrong
cases). High-entropy samples are unfiltered: visual ambiguity does not
depend on whether the prediction was right.

#let per_class_samples = csv("../Notebooks/results/per_class_entropy_samples.csv", row-type: dictionary)

#let per_class_tile(row) = layout(size => box(
  clip: true,
  width: 100%,
  height: size.width,
  align(center + horizon, image(row.at("image_path"), width: 100%)),
))

#let per_class_block(class_name, label_anchor) = {
  let high_rows = per_class_samples.filter(r => r.at("diagnosis_2") == class_name and r.at("band") == "high")
  let low_rows = per_class_samples.filter(r => r.at("diagnosis_2") == class_name and r.at("band") == "low")
  let display_name = class_name.replace("_", " ").replace("NonEpidermal", "Non-Epidermal")
  let band_row(label, rows) = stack(
    dir: ttb,
    spacing: 1.5mm,
    text(size: 8pt, style: "italic")[#label],
    grid(
      columns: (1fr,) * 6,
      column-gutter: 2mm,
      ..rows.map(r => per_class_tile(r)),
    ),
  )
  full_width[#figure(
    stack(
      dir: ttb,
      spacing: 4mm,
      band_row("Highest entropy", high_rows),
      band_row("Lowest entropy", low_rows),
    ),
    kind: image,
    caption: flex-caption(
      [#display_name: the highest-entropy row is unfiltered. The lowest-entropy row is restricted to samples the ensemble classifies correctly. Entropy from the Deep Ensembles multiclass head (H2).],
      [Per-class entropy examples — #display_name.],
    ),
  ) #label_anchor]
}

#per_class_block("Benign", <per_class_benign>)
#per_class_block("Malignant_NonEpidermal", <per_class_mal_nonep>)
#per_class_block("Malignant_Epidermal", <per_class_mal_ep>)
#per_class_block("Melanoma", <per_class_melanoma>)
#per_class_block("Other", <per_class_other>)

#pagebreak()

== Performance by Data Source <attribution_performance_appendix>

Detailed performance metrics by data source (attribution) across all UQ methods for the binary classification task. Sources are sorted by sample count in the test set.

#let attribution_sources_sorted = attribution_dist.sorted(key: row => -int(row.at("count")))
#let attribution_sources = attribution_sources_sorted.map(row => row.at("group_value"))

#figure(
  {
    let ensemble_acc = collect-group-metric(ensemble_attribution_h1, attribution_sources, "accuracy")
    let dropout_acc = collect-group-metric(dropout_attribution_h1, attribution_sources, "accuracy")
    let dropconnect_acc = collect-group-metric(dropconnect_attribution_h1, attribution_sources, "accuracy")
    let flipout_acc = collect-group-metric(flipout_attribution_h1, attribution_sources, "accuracy")
    let duq_acc = collect-group-metric(duq_attribution_h1, attribution_sources, "accuracy")

    color-table(
      transpose((ensemble_acc, dropout_acc, dropconnect_acc, flipout_acc, duq_acc)),
      attribution_sources,
      model_labels_short_uq,
      0.70,
      1.00,
      color-fn: white-to-green-color,
    )
  },
  caption: flex-caption(
    [Accuracy by data source across UQ methods (binary classification). Higher is better.],
    [Accuracy by data source.],
  ),
) <attribution_accuracy_h1>

#figure(
  {
    let ensemble_ent = collect-group-metric(ensemble_attribution_h1, attribution_sources, "mean_predictive_entropy")
    let dropout_ent = collect-group-metric(dropout_attribution_h1, attribution_sources, "mean_predictive_entropy")
    let dropconnect_ent = collect-group-metric(
      dropconnect_attribution_h1,
      attribution_sources,
      "mean_predictive_entropy",
    )
    let flipout_ent = collect-group-metric(flipout_attribution_h1, attribution_sources, "mean_predictive_entropy")
    let duq_ent = collect-group-metric(duq_attribution_h1, attribution_sources, "mean_predictive_entropy")

    color-table(
      transpose((ensemble_ent, dropout_ent, dropconnect_ent, flipout_ent, duq_ent)),
      attribution_sources,
      model_labels_short_uq,
      0.00,
      0.50,
      color-fn: white-to-red-color,
    )
  },
  caption: flex-caption(
    [Mean predictive entropy by data source across UQ methods (binary classification). Higher values indicate greater uncertainty.],
    [Mean predictive entropy by data source.],
  ),
) <attribution_entropy_h1>

#figure(
  {
    let ensemble_ece = collect-group-metric(ensemble_attribution_h1, attribution_sources, "ece")
    let dropout_ece = collect-group-metric(dropout_attribution_h1, attribution_sources, "ece")
    let dropconnect_ece = collect-group-metric(dropconnect_attribution_h1, attribution_sources, "ece")
    let flipout_ece = collect-group-metric(flipout_attribution_h1, attribution_sources, "ece")
    let duq_ece = collect-group-metric(duq_attribution_h1, attribution_sources, "ece")

    color-table(
      transpose((ensemble_ece, dropout_ece, dropconnect_ece, flipout_ece, duq_ece)),
      attribution_sources,
      model_labels_short_uq,
      0.00,
      0.20,
      color-fn: white-to-red-color,
    )
  },
  caption: flex-caption(
    [Expected Calibration Error (ECE) by data source across UQ methods (binary classification). Lower is better.],
    [ECE by data source.],
  ),
) <attribution_ece_h1>

#pagebreak()

== Sample Images by Data Source <attribution_samples_appendix>

Sample images from each data source, sorted by sample count in the test set.

#let attribution_samples_csv = csv("../Notebooks/results/attribution_samples/sampled_images.csv", row-type: dictionary)
#let attribution_dist_csv = csv(
  "../Notebooks/results/metrics/distribution_test_set_by_attribution.csv",
  row-type: dictionary,
)

#let get_attribution_samples(attr) = attribution_samples_csv.filter(row => row.at("attribution") == attr)

#let get_attribution_count(attr) = {
  let row = attribution_dist_csv.find(r => r.at("group_value") == attr)
  if row != none { row.at("count") } else { "?" }
}

#let attr_tile(row) = box(
  width: 100%,
  stroke: 0.5pt + gray,
  inset: 0pt,
  clip: true,
  {
    image(row.at("image_path"), width: 100%, height: auto)
  },
)

#let sample_attributions = attribution_samples_csv.map(row => row.at("attribution")).dedup()
#let sample_attributions_sorted = sample_attributions.sorted(key: attr => {
  let row = attribution_dist_csv.find(r => r.at("group_value") == attr)
  if row != none { -int(row.at("count")) } else { 0 }
})

#for attr in sample_attributions_sorted {
  let samples = get_attribution_samples(attr)
  if samples.len() > 0 {
    figure(
      grid(
        columns: (1fr,) * calc.min(6, samples.len()),
        gutter: 2mm,
        ..samples.map(row => attr_tile(row)),
      ),
      caption: [Sample images from #attr (N=#get_attribution_count(attr)).],
    )
  }
}

#pagebreak()

== Multivariate Regression: Detailed Per-Model Results <multivariate_regression_appendix>

Full multivariate regression results (Type II ANOVA) for each UQ method. The model is: Entropy ~ diagnosis_1 + diagnosis_2 + diagnosis_confirm_type + age_approx + attribution + image_type + sex + anatom_site_general ($N = 3617$).

#let mv_detail_terms = (
  "diagnosis_confirm_type",
  "diagnosis_2",
  "attribution",
  "image_type",
  "anatom_site_general",
  "age_approx",
  "diagnosis_1",
  "sex",
)
#let mv_detail_labels = (
  [Confirmation type],
  [Secondary diagnosis],
  [Attribution],
  [Image type],
  [Anatomical site],
  [Age],
  [Primary diagnosis],
  [Sex],
)
#let mv_detail_model_names = (
  ("flipout", "Flipout"),
  ("ensemble", "Deep Ensembles"),
  ("dropout", "MC Dropout"),
  ("dropconnect", "MC DropConnect"),
  ("duq", "DUQ"),
)

#for (run_type, model_name) in mv_detail_model_names [
  #full_width[
    #figure(
      {
        let get_row(head, term) = {
          multivariate_regression.find(r => (
            r.at("run_type") == run_type and r.at("head") == head and r.at("term") == term
          ))
        }

        let fmt_p(row) = {
          if row == none { return [—] }
          let v = row.at("p_value")
          if v == "" { return [—] }
          let p = float(v)
          if p < 0.001 { [< 0.001] } else { fmt(p) }
        }

        let fmt_val(row, field) = {
          if row == none { return [—] }
          let v = row.at(field)
          if v == "" { return [—] }
          fmt(float(v))
        }

        table(
          columns: (1fr, auto, auto, auto, auto, auto, auto, auto, auto),
          align: (left, right, right, right, right, right, right, right, right),
          stroke: none,
          inset: 4pt,
          table.hline(y: 2),
          table.header(
            table.cell(rowspan: 2, [_Variable_], align: bottom),
            table.cell(rowspan: 2, [_df_], align: bottom),
            table.cell(colspan: 3, [_Binary head (H1)_], align: center),
            [],
            table.cell(colspan: 3, [_Multiclass head (H2)_], align: center),
            [_η²_], [_Partial η²_], [_p_], [], [_η²_], [_Partial η²_], [_p_],
          ),
          ..mv_detail_terms
            .enumerate()
            .map(((i, term)) => {
              let h1 = get_row("head1", term)
              let h2 = get_row("head2", term)
              (
                mv_detail_labels.at(i),
                {
                  let r = get_row("head1", term)
                  if r != none { fmt(float(r.at("df")), decimals: 0) } else { [—] }
                },
                fmt_val(h1, "eta_sq"),
                fmt_val(h1, "partial_eta_sq"),
                fmt_p(h1),
                [],
                fmt_val(h2, "eta_sq"),
                fmt_val(h2, "partial_eta_sq"),
                fmt_p(h2),
              )
            })
            .flatten(),
          table.hline(),
          ..{
            let h1_model = get_row("head1", "Model (total)")
            let h2_model = get_row("head2", "Model (total)")
            (
              [_Model ($R^2$)_],
              { if h1_model != none { fmt(float(h1_model.at("df")), decimals: 0) } else { [—] } },
              table.cell(colspan: 2)[#{ if h1_model != none { fmt(float(h1_model.at("eta_sq"))) } else { [—] } }],
              [< 0.001],
              [],
              table.cell(colspan: 2)[#{ if h2_model != none { fmt(float(h2_model.at("eta_sq"))) } else { [—] } }],
              [< 0.001],
            )
          },
        )
      },
      caption: flex-caption(
        [Multivariate regression of predictive entropy on metadata variables (Type II SS, #model_name).],
        [Multivariate regression, #model_name.],
      ),
    )
  ]
]

#pagebreak()

== Diagnosis Confirmation Type Distribution <diagnosis_confirm_distribution_appendix>

Distribution of diagnosis confirmation methods in the test set. Not all samples have a recorded confirmation type.

#{
  let dist_data = read-dist(metrics_dir + "/distribution_test_set_by_diagnosis_confirm_type.csv")

  let known_total = dist_data.map(r => r.count).sum()
  let test_total = 5920
  let missing = test_total - known_total

  let full_data = dist_data
  full_data.push(("label": "Missing", "count": missing))

  data-table(
    full_data,
    show-total: true,
  )
}

#pagebreak()

== Performance by Diagnosis Confirmation Type <diagnosis_confirm_performance_appendix>

Detailed performance metrics by diagnosis confirmation method across all UQ methods for the binary classification task. Types are sorted by sample count in the test set.

#let diagnosis_confirm_types_sorted = diagnosis_confirm_dist.sorted(key: row => -int(row.at("count")))
#let diagnosis_confirm_types = diagnosis_confirm_types_sorted.map(row => row.at("group_value"))
#let diagnosis_confirm_labels = (
  "Histopathology",
  "Expert Consensus",
  "Serial Imaging",
  "Clinical Assessment",
  "Confocal + Dermoscopy",
)

#figure(
  {
    let ensemble_acc = collect-group-metric(ensemble_diagnosis_confirm_h1, diagnosis_confirm_types, "accuracy")
    let dropout_acc = collect-group-metric(dropout_diagnosis_confirm_h1, diagnosis_confirm_types, "accuracy")
    let dropconnect_acc = collect-group-metric(dropconnect_diagnosis_confirm_h1, diagnosis_confirm_types, "accuracy")
    let flipout_acc = collect-group-metric(flipout_diagnosis_confirm_h1, diagnosis_confirm_types, "accuracy")
    let duq_acc = collect-group-metric(duq_diagnosis_confirm_h1, diagnosis_confirm_types, "accuracy")

    color-table(
      transpose((ensemble_acc, dropout_acc, dropconnect_acc, flipout_acc, duq_acc)),
      diagnosis_confirm_labels,
      model_labels_short_uq,
      0.70,
      1.00,
      color-fn: white-to-green-color,
    )
  },
  caption: flex-caption(
    [Accuracy by diagnosis confirmation type across UQ methods (binary classification). Higher is better.],
    [Accuracy by diagnosis confirmation type.],
  ),
) <diagnosis_confirm_accuracy_h1>

#figure(
  {
    let ensemble_ent = collect-group-metric(
      ensemble_diagnosis_confirm_h1,
      diagnosis_confirm_types,
      "mean_predictive_entropy",
    )
    let dropout_ent = collect-group-metric(
      dropout_diagnosis_confirm_h1,
      diagnosis_confirm_types,
      "mean_predictive_entropy",
    )
    let dropconnect_ent = collect-group-metric(
      dropconnect_diagnosis_confirm_h1,
      diagnosis_confirm_types,
      "mean_predictive_entropy",
    )
    let flipout_ent = collect-group-metric(
      flipout_diagnosis_confirm_h1,
      diagnosis_confirm_types,
      "mean_predictive_entropy",
    )
    let duq_ent = collect-group-metric(duq_diagnosis_confirm_h1, diagnosis_confirm_types, "mean_predictive_entropy")

    color-table(
      transpose((ensemble_ent, dropout_ent, dropconnect_ent, flipout_ent, duq_ent)),
      diagnosis_confirm_labels,
      model_labels_short_uq,
      0.00,
      0.50,
      color-fn: white-to-red-color,
    )
  },
  caption: flex-caption(
    [Mean predictive entropy by diagnosis confirmation type across UQ methods (binary classification). Higher values indicate greater uncertainty.],
    [Mean predictive entropy by confirmation type.],
  ),
) <diagnosis_confirm_entropy_h1>

#figure(
  {
    let ensemble_ece = collect-group-metric(ensemble_diagnosis_confirm_h1, diagnosis_confirm_types, "ece")
    let dropout_ece = collect-group-metric(dropout_diagnosis_confirm_h1, diagnosis_confirm_types, "ece")
    let dropconnect_ece = collect-group-metric(dropconnect_diagnosis_confirm_h1, diagnosis_confirm_types, "ece")
    let flipout_ece = collect-group-metric(flipout_diagnosis_confirm_h1, diagnosis_confirm_types, "ece")
    let duq_ece = collect-group-metric(duq_diagnosis_confirm_h1, diagnosis_confirm_types, "ece")

    color-table(
      transpose((ensemble_ece, dropout_ece, dropconnect_ece, flipout_ece, duq_ece)),
      diagnosis_confirm_labels,
      model_labels_short_uq,
      0.00,
      0.20,
      color-fn: white-to-red-color,
    )
  },
  caption: flex-caption(
    [Expected Calibration Error (ECE) by diagnosis confirmation type across UQ methods (binary classification). Lower is better.],
    [ECE by diagnosis confirmation type.],
  ),
) <diagnosis_confirm_ece_h1>

#full_width[
  #figure(
    {
      let types = diagnosis_confirm_types
      let labels = diagnosis_confirm_labels

      let data = types
        .enumerate()
        .map(((i, type_val)) => {
          let row = ensemble_diagnosis_confirm_h1.find(r => r.group_value == type_val)
          let total = to_float(row.at("mean_predictive_entropy"))
          let aleatoric = to_float(row.at("mean_expected_entropy"))
          let epistemic = to_float(row.at("mean_mutual_information"))
          let pct_a = if total > 0 { calc.round(aleatoric / total * 100, digits: 1) } else { 0.0 }
          let pct_e = if total > 0 { calc.round(epistemic / total * 100, digits: 1) } else { 0.0 }
          (
            label: labels.at(i),
            n: row.at("group_size"),
            total: total,
            aleatoric: aleatoric,
            epistemic: epistemic,
            pct_a: pct_a,
            pct_e: pct_e,
          )
        })

      table(
        columns: (1fr, auto, auto, auto, auto, auto, auto),
        align: (left, right, right, right, right, right, right),
        stroke: none,
        inset: (x, y) => if x == 0 { (left: 0pt, right: 4pt, top: 5pt, bottom: 5pt) } else { 4pt },
        table.hline(y: 1),
        table.header(
          [_Confirmation Type_], [_N_], [_Total_], [_Aleatoric_], [_Epistemic_], [_% Aleatoric_], [_% Epistemic_]
        ),
        ..data
          .map(d => (
            d.label,
            str(d.n),
            fmt(d.total),
            fmt(d.aleatoric),
            fmt(d.epistemic),
            [#fmt(d.pct_a, decimals: 1)%],
            [#fmt(d.pct_e, decimals: 1)%],
          ))
          .flatten(),
      )
    },
    caption: flex-caption(
      [Uncertainty decomposition by diagnosis confirmation type for Deep Ensembles (binary classification). Total predictive entropy is split into aleatoric (expected entropy) and epistemic (mutual information) components.],
      [Uncertainty decomposition by confirmation type.],
    ),
  ) <diagnosis_confirm_uncertainty_decomposition>]

== Sample Images by Diagnosis Confirmation Type <diagnosis_confirm_samples_appendix>

Sample images from each diagnosis confirmation type.

#let confirm_samples_csv = csv(
  "../Notebooks/results/diagnosis_confirm_samples/sampled_images.csv",
  row-type: dictionary,
)
#let confirm_dist_csv = csv(
  "../Notebooks/results/metrics/distribution_test_set_by_diagnosis_confirm_type.csv",
  row-type: dictionary,
)

#let get_confirm_samples(ctype) = confirm_samples_csv.filter(row => row.at("diagnosis_confirm_type") == ctype)

#let get_confirm_count(ctype) = {
  let row = confirm_dist_csv.find(r => r.at("group_value") == ctype)
  if row != none { row.at("count") } else { "?" }
}

#let confirm_tile(row) = box(
  width: 100%,
  stroke: 0.5pt + gray,
  inset: 0pt,
  clip: true,
  {
    image(row.at("image_path"), width: 100%, height: auto)
  },
)

#let sample_confirm_types = confirm_samples_csv.map(row => row.at("diagnosis_confirm_type")).dedup()
#let sample_confirm_types_sorted = sample_confirm_types.sorted(key: ctype => {
  let row = confirm_dist_csv.find(r => r.at("group_value") == ctype)
  if row != none { -int(row.at("count")) } else { 0 }
})

#for ctype in sample_confirm_types_sorted {
  let samples = get_confirm_samples(ctype)
  if samples.len() > 0 {
    figure(
      grid(
        columns: (1fr,) * calc.min(6, samples.len()),
        gutter: 2mm,
        ..samples.map(row => confirm_tile(row)),
      ),
      caption: [Sample images confirmed by #ctype (N=#get_confirm_count(ctype)).],
    )
  }
}

== Sample counts and malignant rates by Fitzpatrick skin type <skintype_summary_appendix>

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, right, right, right, right),
    stroke: 0.5pt + gray,
    inset: 6pt,
    [_Skin Type_], [_Total_], [_Benign_], [_Malignant_], [_% Malignant_],
    ..h1_counts
      .map(row => {
        let st = row.at("fitzpatrick_skin_type")
        let benign = int(row.at("Benign", default: "0"))
        let malignant = int(row.at("Malignant", default: "0"))
        let total = benign + malignant
        let pct = if total > 0 { calc.round(malignant / total * 100, digits: 1) } else { 0 }
        (st, str(total), str(benign), str(malignant), str(pct) + "%")
      })
      .flatten(),
  ),
  caption: flex-caption(
    [Sample counts and malignant rates by Fitzpatrick skin type in the test set.],
    [Sample counts and malignant rates by skin type.],
  ),
) <skintype_summary_table>

== Performance by Skin Type <skintype_performance_appendix>

Detailed performance metrics by Fitzpatrick skin type across all UQ methods for the binary classification task.

#let skintype_labels = ("I", "II", "III", "IV", "V", "VI")

#figure(
  {
    let ensemble_acc = collect-group-metric(ensemble_skintype_h1, skin_types, "accuracy")
    let dropout_acc = collect-group-metric(dropout_skintype_h1, skin_types, "accuracy")
    let dropconnect_acc = collect-group-metric(dropconnect_skintype_h1, skin_types, "accuracy")
    let flipout_acc = collect-group-metric(flipout_skintype_h1, skin_types, "accuracy")
    let duq_acc = collect-group-metric(duq_skintype_h1, skin_types, "accuracy")

    color-table(
      transpose((ensemble_acc, dropout_acc, dropconnect_acc, flipout_acc, duq_acc)),
      skintype_labels,
      model_labels_short_uq,
      0.85,
      1.00,
      color-fn: white-to-green-color,
    )
  },
  caption: flex-caption(
    [Accuracy by Fitzpatrick skin type across UQ methods, binary head (H1).],
    [Accuracy by skin type, binary head (H1).],
  ),
) <skintype_accuracy_h1>

#figure(
  {
    let ensemble_ent = collect-group-metric(ensemble_skintype_h1, skin_types, "mean_predictive_entropy")
    let dropout_ent = collect-group-metric(dropout_skintype_h1, skin_types, "mean_predictive_entropy")
    let dropconnect_ent = collect-group-metric(dropconnect_skintype_h1, skin_types, "mean_predictive_entropy")
    let flipout_ent = collect-group-metric(flipout_skintype_h1, skin_types, "mean_predictive_entropy")
    let duq_ent = collect-group-metric(duq_skintype_h1, skin_types, "mean_predictive_entropy")

    color-table(
      transpose((ensemble_ent, dropout_ent, dropconnect_ent, flipout_ent, duq_ent)),
      skintype_labels,
      model_labels_short_uq,
      0.00,
      0.30,
      color-fn: white-to-red-color,
    )
  },
  caption: flex-caption(
    [Mean predictive entropy by Fitzpatrick skin type across UQ methods, binary head (H1).],
    [Mean entropy by skin type, binary head (H1).],
  ),
) <skintype_entropy_h1>

#figure(
  {
    let ensemble_ece = collect-group-metric(ensemble_skintype_h1, skin_types, "ece")
    let dropout_ece = collect-group-metric(dropout_skintype_h1, skin_types, "ece")
    let dropconnect_ece = collect-group-metric(dropconnect_skintype_h1, skin_types, "ece")
    let flipout_ece = collect-group-metric(flipout_skintype_h1, skin_types, "ece")
    let duq_ece = collect-group-metric(duq_skintype_h1, skin_types, "ece")

    color-table(
      transpose((ensemble_ece, dropout_ece, dropconnect_ece, flipout_ece, duq_ece)),
      skintype_labels,
      model_labels_short_uq,
      0.00,
      0.10,
      color-fn: white-to-red-color,
    )
  },
  caption: flex-caption(
    [Expected Calibration Error (ECE) by Fitzpatrick skin type across UQ methods, binary head (H1).],
    [ECE by skin type, binary head (H1).],
  ),
) <skintype_ece_h1>

#full_width[
  #figure(
    {
      let data = skin_types
        .enumerate()
        .map(((i, type_val)) => {
          let row = ensemble_skintype_h1.find(r => r.group_value == type_val)
          let total = to_float(row.at("mean_predictive_entropy"))
          let aleatoric = to_float(row.at("mean_expected_entropy"))
          let epistemic = to_float(row.at("mean_mutual_information"))
          let pct_a = if total > 0 { calc.round(aleatoric / total * 100, digits: 1) } else { 0.0 }
          let pct_e = if total > 0 { calc.round(epistemic / total * 100, digits: 1) } else { 0.0 }
          (
            label: skintype_labels.at(i),
            n: row.at("group_size"),
            total: total,
            aleatoric: aleatoric,
            epistemic: epistemic,
            pct_a: pct_a,
            pct_e: pct_e,
          )
        })

      table(
        columns: (1fr, auto, auto, auto, auto, auto, auto),
        align: (left, right, right, right, right, right, right),
        stroke: none,
        inset: (x, y) => if x == 0 { (left: 0pt, right: 4pt, top: 5pt, bottom: 5pt) } else { 4pt },
        table.hline(y: 1),
        table.header([_Skin Type_], [_N_], [_Total_], [_Aleatoric_], [_Epistemic_], [_% Aleatoric_], [_% Epistemic_]),
        ..data
          .map(d => (
            d.label,
            str(d.n),
            fmt(d.total),
            fmt(d.aleatoric),
            fmt(d.epistemic),
            [#fmt(d.pct_a, decimals: 1)%],
            [#fmt(d.pct_e, decimals: 1)%],
          ))
          .flatten(),
      )
    },
    caption: flex-caption(
      [Uncertainty decomposition by Fitzpatrick skin type for Deep Ensembles (binary classification). Total predictive entropy is split into aleatoric (expected entropy) and epistemic (mutual information) components.],
      [Uncertainty decomposition by Fitzpatrick skin type.],
    ),
  ) <skintype_uncertainty_decomposition>]

#pagebreak()

== Predictive Entropy by Skin Type, Per Method <skintype_entropy_per_method_appendix>

The in-chapter @skintype_entropy_violin_h1 and @skintype_entropy_violin_h2 show predictive entropy by Fitzpatrick skin type for Deep Ensembles only. The figures below give the same view for each of the remaining four UQ methods, so the claim that "the same pattern holds for all five UQ methods" can be checked directly. Each figure shows the binary head (H1) on the left and the multiclass head (H2) on the right.

#let skintype_entropy_for_method(run_type, head) = {
  let grouped = fitzpatrick_skin_types.map(_ => ())
  for row in predictive_entropy_rows {
    if row.dataset != "test_set" or row.head != head or row.run_type != run_type {
      continue
    }
    let value = fitzpatrick_lookup.at(row.isic_id, default: none)
    if value == none or value == "" {
      continue
    }
    let idx = find-index(fitzpatrick_skin_types, value)
    if idx != none {
      grouped.at(idx).push(float(row.predictive_entropy))
    }
  }
  grouped
}

#let skintype_violin_for_method(run_type, head, xlim_max) = {
  let dists = skintype_entropy_for_method(run_type, head)
  let plots = ()
  for (idx, label) in fitzpatrick_skin_types.enumerate() {
    let values = dists.at(idx)
    if values.len() == 0 { continue }
    plots.push(
      lq.hviolin(
        values,
        y: (idx,),
        width: 0.6,
        color: skin_palette.at(idx),
      ),
    )
  }
  lq.diagram(
    height: 55mm,
    width: 53mm,
    xlabel: "Predictive Entropy",
    xlim: (-0.1, xlim_max),
    yaxis: (format-ticks: none),
    ..plots,
  )
}

#let skintype_per_method_pair(run_type, label, h1_label, h2_label) = {
  pad(
    left: 1mm,
    grid(columns: (53mm, 53mm), gutter: 8mm)[
      #figure(
        skintype_violin_for_method(run_type, "head1", 1.0),
        caption: [Predictive entropy by Fitzpatrick skin type, binary head (H1), #label.],
      ) #h1_label
    ][
      #figure(
        skintype_violin_for_method(run_type, "head2", 2.0),
        caption: [Predictive entropy by Fitzpatrick skin type, multiclass head (H2), #label.],
      ) #h2_label
    ],
  )
}

#margin_note([
  #pad(
    top: 11mm,
    fitzpatrick_skin_types
      .rev()
      .enumerate()
      .map(((i, label)) => (
        box(
          fill: skin_palette.rev().at(i).transparentize(70%),
          stroke: skin_palette.rev().at(i),
          width: 0.8em,
          height: 0.8em,
          baseline: 15%,
        )
          + h(0.4em)
          + label
      ))
      .join([\  ]),
  )])

#skintype_per_method_pair("dropout", "MC Dropout", <skintype_entropy_violin_dropout_h1>, <skintype_entropy_violin_dropout_h2>)

#skintype_per_method_pair("dropconnect", "DropConnect", <skintype_entropy_violin_dropconnect_h1>, <skintype_entropy_violin_dropconnect_h2>)

#skintype_per_method_pair("flipout", "Flipout", <skintype_entropy_violin_flipout_h1>, <skintype_entropy_violin_flipout_h2>)

#skintype_per_method_pair("duq", "DUQ", <skintype_entropy_violin_duq_h1>, <skintype_entropy_violin_duq_h2>)

#pagebreak()

== Sample Images by Skin Type <skintype_samples_appendix>

Sample images from each Fitzpatrick skin type.

#let skintype_samples_csv = csv("../Notebooks/results/skin_type_samples/sampled_images.csv", row-type: dictionary)
#let skintype_dist_csv = csv(
  "../Notebooks/results/metrics/distribution_test_set_by_fitzpatrick_skin_type.csv",
  row-type: dictionary,
)

#let get_skintype_samples(skin_type) = skintype_samples_csv.filter(row => row.at("skin_type") == skin_type)

#let get_skintype_count(skin_type) = {
  let row = skintype_dist_csv.find(r => r.at("group_value") == skin_type)
  if row != none { row.at("count") } else { "?" }
}

#let skintype_tile(row) = box(
  width: 100%,
  stroke: 0.5pt + gray,
  inset: 0pt,
  clip: true,
  {
    image(row.at("image_path"), width: 100%, height: auto)
  },
)

#figure(
  grid(
    columns: (1fr,) * 6,
    gutter: 2mm,
    ..get_skintype_samples("I").map(row => skintype_tile(row)),
  ),
  caption: flex-caption(
    [Sample images from Fitzpatrick skin type I (N=#get_skintype_count("I")). Very fair skin that always burns and never tans.],
    [Fitzpatrick skin type I samples.],
  ),
) <samples_skintype_I>

#figure(
  grid(
    columns: (1fr,) * 6,
    gutter: 2mm,
    ..get_skintype_samples("II").map(row => skintype_tile(row)),
  ),
  caption: flex-caption(
    [Sample images from Fitzpatrick skin type II (N=#get_skintype_count("II")). Fair skin that usually burns and tans minimally.],
    [Fitzpatrick skin type II samples.],
  ),
) <samples_skintype_II>

#figure(
  grid(
    columns: (1fr,) * 6,
    gutter: 2mm,
    ..get_skintype_samples("III").map(row => skintype_tile(row)),
  ),
  caption: flex-caption(
    [Sample images from Fitzpatrick skin type III (N=#get_skintype_count("III")). Medium skin that sometimes burns and tans uniformly.],
    [Fitzpatrick skin type III samples.],
  ),
) <samples_skintype_III>

#figure(
  grid(
    columns: (1fr,) * 6,
    gutter: 2mm,
    ..get_skintype_samples("IV").map(row => skintype_tile(row)),
  ),
  caption: flex-caption(
    [Sample images from Fitzpatrick skin type IV (N=#get_skintype_count("IV")). Olive skin that rarely burns and tans easily.],
    [Fitzpatrick skin type IV samples.],
  ),
) <samples_skintype_IV>

#figure(
  grid(
    columns: (1fr,) * 6,
    gutter: 2mm,
    ..get_skintype_samples("V").map(row => skintype_tile(row)),
  ),
  caption: flex-caption(
    [Sample images from Fitzpatrick skin type V (N=#get_skintype_count("V")). Brown skin that very rarely burns and tans very easily.],
    [Fitzpatrick skin type V samples.],
  ),
) <samples_skintype_V>

#figure(
  grid(
    columns: (1fr,) * 6,
    gutter: 2mm,
    ..get_skintype_samples("VI").map(row => skintype_tile(row)),
  ),
  caption: flex-caption(
    [Sample images from Fitzpatrick skin type VI (N=#get_skintype_count("VI")). Dark brown to black skin that never burns.],
    [Fitzpatrick skin type VI samples.],
  ),
) <samples_skintype_VI>

== Performance by Lesion Type (Secondary Diagnosis) <lesion_type_performance_appendix>

Detailed accuracy, entropy, and calibration metrics by lesion type across all UQ methods for the binary classification task.

#let lesion_types_appendix = ("Benign", "Melanoma", "Malignant_Epidermal", "Malignant_NonEpidermal", "Other")
#let lesion_labels_appendix = ("Benign", "Melanoma", "Mal. Epid.", "Mal. Non-Ep.", "Other")

#figure(
  {
    let ensemble_acc = collect-group-metric(ensemble_diagnosis2_h1, lesion_types_appendix, "accuracy")
    let dropout_acc = collect-group-metric(dropout_diagnosis2_h1, lesion_types_appendix, "accuracy")
    let dropconnect_acc = collect-group-metric(dropconnect_diagnosis2_h1, lesion_types_appendix, "accuracy")
    let flipout_acc = collect-group-metric(flipout_diagnosis2_h1, lesion_types_appendix, "accuracy")
    let duq_acc = collect-group-metric(duq_diagnosis2_h1, lesion_types_appendix, "accuracy")

    color-table(
      transpose((ensemble_acc, dropout_acc, dropconnect_acc, flipout_acc, duq_acc)),
      lesion_labels_appendix,
      model_labels_short_uq,
      0.50,
      1.00,
      color-fn: white-to-green-color,
    )
  },
  caption: flex-caption(
    [Accuracy by lesion type across UQ methods, binary head (H1).],
    [Accuracy by lesion type, binary head (H1).],
  ),
) <diagnosis2_accuracy_h1>

#figure(
  {
    let ensemble_ent = collect-group-metric(ensemble_diagnosis2_h1, lesion_types_appendix, "mean_predictive_entropy")
    let dropout_ent = collect-group-metric(dropout_diagnosis2_h1, lesion_types_appendix, "mean_predictive_entropy")
    let dropconnect_ent = collect-group-metric(
      dropconnect_diagnosis2_h1,
      lesion_types_appendix,
      "mean_predictive_entropy",
    )
    let flipout_ent = collect-group-metric(flipout_diagnosis2_h1, lesion_types_appendix, "mean_predictive_entropy")
    let duq_ent = collect-group-metric(duq_diagnosis2_h1, lesion_types_appendix, "mean_predictive_entropy")

    color-table(
      transpose((ensemble_ent, dropout_ent, dropconnect_ent, flipout_ent, duq_ent)),
      lesion_labels_appendix,
      model_labels_short_uq,
      0.00,
      0.50,
      color-fn: white-to-red-color,
    )
  },
  caption: flex-caption(
    [Mean predictive entropy by lesion type across UQ methods, binary head (H1).],
    [Mean entropy by lesion type, binary head (H1).],
  ),
) <diagnosis2_entropy_h1>

#figure(
  {
    let ensemble_ece = collect-group-metric(ensemble_diagnosis2_h1, lesion_types_appendix, "ece")
    let dropout_ece = collect-group-metric(dropout_diagnosis2_h1, lesion_types_appendix, "ece")
    let dropconnect_ece = collect-group-metric(dropconnect_diagnosis2_h1, lesion_types_appendix, "ece")
    let flipout_ece = collect-group-metric(flipout_diagnosis2_h1, lesion_types_appendix, "ece")
    let duq_ece = collect-group-metric(duq_diagnosis2_h1, lesion_types_appendix, "ece")

    color-table(
      transpose((ensemble_ece, dropout_ece, dropconnect_ece, flipout_ece, duq_ece)),
      lesion_labels_appendix,
      model_labels_short_uq,
      0.00,
      0.25,
      color-fn: white-to-red-color,
    )
  },
  caption: flex-caption(
    [Expected Calibration Error (ECE) by lesion type across UQ methods, binary head (H1).],
    [ECE by lesion type, binary head (H1).],
  ),
) <diagnosis2_ece_h1>

#pagebreak()

== Sample Images by Lesion Type <lesion_type_samples_appendix>

Sample images from each lesion type (secondary diagnosis).

#let lesion_samples_csv = csv("../Notebooks/results/lesion_type_samples/sampled_images.csv", row-type: dictionary)
#let lesion_dist_csv = csv(
  "../Notebooks/results/metrics/distribution_test_set_by_diagnosis_2.csv",
  row-type: dictionary,
)

#let get_lesion_samples(lesion_type) = lesion_samples_csv.filter(row => row.at("lesion_type") == lesion_type)

#let get_lesion_count(lesion_type) = {
  let row = lesion_dist_csv.find(r => r.at("group_value") == lesion_type)
  if row != none { row.at("count") } else { "?" }
}

#let lesion_tile(row) = box(
  width: 100%,
  stroke: 0.5pt + gray,
  inset: 0pt,
  clip: true,
  {
    image(row.at("image_path"), width: 100%, height: auto)
  },
)

#figure(
  grid(
    columns: (1fr,) * 6,
    gutter: 2mm,
    ..get_lesion_samples("Benign").map(row => lesion_tile(row)),
  ),
  caption: flex-caption(
    [Sample benign lesions (N=#get_lesion_count("Benign")). These include nevi, seborrheic keratoses, and other non-malignant proliferations.],
    [Benign lesion samples.],
  ),
) <samples_benign>

#figure(
  grid(
    columns: (1fr,) * 6,
    gutter: 2mm,
    ..get_lesion_samples("Melanoma").map(row => lesion_tile(row)),
  ),
  caption: flex-caption(
    [Sample melanoma lesions (N=#get_lesion_count("Melanoma")). Malignant melanocytic proliferations with characteristic asymmetry, border irregularity, and color variegation.],
    [Melanoma lesion samples.],
  ),
) <samples_melanoma>

#figure(
  grid(
    columns: (1fr,) * 6,
    gutter: 2mm,
    ..get_lesion_samples("Malignant_Epidermal").map(row => lesion_tile(row)),
  ),
  caption: flex-caption(
    [Sample malignant epidermal lesions (N=#get_lesion_count("Malignant_Epidermal")). Includes squamous cell carcinoma and other epidermal malignancies.],
    [Malignant epidermal lesion samples.],
  ),
) <samples_malignant_epidermal>

#figure(
  grid(
    columns: (1fr,) * 6,
    gutter: 2mm,
    ..get_lesion_samples("Malignant_NonEpidermal").map(row => lesion_tile(row)),
  ),
  caption: flex-caption(
    [Sample malignant non-epidermal lesions (N=#get_lesion_count("Malignant_NonEpidermal")). Primarily basal cell carcinomas and other non-epidermal malignancies.],
    [Malignant non-epidermal lesion samples.],
  ),
) <samples_malignant_nonepidermal>

#figure(
  grid(
    columns: (1fr,) * 6,
    gutter: 2mm,
    ..get_lesion_samples("Other").map(row => lesion_tile(row)),
  ),
  caption: flex-caption(
    [Sample "Other" category lesions (N=#get_lesion_count("Other")). Includes indeterminate proliferations, collision tumors, and inflammatory conditions.],
    ["Other" category lesion samples.],
  ),
) <samples_other>

#pagebreak()

== Performance by Imaging Type <image_type_performance_appendix>

Detailed performance metrics by imaging modality across all UQ methods for the binary classification task.

#let image_type_sorted = image_type_dist.sorted(key: row => -int(row.at("count")))
#let image_types = image_type_sorted.map(row => row.at("group_value"))
#let image_type_labels = image_types.map(t => {
  if t == "dermoscopic" { "Dermoscopic" } else if t == "clinical: close-up" { "Clinical" } else if (
    t == "TBP tile: close-up"
  ) { "TBP Tile" } else { t }
})

#figure(
  {
    let ensemble_acc = collect-group-metric(ensemble_image_type_h1, image_types, "accuracy")
    let dropout_acc = collect-group-metric(dropout_image_type_h1, image_types, "accuracy")
    let dropconnect_acc = collect-group-metric(dropconnect_image_type_h1, image_types, "accuracy")
    let flipout_acc = collect-group-metric(flipout_image_type_h1, image_types, "accuracy")
    let duq_acc = collect-group-metric(duq_image_type_h1, image_types, "accuracy")

    color-table(
      transpose((ensemble_acc, dropout_acc, dropconnect_acc, flipout_acc, duq_acc)),
      image_type_labels,
      model_labels_short_uq,
      0.50,
      1.00,
      color-fn: white-to-green-color,
    )
  },
  caption: flex-caption(
    [Accuracy by imaging type across UQ methods (binary classification). Higher is better.],
    [Accuracy by imaging type.],
  ),
) <image_type_accuracy_h1>

#figure(
  {
    let ensemble_ent = collect-group-metric(ensemble_image_type_h1, image_types, "mean_predictive_entropy")
    let dropout_ent = collect-group-metric(dropout_image_type_h1, image_types, "mean_predictive_entropy")
    let dropconnect_ent = collect-group-metric(
      dropconnect_image_type_h1,
      image_types,
      "mean_predictive_entropy",
    )
    let flipout_ent = collect-group-metric(flipout_image_type_h1, image_types, "mean_predictive_entropy")
    let duq_ent = collect-group-metric(duq_image_type_h1, image_types, "mean_predictive_entropy")

    color-table(
      transpose((ensemble_ent, dropout_ent, dropconnect_ent, flipout_ent, duq_ent)),
      image_type_labels,
      model_labels_short_uq,
      0.00,
      0.50,
      color-fn: white-to-red-color,
    )
  },
  caption: flex-caption(
    [Mean predictive entropy by imaging type across UQ methods (binary classification). Higher values indicate greater uncertainty.],
    [Mean predictive entropy by imaging type.],
  ),
) <image_type_entropy_h1>

#figure(
  {
    let ensemble_ece = collect-group-metric(ensemble_image_type_h1, image_types, "ece")
    let dropout_ece = collect-group-metric(dropout_image_type_h1, image_types, "ece")
    let dropconnect_ece = collect-group-metric(dropconnect_image_type_h1, image_types, "ece")
    let flipout_ece = collect-group-metric(flipout_image_type_h1, image_types, "ece")
    let duq_ece = collect-group-metric(duq_image_type_h1, image_types, "ece")

    color-table(
      transpose((ensemble_ece, dropout_ece, dropconnect_ece, flipout_ece, duq_ece)),
      image_type_labels,
      model_labels_short_uq,
      0.00,
      0.20,
      color-fn: white-to-red-color,
    )
  },
  caption: flex-caption(
    [Expected Calibration Error (ECE) by imaging type across UQ methods (binary classification). Lower is better.],
    [ECE by imaging type.],
  ),
) <image_type_ece_h1>

#pagebreak()

== Sample Images by Imaging Type <image_type_samples_appendix>

Sample images from each imaging modality in the test set.

#let image_type_samples_csv = csv("../Notebooks/results/image_type_samples/sampled_images.csv", row-type: dictionary)

#let get_image_type_samples(img_type) = image_type_samples_csv.filter(row => row.at("image_type") == img_type)

#let get_image_type_count(img_type) = {
  let row = image_type_dist.find(r => r.at("group_value") == img_type)
  if row != none { row.at("count") } else { "?" }
}

#let img_type_tile(row) = box(
  width: 100%,
  stroke: 0.5pt + gray,
  inset: 0pt,
  clip: true,
  {
    image(row.at("image_path"), width: 100%, height: auto)
  },
)

#figure(
  grid(
    columns: (1fr,) * 6,
    gutter: 2mm,
    ..get_image_type_samples("dermoscopic").map(row => img_type_tile(row)),
  ),
  caption: flex-caption(
    [Sample dermoscopic images (N=#get_image_type_count("dermoscopic")).],
    [Dermoscopic image samples.],
  ),
) <samples_dermoscopic>

#figure(
  grid(
    columns: (1fr,) * 6,
    gutter: 2mm,
    ..get_image_type_samples("clinical: close-up").map(row => img_type_tile(row)),
  ),
  caption: flex-caption(
    [Sample clinical close-up images (N=#get_image_type_count("clinical: close-up")).],
    [Clinical close-up image samples.],
  ),
) <samples_clinical>

#figure(
  grid(
    columns: (1fr,) * 6,
    gutter: 2mm,
    ..get_image_type_samples("TBP tile: close-up").map(row => img_type_tile(row)),
  ),
  caption: flex-caption(
    [Sample TBP tile close-up images (N=#get_image_type_count("TBP tile: close-up")).],
    [TBP tile close-up image samples.],
  ),
) <samples_tbp_tile>

#pagebreak()

== Metrics by Difficulty Tier (Full Table) <difficulty_metrics_by_tier_appendix>

#figure(
  {
    let methods = ("dropconnect", "dropout", "duq", "ensemble", "flipout")
    let method_labels = ("DC", "DO", "DUQ", "ENS", "FLP")

    table(
      columns: (auto, auto, auto, auto, auto, auto, auto),
      align: (left, left, right, right, right, right, right),
      stroke: none,
      inset: 4pt,
      [_Tier_], [_Method_], [_N_], [_Acc._], [_Entropy_], [_Conf._], [_OC Rate_],
      table.hline(),
      ..range(5)
        .map(tier => {
          methods
            .zip(method_labels)
            .map(((method, label)) => {
              let row = difficulty_metrics.find(r => (
                r.at("method") == method and r.at("head") == "head1" and r.at("tier") == str(tier)
              ))
              if row != none {
                (
                  [#tier],
                  [#label],
                  [#row.at("n_samples")],
                  [#fmt(to_float(row.at("accuracy")) * 100, decimals: 1)%],
                  [#fmt(to_float(row.at("mean_entropy")), decimals: 3)],
                  [#fmt(to_float(row.at("mean_confidence")) * 100, decimals: 1)%],
                  [#fmt(to_float(row.at("overconfidence_rate")) * 100, decimals: 1)%],
                )
              } else { () }
            })
            .flatten()
        })
        .flatten(),
    )
  },
  caption: flex-caption(
    [Binary head (H1) metrics by leave-one-out difficulty tier per UQ method. For each method, the tier is the number of _other_ methods (0--4) that misclassify the sample.],
    [Binary head (H1) metrics by leave-one-out difficulty tier.],
  ),
) <difficulty_metrics_by_tier_table>

#bibliography("library.bib", style: "ieee")
