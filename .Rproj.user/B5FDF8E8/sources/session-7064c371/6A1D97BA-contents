# R/model_utils.R

#' Wrapper to fit and predict using different model engines
#' Supports: lm (Linear), lmer (Mixed Effects), rf (Random Forest)
fit_and_predict <- function(model_type, formula_obj, data_train, data_val, response_var) {
  
  preds <- NULL
  
  # NOTE: We use tryCatch extensively here.
  # Challenge: Categorical variables with rare levels might cause split issues 
  # (e.g., level 'A' is in train but not validation).
  # Strategy: If a model fails due to data mismatch, we return NULL. 
  # The Fitness Function handles NULLs by assigning a high error penalty,
  # effectively teaching the PSO to avoid unstable variables.
  
  if (model_type == "lm") {
    # Simple Linear Model
    fit <- tryCatch(lm(formula_obj, data = data_train), error = function(e) NULL)
    
    if(!is.null(fit)) {
      preds <- tryCatch(predict(fit, newdata = data_val), error = function(e) NULL)
    }
    
  } else if (model_type == "lmer") {
    # Mixed Effects Model
    # 'allow.new.levels = TRUE' handles random effects (GEN) missing in training,
    fit <- tryCatch(
      lme4::lmer(formula_obj, data = data_train, REML = FALSE,
                 control = lme4::lmerControl(calc.derivs = FALSE)),
      error = function(e) NULL, warning = function(w) NULL
    )
    if(!is.null(fit)) {
      preds <- tryCatch(predict(fit, newdata = data_val, allow.new.levels = TRUE), 
                        error = function(e) NULL)
    }
    
  } else if (model_type == "rf") {
    # Random Forest (ranger)
    if(requireNamespace("ranger", quietly = TRUE)) {
      fit <- tryCatch(
        ranger::ranger(formula_obj, data = data_train, num.trees = 100),
        error = function(e) NULL
      )
      if(!is.null(fit)) preds <- predict(fit, data = data_val)$predictions
    }
  }
  
  return(preds)
}

#' Cross-Validation Routine
#' Calculates the average MAE across k-folds
get_cv_error <- function(model_type, formula_str, data, response_var, k = 5) {
  
  # REPRODUCIBILITY:
  # We set a seed inside the function to ensure the folds are identical 
  # for every particle in the swarm. This ensures fair comparison.
  set.seed(6) 
  
  # Create stratified folds if possible
  folds <- caret::createFolds(data[[response_var]], k = k, list = TRUE, returnTrain = FALSE)
  
  mae_list <- c()
  
  for(i in 1:k) {
    # Split Data
    test_idx <- folds[[i]]
    d_train <- data[-test_idx, ]
    d_test  <- data[test_idx, ]
    
    # Define Formula
    form <- as.formula(formula_str)
    
    # Train and Predict
    preds <- fit_and_predict(model_type, form, d_train, d_test, response_var)
    
    if(is.null(preds)) {
      # If model fails we return a massive error. This penalizes the particle.
      return(1e7) 
    }
    
    # Calculate MAE for this fold
    mae_list[i] <- Metrics::mae(d_test[[response_var]], preds)
  }
  
  # Return Average MAE across folds
  return(mean(mae_list))
}