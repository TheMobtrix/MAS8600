enrol_tables <- grep("enrolments", names(tables), value = TRUE)


enrolments_list <- lapply(enrol_tables, function(table_name) {
  df <- tables[[table_name]]
  run_id <- sub(".*cyber\\.security\\.(\\d+).*", "\\1", table_name)
  df$run <- as.integer(run_id)
  df
})

learner_spine <- bind_rows(enrolments_list)

learner_spine <- learner_spine %>%
  mutate(
    enrolled_at = ymd_hms(enrolled_at, quiet = TRUE),
    unenrolled_at = ymd_hms(unenrolled_at, quiet = TRUE),
    fully_participated_at = ymd_hms(fully_participated_at, quiet = TRUE)
  )

learner_spine <- learner_spine %>%
  mutate(
    completed = if_else(!is.na(fully_participated_at), 1, 0)
  )

message("Learner spine created: ", nrow(learner_spine), " learners across ", 
        n_distinct(learner_spine$run), " runs")
message("Overall completion rate: ", round(mean(learner_spine$completed) * 100, 2), "%")
saveRDS(learner_spine, "cache/learner_spine.rds")
