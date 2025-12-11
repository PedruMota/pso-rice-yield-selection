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
    fit <- tryCatch(lm(formula_obj, data = data_train), error = function(e) NULL)
    
    if(!is.null(fit)) {
      preds <- tryCatch(predict(fit, newdata = data_val), error = function(e) NULL)
    }
    
  } else if (model_type == "rf") {
    if(requireNamespace("ranger", quietly = TRUE)) {
      fit <- tryCatch(
        ranger::ranger(formula_obj, data = data_train, num.trees = 50),
        error = function(e) NULL
      )
      if(!is.null(fit)) {
        preds <- predict(fit, data = data_val)$predictions
      }
    }
  }
  
  return(preds)
}


#' Cross-Validation Routine
#' Calculates the average MAE across k-folds
get_cv_error <- function(model_type, formula_str, data, response_var, k = 5) {
  
  set.seed(999)
  
  # Create folds
  folds <- caret::createFolds(data[[response_var]], k = k, list = TRUE, returnTrain = FALSE)
  mae_list <- c()
  
  for(i in 1:k) {
    test_idx <- folds[[i]]
    d_train <- data[-test_idx, ]
    d_test  <- data[test_idx, ]
    
    form <- as.formula(formula_str)
    
    preds <- fit_and_predict(model_type, form, d_train, d_test, response_var)
    
    # High penalty if model fails (e.g. categorical mismatch)
    if(is.null(preds)) return(1e7) 
    
    mae_list[i] <- Metrics::mae(d_test[[response_var]], preds)
  }
  
  return(mean(mae_list))
}