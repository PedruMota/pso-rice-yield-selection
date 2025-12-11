# ==============================================================================
# PROJECT: Feature Selection using PSO with Warm Start & Cross-Validation
# AUTHOR: Pedro Mota
# YEAR: 2025
#
# NOTE ON METHODOLOGY:
# 1. Prediction Focus: We prioritize predictive accuracy (MAE) over statistical
#    inference assumptions (normality, homoscedasticity).
# 2. Reproducibility: 'set.seed' is used to ensure consistent folds and warm starts.
# 3. Categorical Variables: The algorithm automatically penalizes variables with
#    rare levels that cause instability during Cross-Validation splits.
# 4. Regularization: We use a manual penalty factor to control the trade-off
#    between model accuracy and model complexity (number of features).
# ==============================================================================

# 1. Setup ---------------------------------------------------------------------
if(!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(tidyverse, pso, Metrics, xgboost, ranger, here, caret)

# Global Seed for Reproducibility
set.seed(6)

# Load helper scripts
if (!file.exists(here("data", "train_data.csv"))) {
  source(here("R", "generate_synthetic.R"))
  generate_synthetic_data() 
}
source(here("R", "process_data.R"))
source(here("R", "model_utils.R"))

# 2. Data Preparation ----------------------------------------------------------
raw_data <- read_csv(here("data", "train_data.csv"), show_col_types = FALSE)
data_full <- process_data(raw_data)

# HOLD-OUT STRATEGY (To avoid Overfitting)
# We reserve 30% of data purely for final validation. 
# The PSO never sees this data, preventing "Selection Bias".
idx <- createDataPartition(data_full$GY, p = 0.7, list = FALSE)
data_train <- data_full[idx, ]
data_test  <- data_full[-idx, ]

# 3. Configuration -------------------------------------------------------------
RESPONSE_VAR <- "GY"
MODEL_TYPE   <- "rf" # Options: "lm", "rf"

# Dynamic Penalty
# We calculate the Standard Deviation of the target variable in the training set.
sd_y <- sd(data_train[[RESPONSE_VAR]], na.rm = TRUE)

# We define the penalty as a percentage of the data variability.
# It means a variable must explain at least ~1.5% of the remaining variance to be kept.
PENALTY_FACTOR <- 0.015
COMPLEXITY_PENALTY <- sd_y * PENALTY_FACTOR

# Define Candidate Variables (Exclude metadata and response)
ignore_vars <- c(RESPONSE_VAR, "GEN", "LOC", "ST", "YEAR") 
candidate_vars <- setdiff(names(data_train), ignore_vars)
n_vars <- length(candidate_vars)

# 4. Warm Start (Smart Initialization) --------------------------
# Heuristic: Identify linear correlations to guide initial particles
num_vars <- candidate_vars[sapply(data_train[candidate_vars], is.numeric)]
cor_vals <- abs(cor(data_train[num_vars], data_train[[RESPONSE_VAR]], use="complete.obs"))

# Select potential top predictors
top_5 <- rownames(cor_vals)[order(cor_vals, decreasing = TRUE)][1:5]

# Create a "Best Guess" vector (Warm Start)
par_init <- rep(0, n_vars)

if(length(top_5) > 0) {
  idx_10 <- match(top_5, candidate_vars)
  par_init[idx_10] <- 1
}


# 5. Fitness Function (Wrapper) ------------------------------------------------
fitness_wrapper <- function(x) {
  
  selected_vars <- candidate_vars[x >= 0.5]
  if(length(selected_vars) == 0) return(1e7)
  
  fixed_part <- paste(selected_vars, collapse = " + ")
  form_str <- paste(RESPONSE_VAR, "~", fixed_part)
  
  # k=5 for robustness
  cv_mae <- get_cv_error(MODEL_TYPE, form_str, data_train, RESPONSE_VAR, k = 5)
  
  penalty <- length(selected_vars) * COMPLEXITY_PENALTY 
  return(cv_mae + penalty)
}

# 6. Run PSO -------------------------------------------------------------------
message(paste("Starting Optimization using:", MODEL_TYPE))
message("Strategy: Warm Start + 5-Fold CV + Complexity Penalty")

pso_res <- psoptim(
  par = par_init,
  fn = fitness_wrapper,
  lower = rep(0, n_vars),
  upper = rep(1, n_vars),
  control = list(maxit = 80, s = 30, trace = 1) 
)

# 7. Final Evaluation ----------------------------------------------------------
best_sol <- round(pso_res$par)
final_vars <- candidate_vars[best_sol == 1]

cat("\n==============================================\n")
cat("Total Variables Selected:", length(final_vars), "\n")
cat("Selected Variables:", paste(final_vars, collapse = ", "), "\n")


# Train Final Model on full Training Set and Test on unseen Holdout Set
final_fixed <- paste(final_vars, collapse = " + ")
if(MODEL_TYPE == "lmer") {
  final_form <- as.formula(paste(RESPONSE_VAR, "~", final_fixed, "+ (1|GEN)"))
} else {
  final_form <- as.formula(paste(RESPONSE_VAR, "~", final_fixed))
}

# Calculate Final Holdout Error
# We reuse fit_and_predict logic but manually here for clarity
preds_test <- fit_and_predict(MODEL_TYPE, final_form, data_train, data_test, RESPONSE_VAR)

if(!is.null(preds_test)){
  cat("Final Holdout MAE:", mae(data_test[[RESPONSE_VAR]], preds_test), "\n")
} else {
  cat("Final model failed validation due to data consistency issues.\n")
}


# 8. Export Results & Artifacts ------------------------------------------------

# Ensure output directory exists
if(!dir.exists(here("output"))) dir.create(here("output"))

# Save Optimization Results (PSO)
# Saves the raw output from the algorithm (convergence, history, best par)
saveRDS(pso_res, here("output", paste0("pso_results_", MODEL_TYPE, ".rds")))
message(paste0("PSO optimization results saved to output/pso_results_", MODEL_TYPE,".rds"))

# Retrain & Save Final Model Object ---
# We explicitly refit the model on the training set to create a deploy-able artifact.
message("Retraining final model object for export...")

final_model_obj <- NULL

if (MODEL_TYPE == "lmer") {
  final_model_obj <- lme4::lmer(final_form, data = data_train, REML = FALSE)
} else if (MODEL_TYPE == "rf") {
  if(requireNamespace("ranger", quietly = TRUE)) {
    final_model_obj <- ranger::ranger(final_form, data = data_train, num.trees = 100)
  }
} else {
  final_model_obj <- lm(final_form, data = data_train)
}

# Save Model Artifact to disk
if (!is.null(final_model_obj)) {
  filename <- paste0("final_model_", MODEL_TYPE, ".rds")
  output_path <- here("output", filename)
  
  saveRDS(final_model_obj, output_path)
  message(paste("Final model artifact saved successfully to:", output_path))
  
} else {
  warning("Could not save the final model object due to training failure.")
}

message("\n=== PROJECT EXECUTION COMPLETED SUCCESSFULLY ===")
