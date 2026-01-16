base_dir <- here::here()
data_dir <- file.path(base_dir, "MAS8600_Dataset")
here::here()
list.files(data_dir)

csv_paths <- list.files(
  data_dir,
  pattern = "\\.csv$",
  recursive = TRUE,
  full.names = TRUE
)

csv_paths <- csv_paths[!grepl("__MACOSX|/\\._", csv_paths)]

if (length(csv_paths) == 0) {
  stop(paste0("No CSV files found under:\n  ", data_dir))
}

tables <- lapply(csv_paths, read_csv, show_col_types = FALSE)

names(tables) <- make.names(
  tools::file_path_sans_ext(basename(csv_paths)),
  unique = TRUE
)

if (anyDuplicated(names(tables)) > 0) {
  stop("Name collision detected in tables names.")
}

table_index <- data.frame(
  object_name = names(tables),
  file_path   = csv_paths,
  n_rows      = vapply(tables, nrow, integer(1)),
  n_cols      = vapply(tables, ncol, integer(1)),
  stringsAsFactors = FALSE
)

message("Loaded ", nrow(table_index), " tables.")
print(head(table_index[order(-table_index$n_rows), ], 10))

schema <- lapply(tables, function(tbl) {
  n <- nrow(tbl)
  data.frame(
    variable    = names(tbl),
    class       = vapply(tbl, function(x) class(x)[1], character(1)),
    missing     = vapply(tbl, function(x) sum(is.na(x)), integer(1)),
    missing_pct = if (n == 0) NA_real_ else vapply(tbl, function(x) mean(is.na(x)), numeric(1)),
    stringsAsFactors = FALSE
  )
})
names(schema) <- names(tables)

missing_report <- do.call(
  rbind,
  lapply(names(schema), function(table_name) {
    s <- schema[[table_name]]
    data.frame(
      table             = table_name,
      vars              = nrow(s),
      vars_with_missing = sum(s$missing > 0),
      max_missing_pct   = if (all(is.na(s$missing_pct))) NA_real_ else max(s$missing_pct, na.rm = TRUE),
      stringsAsFactors  = FALSE
    )
  })
)

missing_report <- missing_report[order(-missing_report$max_missing_pct), ]
message("\nMissingness Overview:")
print(head(missing_report, 10))

event_tables <- grep("(step\\.activity|question\\.response|video\\.stats)", names(tables), value = TRUE)
learner_tables <- grep("(enrolments|archetype\\.survey|leaving\\.survey)", names(tables), value = TRUE)

message("\nTable Classification:")
message("Event tables: ", length(event_tables))
message("Learner tables: ", length(learner_tables))


dir.create("cache", showWarnings = FALSE)
saveRDS(tables,         "cache/tables.rds")
saveRDS(table_index,    "cache/table_index.rds")
saveRDS(schema,         "cache/schema.rds")
saveRDS(missing_report, "cache/missing_report.rds")
saveRDS(event_tables,   "cache/event_tables.rds")
saveRDS(learner_tables, "cache/learner_tables.rds")
