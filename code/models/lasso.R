library(glmnet)

lasso <- function(data, outcome, covariates, 
                  scores = NULL, 
                  family = "gaussian", 
                  test_indices = NULL,
                  x_cache = NULL,
                  x_pred_cache = NULL, ...) {
  
  # validation of input
  if (!is.null(scores)) {
    # only use scores for covariates that are in the provided data
    scores <- scores[which(covariates %in% colnames(data))]
  }
  # only use covariates that are in the provided data
  covariates <- covariates[covariates %in% colnames(data)]
  
  # if withholding part of data as a test set, 
  # set those outcomes to NA before creating model matrix
  if (!is.null(test_indices)) {
    test_outcomes <- data[[outcome]][test_indices]
    data[[outcome]][test_indices] <- NA
  }
  
  # build covariate matrix and response vector
  f <- as.formula(paste0(outcome, " ~ ", paste0(covariates, collapse = " + ")))
  d <- model.frame(f, data)
  x <- if(is.null(x_cache)) sparse.model.matrix(f, data = d)[, -1] else x_cache
  y <- d[[outcome]]
  
  # if scores are provided, convert to penalties for penalty.factor
  # else use default penalty.factor of 1 for all covariates
  penalties <- 
    if (!is.null(scores)) {
      calculate_penalty_factors(colnames(x), covariates, scores)
    } else {
      rep(1, length(colnames(x)))
    }

  # fit lasso model
  # alpha = 1 by default
  # (alpha is the mixing parameter for elastic net, so 1 = lasso)
  model_fit <- 
    cv.glmnet(x = x, y = y, 
              family = family, 
              type.measure = "mse", 
              penalty.factor = penalties, 
              ...)
  
  # predict responses for outcome
  # don't want to drop NAs here
  # https://stackoverflow.com/a/31949950
  x_pred <- 
    if(is.null(x_pred_cache)) {
      sparse.model.matrix(f, data = model.frame(~ ., data, na.action = na.pass))[, -1]
    } else {
      x_pred_cache
    }
  pred <- predict(model_fit, newx = x_pred, s = "lambda.min", type = "response")
  
  # in-sample mean squared error
  mse <- mean((data[[outcome]] - pred)^2, na.rm = TRUE)
  print(paste0("in-sample mse for ", outcome, ": ", 
               formatC(mse, digits = 5, format = "f")))
  
  # if withholding part of data as test set, 
  # calculate out-of-sample mean squared error on test set
  if (!is.null(test_indices)) {
    test_mse <- mean((test_outcomes - pred[test_indices])^2, na.rm = TRUE)
    print(paste0("test mse for ", outcome, ": ", 
                 formatC(test_mse, digits = 5, format = "f")))
  } else {
    test_mse <- NULL
  }

  # pred
  list(pred = pred, mse = mse, model = model_fit, formula = f, test_mse = test_mse)
}
