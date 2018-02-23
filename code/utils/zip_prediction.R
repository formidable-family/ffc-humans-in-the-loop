library(readr)

zip_prediction <- function(prediction, name, run_file = "run_lasso.R") {
  if (!dir.exists("predictions")) dir.create("predictions")
  
  # write prediction to csv
  pred_path <- file.path("predictions", name)
  if (!dir.exists(pred_path)) dir.create(pred_path)
  write_csv(prediction, file.path(pred_path, "prediction.csv"))
  
  # copy narrative to prediction directory
  narrative <- file.path("narratives", name, "narrative.txt")
  if (file.exists(narrative)) {
    file.copy(narrative, pred_path, overwrite = TRUE)
  } else {
    warning("Please create a narrative.txt file for this prediction: ", name)
  }
  
  # copy code to prediction directory
  file.copy(run_file, pred_path, overwrite = TRUE)
  file.copy("models/lasso.R", pred_path, overwrite = TRUE)
  
  # cd all the way into the directory with the predictions before zipping
  # then move zip file to predictions/ folder for convenience
  # and restore working directory to project root
  setwd(pred_path)
  zip(zipfile = name, files = list.files())
  file.rename(paste0(name, ".zip"), file.path("..", paste0(name, ".zip")))
  setwd("../..")
}
