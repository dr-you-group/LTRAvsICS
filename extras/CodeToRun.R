library(LTRAvsICS)
library(CohortMethod)
library(dplyr)

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
        createCohorts = FALSE,
        synthesizePositiveControls = TRUE,
        runAnalyses = TRUE,
        packageResults = TRUE,
        maxCores = maxCores)

if (!file.exists(file.path(outputFolder, "revision")))
  dir.create(file.path(outputFolder, "revision"), recursive = TRUE)

cmOutput <- file.path(outputFolder, "cmOutput")
connection <- DatabaseConnector::connect(connectionDetails)

om <- readRDS(file.path(cmOutput, "outcomeModelReference.rds"))

omIr <- om %>%
  as.data.frame() %>%
  filter(analysisId == 9,
         targetId == 1205,
         outcomeId == 989
  )

cmData <- CohortMethod::loadCohortMethodData(file.path(cmOutput, omIr$cohortMethodDataFile))
stratPop <- readRDS(file.path(cmOutput, omIr$strataFile))
stratPop$outcomeStartDate <- as.Date(stratPop$cohortStartDate + stratPop$daysToEvent)

cmDataCohort <- as.data.frame(cmData$cohorts)
mergedPop <- left_join(stratPop, cmDataCohort[,c("rowId", "personId")], by = "rowId")

#### get outcome concept id ####
sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "GetOutcomeCounts.sql",
                                         packageName = "LTRAvsICS",
                                         dbms = connectionDetails$dbms,
                                         vocabulary_database_schema = cdmDatabaseSchema,
                                         cdm_database_schema = cdmDatabaseSchema,
                                         cohort_database_schema = cohortDatabaseSchema,
                                         cohort_table = cohortTable,
                                         target_definition_id = 1205,
                                         comparator_definition_id = 1207)

outcomes <- DatabaseConnector::querySql(connection, sql)
colnames(outcomes) <- SqlRender::snakeCaseToCamelCase(colnames(outcomes))

outcomes$personId <- as.numeric(outcomes$personId)
mergedPop$personId <- as.numeric(mergedPop$personId)

outcomePop <- left_join(mergedPop, outcomes, by = c("personId", "outcomeStartDate"))
outcomePop <- outcomePop %>% filter(outcomeCount >= 1)

#### Classify composite outcome into secondary outcomes #### 
outcomeCf <- read.csv("./outcome_classification.csv")

##### get descendant concept #####
for (i in 1:length(unique(outcomeCf$type))) {
  
  outcomeType <- unique(outcomeCf$type)
  temp <- outcomeCf %>% filter(type == outcomeType[i]) %>% mutate(concept_id = as.numeric(concept_id))
  assign(outcomeType[i], temp)
  
  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "GetDescendants.sql",
                                           packageName = "LTRAvsICS",
                                           dbms = connectionDetails$dbms,
                                           vocabulary_database_schema = cdmDatabaseSchema,
                                           ancestor_concept = get(outcomeType[i])[,"concept_id"])
  
  temp <- DatabaseConnector::querySql(connection, sql)
  assign(paste0(outcomeType[i], "concept"), temp)
  
}

##### Classify outcomes  and count number of outcomes #####
outcomePop <- outcomePop %>% mutate(outcomeType = case_when(conceptId %in% psychoticconcept$CONCEPT_ID ~ "psychotic",
                                                            conceptId %in% moodconcept$CONCEPT_ID ~ "mood",
                                                            conceptId %in% anxietyconcept$CONCEPT_ID ~ "anxiety",
                                                            conceptId %in% sleepconcept$CONCEPT_ID ~ "sleep",
                                                            conceptId %in% cognitiveconcept$CONCEPT_ID ~ "cognitive",
                                                            conceptId %in% movementconcept$CONCEPT_ID ~ "movement",
                                                            conceptId %in% personalityconcept$CONCEPT_ID ~ "personality",
                                                            conceptId %in% otherconcept$CONCEPT_ID ~ "other",
                                                            TRUE ~ NA_character_))

outcomePop <- outcomePop %>% group_by(stratumId, treatment, outcomeType) %>% summarize(numOfEvents = n())

