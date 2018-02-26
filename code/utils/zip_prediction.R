library(readr)

zip_prediction <- function(prediction, name, run_file = "run_lasso.R") {
  if (!dir.exists("output/predictions")) { 
    dir.create("output/predictions", recursive = TRUE) 
  }
  
  if (!dir.exists("output/predictions/zipped")) { 
    dir.create("output/predictions/zipped", recursive = TRUE) 
  }
  
  # write prediction to csv
  pred_path <- file.path("output", "predictions", name)
  if (!dir.exists(pred_path)) dir.create(pred_path)
  write_csv(prediction, file.path(pred_path, "prediction.csv"))
  
  # copy narrative to prediction directory
  narrative <- file.path("doc", "narratives", name, "narrative.txt")
  if (file.exists(narrative)) {
    file.copy(narrative, pred_path, overwrite = TRUE)
  } else {
    warning("Please create a narrative.txt file for this prediction: ", name)
  }
  
  # copy code to prediction directory
  file.copy(file.path("code", "runs", run_file), pred_path, overwrite = TRUE)
  file.copy("code/models/lasso.R", pred_path, overwrite = TRUE)
  
  # cd all the way into the directory with the predictions before zipping
  # then move zip file to predictions/ folder for convenience
  # and restore working directory to project root
  zip(zipfile = file.path(pred_path, name), 
      files = list.files(pred_path, recursive = TRUE))
  file.rename(file.path(pred_path, paste0(name, ".zip")), 
              file.path("output", "predictions", "zipped", paste0(name, ".zip")))
}
