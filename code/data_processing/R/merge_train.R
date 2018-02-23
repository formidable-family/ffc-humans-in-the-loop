merge_train <- function(background, train) {
  # merges background and training data
  # returns merged data
  background$challengeID <- as.integer(background$challengeID)
  full_join(train, background, by = "challengeID")
}