#### Calculate weighted average IR ####
##### Calculate weight #####
stratPop$stratumSizeT <- 1 
strataSizesT <- aggregate(stratumSizeT ~ stratumId, stratPop[stratPop$treatment==1,], sum)
strataSizesC <- aggregate(stratumSizeT ~ stratumId, stratPop[stratPop$treatment==0,], sum)

colnames(strataSizesC)[2] <- "stratumSizeC"
weights <- merge(strataSizesT, strataSizesC)

weights$weight <- weights$stratumSizeT / weights$stratumSizeC
outcomePop <- merge(outcomePop, weights[, c("stratumId", "weight")], by = "stratumId")
outcomePop$weight[outcomePop$treatment == 1] <- 1

personYears <- mergedPop %>% group_by(stratumId, treatment) %>% summarise(survivalTime = sum(survivalTime))
outcomePop <- merge(outcomePop, personYears, by = c("stratumId", "treatment"))

##### Calculate IR for secondary outcomes #####
ir_tab <- outcomePop %>% 
  group_by(treatment, outcomeType) %>%
  summarise(events = sum(numOfEvents * weight),
            py = sum(survivalTime * weight),
            IR = events/py * 1000)
##### Calculate IR for primary outcome #####
ir_full <- mergedPop %>% mutate(outcomeYN = ifelse(outcomeCount >= 1, 1, 0)) %>% group_by(stratumId, treatment) %>%
  summarise(events = sum(outcomeYN),
            survivalTime = sum(survivalTime))

ir_full <- merge(ir_full, weights[, c("stratumId", "weight")], by = "stratumId")
ir_full$weight[ir_full$treatment == 1] <- 1

ir_full <- ir_full %>% 
  group_by(treatment) %>%
  summarise(events = sum(events * weight),
            py = sum(survivalTime * weight),
            IR = events/py * 1000)

ir_full$outcomeType <- "full"
##### Final #####
ir_final <- rbind(ir_full, ir_tab)
write.csv(ir_final, file.path(outputFolder, "revision", "outcome_distribution.csv"), row.names = F)

#### Attrition table befor study population ####
##### ICS #####
sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "ICS_HIRA_attrition.sql",
                                         packageName = "LTRAvsICS",
                                         dbms = connectionDetails$dbms,
                                         vocabulary_database_schema = cdmDatabaseSchema,
                                         cdm_database_schema = cdmDatabaseSchema)

temp <- DatabaseConnector::querySql(connection, sql)

ics_attrition <- temp %>% distinct(PERSON_ID, .keep_all = T) %>% 
  summarise(qualified = n(),
            stage0 = sum(INCLUSION_STAGE_0==0, na.rm = T),
            stage1 = sum(INCLUSION_STAGE_0==0 & INCLUSION_STAGE_1 == 1, na.rm = T),
            stage2 = sum(INCLUSION_STAGE_0==0 & INCLUSION_STAGE_1 == 1 & INCLUSION_STAGE_2 == 2, na.rm = T)) %>%
  mutate(cohort = "ICS")

##### LTRA #####
sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "LTRA_HIRA_attrition.sql",
                                         packageName = "LTRAvsICS",
                                         dbms = connectionDetails$dbms,
                                         vocabulary_database_schema = cdmDatabaseSchema,
                                         cdm_database_schema = cdmDatabaseSchema)

temp <- DatabaseConnector::querySql(connection, sql)

ltra_attrition <- temp %>% distinct(PERSON_ID, .keep_all = T) %>% 
  summarise(qualified = n(),
            stage0 = sum(INCLUSION_STAGE_0==0, na.rm = T),
            stage1 = sum(INCLUSION_STAGE_0==0 & INCLUSION_STAGE_1 == 1, na.rm = T),
            stage2 = sum(INCLUSION_STAGE_0==0 & INCLUSION_STAGE_1 == 1 & INCLUSION_STAGE_2 == 2, na.rm = T)) %>%
  mutate(cohort = "LTRA")

##### Final #####
attrition_final <- rbind(ics_attrition, ltra_attrition)
write.csv(attrition_final, file.path(outputFolder, "revision", "attrition_before_studyPop.csv"), row.names = F)