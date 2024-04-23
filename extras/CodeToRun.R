library(LTRAvsICS)
library(CohortMethod)

renv::deactivate()

# Optional: specify where the temporary files (used by the Andromeda package) will be created:
options(andromedaTempFolder = "s:/andromedaTemp")

# Maximum number of cores to be used:
maxCores <- parallel::detectCores()

# The folder where the study intermediate and result files will be written:
outputFolder <- "s:/LTRAvsICS"

# Details for connecting to the server:
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "pdw",
                                                                server = Sys.getenv("PDW_SERVER"),
                                                                user = NULL,
                                                                password = NULL,
                                                                port = Sys.getenv("PDW_PORT"))

# The name of the database schema where the CDM data can be found:
cdmDatabaseSchema <- "CDM_IBM_MDCD_V1153.dbo"

# The name of the database schema and table where the study-specific cohorts will be instantiated:
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "mschuemi_skeleton"

# Some meta-information that will be used by the export function:
databaseId <- "HIRA"
databaseName <- "HIRA"
databaseDescription <- "HIRA"

# For Oracle: define a schema that can be used to emulate temp tables:
oracleTempSchema <- NULL

execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        oracleTempSchema = oracleTempSchema,
        outputFolder = outputFolder,
        databaseId = databaseId,
        databaseName = databaseName,
        databaseDescription = databaseDescription,
        createCohorts = TRUE,
        synthesizePositiveControls = TRUE,
        runAnalyses = TRUE,
        packageResults = TRUE,
        maxCores = maxCores)


omr <- readRDS(file.path(outputFolder, "cmOutput", "outcomeModelReference.rds"))
tcos <- read.csv(system.file("settings", "TcosOfInterest.csv", package = "LTRAvsICS"))
analysisIdList <- unique(omr$analysisId)

computePreferenceScore <- function (data, unfilteredData = NULL) {
        
        if (is.null(unfilteredData)) {
                proportion <- sum(data$treatment)/nrow(data)
        }
        else {
                proportion <- sum(unfilteredData$treatment)/nrow(unfilteredData)
        }
        propensityScore <- data$propensityScore
        propensityScore[propensityScore > 0.9999999] <- 0.9999999
        x <- exp(log(propensityScore/(1 - propensityScore)) - log(proportion/(1 - proportion)))
        data$preferenceScore <- x/(x + 1)
        return(data)
}

psResult <- data.frame()

for (i in 1:nrow(tcos)) {
        target <- tcos$targetId[i]
        comparator <- tcos$comparatorId[i]
        outcome <- tcos$outcomeIds[i]
        
        for (j in analysisIdList) {
                
                psFile <- omr %>% filter(targetId == target & comparatorId == comparator & outcomeId == outcome & analysisId == j)
                ps <- readRDS(file.path(outputFolder, "cmOutput", psFile$psFile))
                ps <- computePreferenceScore(ps)
                auc <- CohortMethod::computePsAuc(ps)
                equipoise <- mean(ps$preferenceScore >= 0.3 & ps$preferenceScore <= 0.7)
                
                temp <- data.frame(targetId = target,
                                   comparatorId = comparator,
                                   outcomeId = outcome,
                                   analysisId = j,
                                   auc = auc,
                                   equipoise = equipoise)
                
                psResult <- rbind(psResult, temp)
        }
        
}

write.csv(psResult, file.path(outputFolder, "export", "psResult.csv"), row.names = F)