library(dplyr)
library(readr)
library(tools)

message("Loading FutureLearn MOOC data...")

data_dir <- "data"

# Get all CSV files
csv_files <- list.files(
  data_dir,
  pattern = "\\.csv$",
  recursive = TRUE,
  full.names = TRUE
)

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