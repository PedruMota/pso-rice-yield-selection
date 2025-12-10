# ==============================================================================
# PROJECT: Feature Selection using PSO with Warm Start & Cross-Validation
# AUTHOR: [Your Name]
# YEAR: 2024
#
# NOTE ON METHODOLOGY:
# 1. Prediction Focus: We prioritize predictive accuracy (MAE) over statistical
#    inference assumptions (normality, homoscedasticity).
# 2. Reproducibility: 'set.seed' is used to ensure consistent folds and warm starts.
# 3. Categorical Variables: The algorithm automatically penalizes variables with
#    rare levels that cause instability during Cross-Validation splits.
# ==============================================================================

# 1. Setup ---------------------------------------------------------------------
if(!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(tidyverse, pso, Metrics, lme4, ranger, here, caret)

# Global Seed for Reproducibility
set.seed(123)

# Load helper scripts
if (!file.exists(here("data", "train_data.csv"))) {
  source(here("R", "generate_synthetic.R"))
  generate_synthetic_data() 
}
source(here("R", "process_data2.R"))
source(here("R", "model_utils.R"))

# 2. Data Preparation ----------------------------------------------------------
raw_data <- read_csv(here("data", "train_data.csv"), show_col_types = FALSE)
data_full <- process_data(raw_data)

# HOLD-OUT STRATEGY (To avoid Overfitting)
# We reserve 20% of data purely for final validation. 
# The PSO never sees this data, preventing "Selection Bias".
idx <- createDataPartition(data_full$GY, p = 0.8, list = FALSE)
data_train <- data_full[idx, ]
data_test  <- data_full[-idx, ]

# 3. Configuration -------------------------------------------------------------
RESPONSE_VAR <- "GY"
MODEL_TYPE   <- "lmer" # Options: "lm", "lmer", "rf"

# Define Candidate Variables (Exclude metadata and response)
ignore_vars <- c(RESPONSE_VAR, "GEN", "LOC", "ST", "YEAR") 
candidate_vars <- setdiff(names(data_train), ignore_vars)
n_vars <- length(candidate_vars)

# 4. Improvement A: WARM START (Smart Initialization) --------------------------
message("Initializing Warm Start Particles...")

# Heuristic: Identify linear correlations to guide initial particles
num_vars <- candidate_vars[sapply(data_train[candidate_vars], is.numeric)]
cor_vals <- abs(cor(data_train[num_vars], data_train[[RESPONSE_VAR]], use="complete.obs"))

# Select potential top predictors
top_5  <- rownames(cor_vals)[order(cor_vals, decreasing = TRUE)][1:5]
top_10 <- rownames(cor_vals)[order(cor_vals, decreasing = TRUE)][1:10]

# Swarm Configuration
pop_size <- 40
pop_init <- matrix(runif(pop_size * n_vars), nrow = pop_size, ncol = n_vars)

# Inject Knowledge into specific particles
if(length(top_5) > 0) {
  idx_5 <- match(top_5, candidate_vars)
  pop_init[1, ] <- 0 
  pop_init[1, idx_5] <- 1
}
if(length(top_10) > 0) {
  idx_10 <- match(top_10, candidate_vars)
  pop_init[2, ] <- 0
  pop_init[2, idx_10] <- 1
}

# 5. Fitness Function (Wrapper) ------------------------------------------------
fitness_wrapper <- function(x) {
  
  # Decode binary selection
  selected_vars <- candidate_vars[x >= 0.5]
  
  # Hard constraint: Model must have at least one variable
  if(length(selected_vars) == 0) return(1e7)
  
  # Construct Formula
  fixed_part <- paste(selected_vars, collapse = " + ")
  
  if(MODEL_TYPE == "lmer") {
    # Adding Random Effect for Genotype
    form_str <- paste(RESPONSE_VAR, "~", fixed_part, "+ (1|GEN)")
  } else {
    form_str <- paste(RESPONSE_VAR, "~", fixed_part)
  }
  
  # Call Cross-Validation (Robust Evaluation)
  cv_mae <- get_cv_error(MODEL_TYPE, form_str, data_train, RESPONSE_VAR, k = 3)
  
  # Complexity Penalty (Occam's Razor)
  # Balances accuracy vs model size
  penalty <- length(selected_vars) * 2 
  
  return(cv_mae + penalty)
}

# 6. Run PSO -------------------------------------------------------------------
message(paste("Starting Optimization using:", MODEL_TYPE))
message("Strategy: Warm Start + 3-Fold CV + Complexity Penalty")

pso_res <- psoptim(
  par = rep(0, n_vars),
  fn = fitness_wrapper,
  lower = rep(0, n_vars),
  upper = rep(1, n_vars),
  pop.init = pop_init, 
  control = list(maxit = 20, s = pop_size, trace = 1) 
)

# 7. Final Evaluation ----------------------------------------------------------
best_sol <- round(pso_res$par)
final_vars <- candidate_vars[best_sol == 1]

cat("\n==============================================\n")
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

# Save Result
if(!dir.exists(here("output"))) dir.create(here("output"))
saveRDS(pso_res, here("output", "pso_results.rds"))
message("Optimization finished.")