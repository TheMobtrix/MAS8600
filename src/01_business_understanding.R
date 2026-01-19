source("munge/01_libraries.R")

setup_project_dirs <- function(base_dir = here::here()) {
  dirs <- c("models", "reports", "cache")
  invisible(lapply(file.path(base_dir, dirs), dir.create, 
                   showWarnings = FALSE, recursive = TRUE))
}

setup_project_dirs()

create_project_config <- function() {
  cfg <- list(
    paths = list(
      root = here::here(),
      data = here::here("MAS8600_Dataset"),
      cache = here::here("cache")
    ),
    target = list(
      table = "enrolments",
      var = "fully_participated_at",
      positive = "completed"
    ),
    features = list(
      cutoff = "week_1_only"
    ),
    metrics = list(
      primary = "roc_auc",
      secondary = c("pr_auc", "accuracy", "sens", "spec")
    )
  )
  
  if (!dir.exists(cfg$paths$data)) {
    stop(sprintf("Dataset directory not found: %s", cfg$paths$data))
  }
  
  cfg
}

project_cfg <- create_project_config()
saveRDS(project_cfg, file.path(project_cfg$paths$cache, "project_cfg.rds"))