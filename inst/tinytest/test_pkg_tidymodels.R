library(vip)

# Exits
if (!requireNamespace("ranger", quietly = TRUE)) {
  exit_file("Package 'ranger' missing")
}
if (!requireNamespace("tidymodels", quietly = TRUE)) {
  exit_file("Package 'tidymodels' missing")
}

# Load required packages
suppressMessages({
  library(ranger)
  library(tidymodels)
})

# FIXME: Switch to data set where we know the actual ranking of the features in
# terms of predictive performance.


################################################################################
# Fit a random forest to some sample data
################################################################################

# Load sample data from 'modeldata' package
data("bivariate")

# Define a 'ranger'-based random forest model
ranger_spec <- rand_forest(trees = 1e3, mode = "classification") %>%
  set_engine("ranger", importance = "impurity")

# Fit models
set.seed(421)  # for reproduicbility
ranger_fit_workflow <-  # worflows
  workflow(Class ~ ., ranger_spec) %>%
  fit(bivariate_train)
ranger_fit_parsnip <-  # parsnip
  ranger_spec %>%
  fit(Class ~ ., data = bivariate_train)

# Extract underlying 'ranger' fits
fit_workflow <- extract_fit_engine(ranger_fit_workflow)
fit_parsnip <- extract_fit_engine(ranger_fit_parsnip)


################################################################################
# Model-based variable importance
################################################################################

# Extract model-based VI scores
vi_mod_workflow <- vi(ranger_fit_workflow)
vi_mod_parsnip <- vi(ranger_fit_parsnip)

# Expect model-based VI scores to be of type "impurity"
expect_identical(attr(vi_mod_workflow, which = "type"), "impurity")
expect_identical(attr(vi_mod_parsnip, which = "type"), "impurity")

# Expect VI scores to be the same (when sorted in decreasing order)
expect_equivalent(vi_mod_workflow$Importance,
                  sort(fit_workflow$variable.importance, decreasing = TRUE))
expect_equivalent(vi_mod_parsnip$Importance,
                  sort(fit_parsnip$variable.importance, decreasing = TRUE))


################################################################################
# Permutation-based (i.e., model-agnostic) variable importance
################################################################################

# Define prediction wrapper for 'workflow' object
pfun <- function(object, newdata) {
  # Get predicted prob for class "One"
  predict(object, new_data = newdata , type = "prob")[[".pred_One"]]
}

# Compute permutation-based VI scores using AUC metric
set.seed(912)  # for reproducibility
vi_auc <- ranger_fit_workflow %>%
  vi(method = "permute",
     target = "Class",
     metric = "auc",
     pred_wrapper = pfun,
     train = bivariate_train,
     reference_class = "One")

# Not always the case, but here we can expect these to be in (0, 1)
expect_true(all(vi_auc$Importance > 0 & vi_auc$Importance < 1))

