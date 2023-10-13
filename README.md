LTRAvsICS
==============================


Requirements
============

- A database in [Common Data Model version 5](https://github.com/OHDSI/CommonDataModel) in one of these platforms: SQL Server, Oracle, PostgreSQL, IBM Netezza, Apache Impala, Amazon RedShift, Google BigQuery, or Microsoft APS.
- R version 3.5.0 or newer
- On Windows: [RTools](http://cran.r-project.org/bin/windows/Rtools/)
- [Java](http://java.com)
- 25 GB of free disk space

How to run
==========
1. Open your study package in RStudio. Use the following code to deactivate the renv

	```r
	renv::deactivate()
	```

2. In RStudio, select 'Build' then 'Install and Restart' to build the package.

3. Once installed, you can execute the study by modifying and using the code below. For your convenience, this code is also provided under `extras/CodeToRun.R`:

	```r
	library(LTRAvsICS)

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

	```

4. Share the file ```export/Results_<DatabaseId>.zip``` in the output folder to the study coordinator:

License
=======
The LTRAvsICS package is licensed under Apache License 2.0

Development
===========
LTRAvsICS was developed in ATLAS and R Studio.

### Development status

Unknown
