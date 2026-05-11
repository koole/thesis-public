// CSV exports (header: label,count) feed the charts and tables below.
// Regenerate them from the Dataset notebook aggregation cell before compiling.

#import "@preview/oxifmt:1.0.0": strfmt

#let data_dir = "content/data" // relative to thesis.typ when compiling

#let clean-label(s) = {
  s.replace("_", " ").replace("NonEpidermal", "Non-Epidermal")
}

#let read-dist(path, label-field: "label", count-field: "count") = {
  let rows = csv(path, row-type: dictionary)
  rows.map(r => (
    "label": clean-label(r.at(label-field)),
    "count": int(r.at(count-field)),
  ))
}

#let dataset_attribution_data = read-dist(data_dir + "/dataset_attribution.csv")
#let primary_diagnosis_distribution_data = read-dist(data_dir + "/primary_diagnosis_distribution.csv")
#let secondary_diagnosis_distribution_data = read-dist(data_dir + "/secondary_diagnosis_distribution.csv")
#let fitzpatrick_skin_type_distribution_data = read-dist(data_dir + "/fitzpatrick_skin_type_distribution.csv")
#let image_type_distribution_data = read-dist(data_dir + "/image_type_distribution.csv")

#let primary_diagnosis_distribution_data_cons = read-dist(data_dir + "/primary_diagnosis_distribution_cons.csv")
#let secondary_diagnosis_distribution_data_cons = read-dist(data_dir + "/secondary_diagnosis_distribution_cons.csv")

#let dataset_split_distribution_data = read-dist(data_dir + "/dataset_split_distribution.csv")
#let primary_diagnosis_train_data = read-dist(data_dir + "/primary_diagnosis_distribution_train_set.csv")
#let primary_diagnosis_val_data = read-dist(data_dir + "/primary_diagnosis_distribution_val_set.csv")
#let primary_diagnosis_test_data = read-dist(data_dir + "/primary_diagnosis_distribution_test_set.csv")

// ---------------------------------------------------------------------------
// Aggregates from the loaded distributions, used to inline dataset counts in
// the thesis text instead of hard-coding numbers.
// ---------------------------------------------------------------------------

#let sum-count(dist) = dist.fold(0, (acc, row) => acc + row.at("count"))

#let total_dataset_images = sum-count(dataset_attribution_data)

#let dataset_source_count = dataset_attribution_data.len()

#let total_fitzpatrick_annotated = sum-count(fitzpatrick_skin_type_distribution_data)

// Guard against divide-by-zero when the CSVs have not been generated yet.
#let fitzpatrick_annotated_pct = if total_dataset_images > 0 {
  calc.round(100 * total_fitzpatrick_annotated / total_dataset_images)
} else { 0 }

#let format-int(n) = {
  strfmt("{}", int(n), fmt-thousands-separator: ",")
}

