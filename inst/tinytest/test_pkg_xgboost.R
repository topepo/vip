# Exits
if (!requireNamespace("xgboost", quietly = TRUE)) {
  exit_file("Package 'xgboost' missing")
}

# # Load required packages
# suppressMessages({
#   library(xgboost)
# })

# Generate Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)

# Fit model(s)
set.seed(101)
fit <- xgboost::xgboost(  # params found using `autoxgb::autoxgb()`
  data = data.matrix(subset(friedman1, select = -y)),
  label = friedman1$y,
  max_depth = 3,
  eta = 0.1,
  nrounds = 301,
  verbose = 0
)

# Compute VI scores
vis_gain <- vi_model(fit)
vis_cover <- vi_model(fit, type = "cover")
vis_frequency <- vi_model(fit, type = "frequency")
vis_xgboost <- xgboost::xgb.importance(model = fit)

# Expectations for `vi_model()`
expect_identical(
  current = vis_gain$Importance,
  target = vis_xgboost$Gain
)
expect_identical(
  current = vis_cover$Importance,
  target = vis_xgboost$Cover
)
expect_identical(
  current = vis_frequency$Importance,
  target = vis_xgboost$Frequency
)
