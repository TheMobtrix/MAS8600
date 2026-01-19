source("munge/01_libraries.R")

load_cache <- function(file) {
  readRDS(here::here("cache", file))
}

datasets <- load_cache("tables.rds")
dataset_metadata <- load_cache("table_index.rds")
schemas <- load_cache("schema.rds")
null_stats <- load_cache("missing_report.rds")

parse_run_id <- function(table_names) {
  matches <- stringr::str_match(table_names, "^cyber\\.security\\.(\\d+)_")
  as.integer(matches[, 2])
}

parse_table_type <- function(table_names) {
  stringr::str_replace(table_names, "^cyber\\.security\\.\\d+_", "")
}

inventory <- dataset_metadata %>%
  as_tibble() %>%
  mutate(
    run_id = parse_run_id(object_name),
    table_type = parse_table_type(object_name)
  ) %>%
  arrange(run_id, table_type)

message("Detected runs: ", paste(sort(unique(inventory$run_id)), collapse = ", "))
print(inventory %>% count(table_type, sort = TRUE))
print(head(inventory %>% arrange(desc(n_rows)), 15))
print(head(null_stats, 15))

TARGET_VAR <- "fully_participated_at"

enrolment_datasets <- inventory %>%
  filter(stringr::str_detect(table_type, "enrolments$")) %>%
  arrange(run_id) %>%
  pull(object_name) %>%
  {datasets[.]}

# Check which runs have the target variable
outcome_availability <- tibble(
  dataset = names(enrolment_datasets),
  run_id = parse_run_id(names(enrolment_datasets)),
  has_target = vapply(enrolment_datasets, 
                      function(df) TARGET_VAR %in% names(df), 
                      logical(1))
) %>% 
  arrange(run_id)

print(outcome_availability)

compute_completion_stats <- function(df, table_name) {
  run_id <- parse_run_id(table_name)
  
  learner_id_candidates <- c("learner_id", "learnerID", "user_id")
  learner_col <- intersect(learner_id_candidates, names(df))
  learner_col <- if (length(learner_col) == 0) NA_character_ else learner_col[1]
  
  if (!(TARGET_VAR %in% names(df))) {
    return(tibble(
      run_id = run_id,
      dataset = table_name,
      n_learners = nrow(df),
      n_completed = NA_integer_,
      completion_rate = NA_real_,
      learner_id_col = learner_col
    ))
  }
  
  completed_mask <- !is.na(df[[TARGET_VAR]])
  
  tibble(
    run_id = run_id,
    dataset = table_name,
    n_learners = nrow(df),
    n_completed = sum(completed_mask),
    completion_rate = mean(completed_mask),
    learner_id_col = learner_col
  )
}

completion_stats <- bind_rows(
  lapply(names(enrolment_datasets), function(nm) {
    compute_completion_stats(enrolment_datasets[[nm]], nm)
  })
) %>% 
  arrange(run_id)

print(completion_stats)

common_enrolment_cols <- Reduce(intersect, lapply(enrolment_datasets, names))
message("Common enrolment columns: ", length(common_enrolment_cols))
print(common_enrolment_cols)

get_datasets_by_pattern <- function(pattern) {
  inventory %>%
    filter(stringr::str_detect(table_type, pattern)) %>%
    arrange(run_id) %>%
    pull(object_name)
}

step_activity_tables <- get_datasets_by_pattern("step\\.activity$")
question_response_tables <- get_datasets_by_pattern("question\\.response$")

get_unique_columns <- function(table_names) {
  sort(unique(unlist(lapply(datasets[table_names], names))))
}

step_cols <- get_unique_columns(step_activity_tables)
qr_cols <- get_unique_columns(question_response_tables)

message("Unique step.activity columns: ", length(step_cols))
print(step_cols)

message("Unique question.response columns: ", length(qr_cols))
print(qr_cols)

find_null_columns <- function(table_name) {
  df <- datasets[[table_name]]
  null_cols <- names(df)[vapply(df, function(col) all(is.na(col)), logical(1))]
  
  tibble(
    dataset = table_name,
    run_id = parse_run_id(table_name),
    n_null_cols = length(null_cols),
    null_cols = paste(null_cols, collapse = ", ")
  )
}

null_column_report <- bind_rows(
  lapply(question_response_tables, find_null_columns)
) %>% 
  arrange(run_id)

print(null_column_report)

# ============================================================================
# Key column presence analysis
# ============================================================================
KEY_COLUMNS <- c("learner_id", "step_id", "question_id")

check_key_presence <- function(table_name) {
  cols <- names(datasets[[table_name]])
  tibble(
    has_learner_id = "learner_id" %in% cols,
    has_step_id = "step_id" %in% cols,
    has_question_id = "question_id" %in% cols
  )
}

key_presence <- inventory %>%
  mutate(
    bind_rows(lapply(object_name, check_key_presence))
  ) %>%
  select(run_id, table_type, object_name, starts_with("has_")) %>%
  arrange(run_id, table_type)

print(head(key_presence, 30))

save_cache <- function(obj, filename) {
  saveRDS(obj, here::here("cache", filename))
}

save_cache(inventory, "inventory.rds")
save_cache(completion_stats, "completion_by_run.rds")
save_cache(outcome_availability, "outcome_presence.rds")
save_cache(null_column_report, "question_response_all_na_cols.rds")
save_cache(key_presence, "key_presence.rds")