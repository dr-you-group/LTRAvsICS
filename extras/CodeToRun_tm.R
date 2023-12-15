library(LTRAvsICS)
library(dplyr)

tm <- read.csv("./cdm_prediction.csv")
tm <- tm %>% filter(prediction == 1)

# Optional: specify where the temporary files (used by the Andromeda package) will be created:
options(andromedaTempFolder = "s:/andromedaTemp")

# Maximum number of cores to be used:
maxCores <- parallel::detectCores()

# The folder where the study intermediate and result files will be written:
outputFolder <- "s:/LTRAvsICS"

# Details for connecting to the server:
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "",
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
databaseId <- "Synpuf"
databaseName <- "Medicare Claims Synthetic Public Use Files (SynPUFs)"
databaseDescription <- "Medicare Claims Synthetic Public Use Files (SynPUFs) were created to allow interested parties to gain familiarity using Medicare claims data while protecting beneficiary privacy. These files are intended to promote development of software and applications that utilize files in this format, train researchers on the use and complexities of Centers for Medicare and Medicaid Services (CMS) claims, and support safe data mining innovations. The SynPUFs were created by combining randomized information from multiple unique beneficiaries and changing variable values. This randomization and combining of beneficiary information ensures privacy of health information."

# For Oracle: define a schema that can be used to emulate temp tables:
oracleTempSchema <- NULL


## Step 1: Cohort generation excpet for text-mining result based outcome corhot
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
        synthesizePositiveControls = FALSE,
        runAnalyses = FALSE,
        packageResults = FALSE,
        maxCores = maxCores)

# OutcomeTM : Need to preprocessing text-mining results to compatible with the table generated in Step 1
# Column 1 - COHORT_DEFINITION_ID: cohortId of text mining based outcome cohort ex)500
# Column 2 - SUBJECT_ID: ptno in tm & person_id in person table that can be used to merge clinical notes and CDM database
# Column 3 - COHORT_START_DATE: clinical notes created date in tm table
# Column 4 - COHORT_END_DATE: same as COHORT_START_DATE


outcomTm <- data.frame(COHORT_DEFINITION_ID = 500,
                       SUBJECT_ID = tm$ptno,
                       COHORT_START_DATE = tm$createdDate,
                       COHORT_END_DATE = tm$createdDate,)

conn <- DatabaseConnector::connect(connectionDetails)

DatabaseConnector::insertTable(connection = conn,
                               databaseSchema = cohortDatabaseSchema,
                               tableName = cohortTable,
                               data = outcomeTm,
                               dropTableIfExists = F,
                               createTable = F)

## you need to change and upload some files

tcos <- read.csv("./inst/settings/TcosOfInterest.csv")
tcos[,"outcomeIds"] <- "500;989"

write.csv(tcos, "./inst/settings/TcosOfInterest.csv", row.names = F)

cohortList <- read.csv("./inst/settings/CohortsToCreate.csv")

cohortList[6,] <- c(500, "[LTRAvsICS] text mining", 500, "LTRAvsICS_text_mining")
write.csv(cohortList, "./inst/settings/CohortsToCreate.csv", row.names = F)

## And then, you need to copy and paste the json file of outcomeCohorts (./inst/settings/Cohorts/LTRAvsICS_Neuropsychiatric_event_v3.json)
## in ./inst/settings/Cohorts and rename it as LTRAvsICS_text_mining.json

## If you finish your insert your textmining outcome cohorts in the cohortTable, Please Install and Restart again and go to Step 2


## Step 2
execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        oracleTempSchema = oracleTempSchema,
        outputFolder = outputFolder,
        databaseId = databaseId,
        databaseName = databaseName,
        databaseDescription = databaseDescription,
        createCohorts = FALSE,
        synthesizePositiveControls = TRUE,
        runAnalyses = TRUE,
        packageResults = TRUE,
        maxCores = maxCores)


resultsZipFile <- file.path(outputFolder, "export", paste0("Results_", databaseId, ".zip"))
dataFolder <- file.path(outputFolder, "shinyData")

# You can inspect the results if you want:
prepareForEvidenceExplorer(resultsZipFile = resultsZipFile, dataFolder = dataFolder)
launchEvidenceExplorer(dataFolder = dataFolder, blind = FALSE, launch.browser = FALSE)

# Upload the results to the OHDSI SFTP server:
privateKeyFileName <- ""
userName <- ""
uploadResults(outputFolder, privateKeyFileName, userName)
