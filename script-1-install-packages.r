## Installing devtools to force the use of specific versions.
install.packages("devtools")
library(devtools)

## Installing specific versions of required packages from CRAN.
devtools::install_version("remotes", version = "2.4.2", repos = "https://cran.r-project.org/")
devtools::install_version("SqlRender", version = "1.9.0", repos = "https://cran.r-project.org/")
devtools::install_version("DatabaseConnector", version = "5.0.2", repos = "https://cran.r-project.org/")
devtools::install_version("tidyr", version = "1.2.0", repos = "https://cran.r-project.org/")

## Loading the packages into the library.
library(remotes)
library(SqlRender)
library(DatabaseConnector)
library(tidyr)

## Installing and loading the ETLSyntheaBuilder from local folder (in Docker).
devtools::install_local("/data/ETL-Synthea")
# devtools::install_github("OHDSI/ETL-Synthea", ref="462344e")
# The installation from github should be the standard. However, referencing issue #TODO in the ETL-Synthea repository, the DESCRIPTION file in the root level of the folder currently contains an small issue. As a workaround, the whole repository (commit 462344e from https://github.com/OHDSI/ETL-Synthea ) is downloaded directly to the Docker image (while creating the image with the Dockerfile). The updated DESCRIPTION file is provided within this repository and replaces the copy in the Docker image.
# This section of the code can be removed as soon as the issue will have been solved in the OHDSI/ETL-Synthea repository.
# Background information on this issue can be found in the README of this repository.
library(ETLSyntheaBuilder)

## Downloading the JDBC driver for postgreSQL.
# Currently (as of May 31, 2022, commit b3d3162 tagged v5.0.2 of OHDSI/DatabaseConnector), this is v42.2.18 according to the reference in the code provided by OHDSI at https://github.com/OHDSI/DatabaseConnector/blob/main/R/Drivers.R#L90
# This is the actual site of the Connectors for the different database types: https://ohdsi.github.io/DatabaseConnectorJars/
# ...and the respective postgreSQL driver that is downloaded from here: https://ohdsi.github.io/DatabaseConnectorJars/postgresqlV42.2.18.zip with an MD5 checksum of b2ac5c7b8e7dfc2a0045122833a1603a for the ZIP file.
# When unzipped, the md5 checksum (d6895bb05ac7b9c85c4e89f3880127e3) is equivalent to the original driver (column "JDBC 4.2") from the postgreSQL website at https://jdbc.postgresql.org/download.html
# This section of the code needs continuous monitoring and potentially updating the postgreSQL JDBC drivers, specifically if deployed in a production setting.
downloadJdbcDrivers(
  "postgresql",
  pathToDriver = "/app/jdbc-driver",
  method = "auto"
)
