<<<<<<< HEAD
library(dplyr)
library(readr)
library(tools)
=======
root_dir <- here::here()
data_dir <- file.path(root_dir, "MAS8600_Dataset")

if (!dir.exists(data_dir)) {
  stop(sprintf(
    "Data directory not found:\n  %s\n",
    data_dir
  ))
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
csv_paths <- csv_paths[!grepl("__MACOSX|/\\._", csv_paths)]

if (length(csv_paths) == 0) {
  stop(sprintf("No CSV files found in:\n  %s", data_dir))
}

datasets <- lapply(csv_paths, readr::read_csv, show_col_types = FALSE)
names(datasets) <- make.names(
  tools::file_path_sans_ext(basename(csv_paths)),
  unique = TRUE
)

#metadata index
dataset_metadata <- data.frame(
  name      = names(datasets),
  path      = csv_paths,
  rows      = vapply(datasets, nrow, integer(1)),
  cols      = vapply(datasets, ncol, integer(1)),
  stringsAsFactors = FALSE
)

message(sprintf("Loaded %d datasets", nrow(dataset_metadata)))
print(head(dataset_metadata[order(-dataset_metadata$rows), ], 10))

schemas <- lapply(datasets, function(df) {
  num_rows <- nrow(df)
  data.frame(
    field       = names(df),
    type        = vapply(df, function(col) class(col)[1], character(1)),
    null_count  = vapply(df, function(col) sum(is.na(col)), integer(1)),
    null_ratio  = if (num_rows == 0) NA_real_ else vapply(df, function(col) mean(is.na(col)), numeric(1)),
    stringsAsFactors = FALSE
  )
})

# Null data
null_stats <- do.call(
  rbind,
  lapply(names(schemas), function(ds_name) {
    schema <- schemas[[ds_name]]
    data.frame(
      dataset           = ds_name,
      total_fields      = nrow(schema),
      fields_with_nulls = sum(schema$null_count > 0),
      max_null_ratio    = if (all(is.na(schema$null_ratio))) NA_real_ else max(schema$null_ratio, na.rm = TRUE),
      stringsAsFactors  = FALSE
    )
  })
)
null_stats <- null_stats[order(-null_stats$max_null_ratio), ]

message("\nNull Value Analysis:")
print(head(null_stats, 10))

event_logs <- grep(
  "(step\\.activity|question\\.response|video\\.stats)",
  names(datasets),
  value = TRUE
)

user_data <- grep(
  "(enrolments|archetype\\.survey|leaving\\.survey|weekly\\.sentiment\\.survey)",
  names(datasets),
  value = TRUE
)

team_data <- grep("(team\\.members)", names(datasets), value = TRUE)

message("\nDataset Categories:")
message(sprintf("  Event logs: %d", length(event_logs)))
message(sprintf("  User data: %d", length(user_data)))
message(sprintf("  Team data: %d", length(team_data)))

cache_dir <- here::here("cache")
dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)

saveRDS(datasets,         file.path(cache_dir, "datasets.rds"))
saveRDS(dataset_metadata, file.path(cache_dir, "metadata.rds"))
saveRDS(schemas,          file.path(cache_dir, "schemas.rds"))
saveRDS(null_stats,       file.path(cache_dir, "null_stats.rds"))
saveRDS(event_logs,       file.path(cache_dir, "event_logs.rds"))
saveRDS(user_data,        file.path(cache_dir, "user_data.rds"))
saveRDS(team_data,        file.path(cache_dir, "team_data.rds"))
>>>>>>> b204572 (fixed git ignore and refactored code)
