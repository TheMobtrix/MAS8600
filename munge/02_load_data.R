<<<<<<< HEAD
<<<<<<< HEAD
library(dplyr)
library(readr)
library(tools)
=======
=======
source("munge/01_libraries.R")
>>>>>>> 2317e90 (added data understanding)
root_dir <- here::here()
data_dir <- file.path(root_dir, "MAS8600_Dataset")

if (!dir.exists(data_dir)) {
  stop(sprintf("Data directory not found:\n  %s", data_dir))
}
>>>>>>> b204572 (fixed git ignore and refactored code)

message("Loading FutureLearn MOOC data...")

data_dir <- "data"

# Get all CSV files
csv_files <- list.files(
  data_dir,
  pattern = "\\.csv$",
  recursive = TRUE,
  full.names = TRUE
)
<<<<<<< HEAD
<<<<<<< HEAD

# Remove macOS artifacts if present
csv_files <- csv_files[!grepl("__MACOSX|/\\._", csv_files)]

if (length(csv_files) == 0) {
  stop(paste0("No CSV files found under:\n  ", data_dir))
}

# Read all CSVs
data_list <- lapply(csv_files, function(f) read_csv(f, show_col_types = FALSE))

# Name objects by file basename
names(data_list) <- make.names(
  file_path_sans_ext(basename(csv_files)),
  unique = TRUE
)

# Create inventory
inventory <- data.frame(
  object_name = names(data_list),
  file_path   = csv_files,
  n_rows      = vapply(data_list, nrow, integer(1)),
  n_cols      = vapply(data_list, ncol, integer(1)),
  stringsAsFactors = FALSE
)

message("Loaded ", nrow(inventory), " tables.")
print(head(inventory[order(-inventory$n_rows), ], 10))

# Cache for reuse
cache("data_list")
cache("inventory")
=======
=======

>>>>>>> 2317e90 (added data understanding)
csv_paths <- csv_paths[!grepl("__MACOSX|/\\._", csv_paths)]
csv_paths <- sort(csv_paths)

if (length(csv_paths) == 0) {
  stop(sprintf("No CSV files found in:\n  %s", data_dir))
}

tables <- lapply(csv_paths, readr::read_csv, show_col_types = FALSE)

names(tables) <- make.names(
  tools::file_path_sans_ext(basename(csv_paths)),
  unique = TRUE
)

if (anyDuplicated(names(tables)) > 0) {
  stop("Name collision detected in table names.")
}

table_index <- data.frame(
  object_name = names(tables),
  file_path   = csv_paths,
  n_rows      = vapply(tables, nrow, integer(1)),
  n_cols      = vapply(tables, ncol, integer(1)),
  stringsAsFactors = FALSE
)

message(sprintf("Loaded %d tables.", nrow(table_index)))
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

event_tables <- grep(
  "(step\\.activity|question\\.response|video\\.stats)",
  names(tables),
  value = TRUE
)

learner_tables <- grep(
  "(enrolments|archetype\\.survey|leaving\\.survey|weekly\\.sentiment\\.survey)",
  names(tables),
  value = TRUE
)

team_tables <- grep("(team\\.members)", names(tables), value = TRUE)

message("\nTable Classification:")
message(sprintf("Event tables: %d", length(event_tables)))
message(sprintf("Learner/survey tables: %d", length(learner_tables)))
message(sprintf("Team tables: %d", length(team_tables)))

cache_dir <- here::here("cache")
dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)

<<<<<<< HEAD
saveRDS(datasets,         file.path(cache_dir, "datasets.rds"))
saveRDS(dataset_metadata, file.path(cache_dir, "metadata.rds"))
saveRDS(schemas,          file.path(cache_dir, "schemas.rds"))
saveRDS(null_stats,       file.path(cache_dir, "null_stats.rds"))
saveRDS(event_logs,       file.path(cache_dir, "event_logs.rds"))
saveRDS(user_data,        file.path(cache_dir, "user_data.rds"))
saveRDS(team_data,        file.path(cache_dir, "team_data.rds"))
>>>>>>> b204572 (fixed git ignore and refactored code)
=======
saveRDS(tables,          file.path(cache_dir, "tables.rds"))
saveRDS(table_index,     file.path(cache_dir, "table_index.rds"))
saveRDS(schema,          file.path(cache_dir, "schema.rds"))
saveRDS(missing_report,  file.path(cache_dir, "missing_report.rds"))
saveRDS(event_tables,    file.path(cache_dir, "event_tables.rds"))
saveRDS(learner_tables,  file.path(cache_dir, "learner_tables.rds"))
saveRDS(team_tables,     file.path(cache_dir, "team_tables.rds"))
>>>>>>> 2317e90 (added data understanding)
