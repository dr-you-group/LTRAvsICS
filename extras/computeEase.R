shinyFolder <- "./inst/shiny/EvidenceExplorer/ShinyData"
cohortMethodResultList <- list.files(shinyFolder, "^cohort_method_result.*.rds$", full.names = TRUE)
ncsList <- list.files(shinyFolder, "^negative_control_outcome.*.rds$", full.names = TRUE)
ncs <- readRDS(file.path(ncsList))
loadShinyResults <- function(shinyFile){
  results<-readRDS(shinyFile)
  colnames(results) <- SqlRender::snakeCaseToCamelCase(colnames(results))
  colnames(results)[colnames(results) == "ci95lb"] <- "ci95Lb"
  colnames(results)[colnames(results) == "ci95ub"] <- "ci95Ub"
  ncs <- readRDS(gsub("cohort_method_result","negative_control_outcome",shinyFile))
  colnames(ncs) <- SqlRender::snakeCaseToCamelCase(colnames(ncs))
  results$trueEffectSize <- NA
  idx <- results$outcomeId %in% ncs$outcomeId
  results$trueEffectSize[idx] <- 1
  return(results)
}
allResults <- lapply(cohortMethodResultList,loadShinyResults)
allResults <- do.call(rbind, allResults)
groups <- split(allResults, paste(allResults$targetId, allResults$comparatorId, allResults$analysisId))
computeEase <- function(singleCohortMethodResult) {
  index <-
    !is.na(singleCohortMethodResult$logRr) &
    !is.na(singleCohortMethodResult$seLogRr)
  negativeData<-singleCohortMethodResult[index & singleCohortMethodResult$outcomeId %in% unique(ncs$outcome_id),]
  if(nrow(negativeData) >= 5) {
    null<-EmpiricalCalibration::fitMcmcNull(negativeData$logRr,
                                            negativeData$seLogRr)
    ease <- EmpiricalCalibration::computeExpectedAbsoluteSystematicError(null)$ease
  } 
  else {
    ease <- NA
  }
  results <- list(targetId = unique(singleCohortMethodResult$targetId),
                  comparatorId = unique(singleCohortMethodResult$comparatorId),
                  analysisId = unique(singleCohortMethodResult$analysisId),
                  ease = ease)
  return(results)
}
results <- lapply(groups, computeEase)
results <- do.call(rbind.data.frame, results)
row.names(results) <- 1:nrow(results)
results$databaseId <- ""