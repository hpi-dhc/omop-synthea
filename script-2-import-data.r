# Loading the previously installed packages into the R library.
library(devtools)
library(remotes)
library(SqlRender)
library(DatabaseConnector)
library(tidyr)
library(ETLSyntheaBuilder)

# Creating the connection details for interfacing with the postgreSQL database.
# Change credentials here if necessary.
cd <- DatabaseConnector::createConnectionDetails(
  dbms             = "postgresql",
  connectionString = "jdbc:postgresql://postgres:5432/postgres",       # Has to match the name of the postgres service from the docker-compose.yml file and the database name (default is equal to user name)
  user             = Sys.getenv("POSTGRES_USER"),                      # Has to match the user name in the postgres service section of the docker-compose.yml file.
  password         = Sys.getenv("POSTGRES_PASSWORD"),                  # Has to match the password in the postgres service section of the docker-compose.yml file.
  pathToDriver     = "/app/jdbc-driver"                                # Absolute path inside Docker container, can be changed in the Dockerfile for the import-data service.
)


# Setting paths and variable names.
cdmSchema      <- "synthea_cdm"                   # Schema name for storing the CDM-formatted Synthea data. 
syntheaSchema  <- "synthea_native"                # Schema name for storing the Synthea input. 
cdmVersion     <- "5.3"                           # Can be either "5.3" or "5.4".
syntheaVersion <- "2.7.0"                         # Has to be "2.7.0".
syntheaFileLoc <- "/data/input/synthea-csv"       # Absolute path inside Docker container, can be changed in the Dockerfile for the import-data service.
vocabFileLoc   <- "/data/input/omop-cdm"          # Absolute path inside Docker container, can be changed in the Dockerfile for the import-data service.


# Creating the two schemas for storing a) the output, i.e., the OMOP-formatted Synthea (CDM-styled), and b) the original input, i.e., the native Synthea (CSV-styled) data.
conn <- connect(cd)
executeSql(conn,paste("CREATE SCHEMA IF NOT EXISTS", cdmSchema, ";", "CREATE SCHEMA IF NOT EXISTS", syntheaSchema, ";"))
disconnect(conn)

# Creating the empty OMOP CDM tables with respective data types.
ETLSyntheaBuilder::CreateCDMTables(connectionDetails = cd, cdmSchema = cdmSchema, cdmVersion = cdmVersion)


# Changing the type of the column "unique_device_id" in the "device_exposure" table (CDM), as Synthea 2.7.0 outputs strings of size >50 in the column "UDI" of "devices.csv" and thus violates the data type constraints from CDM v5.3.1.
conn <- connect(cd)
executeSql(conn,paste0("ALTER TABLE ", cdmSchema, ".device_exposure ", "ALTER COLUMN unique_device_id TYPE varchar(255);"))
disconnect(conn)


# Creating the tables to insert the Synthea data.
ETLSyntheaBuilder::CreateSyntheaTables(connectionDetails = cd, syntheaSchema = syntheaSchema, syntheaVersion = syntheaVersion)
print("Successfully created Synthea tables.")


# Loading the Synthea data into the database.
ETLSyntheaBuilder::LoadSyntheaTables(connectionDetails = cd, syntheaSchema = syntheaSchema, syntheaFileLoc = syntheaFileLoc)
print("Successfully loaded Synthea data into the database.")


# Loading vocabulary from the Athena files into the database.
ETLSyntheaBuilder::LoadVocabFromCsv(connectionDetails = cd, cdmSchema = cdmSchema, vocabFileLoc = vocabFileLoc)
print("Successfully loaded vocabulary from Athena files into the database.")


# Converting Synthea data to CDM-formatted data.
ETLSyntheaBuilder::LoadEventTables(connectionDetails = cd, cdmSchema = cdmSchema, syntheaSchema = syntheaSchema, cdmVersion = cdmVersion, syntheaVersion = syntheaVersion)
print("Successfully converted Synthea to CDM format.")
