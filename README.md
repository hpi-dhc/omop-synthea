**This repository provides a composite of Docker containers for creating, populating, and accessing an OMOP CDM-formatted *PostgreSQL* database with synthetic health data generated by [*Synthea*](https://synthetichealth.github.io/synthea/).**

It creates and spins up the following three containerized applications:
1) A container with a *postgreSQL* database for storing and accessing the ontology;
2) A container with an instance of *pgAdmin4* access the database including a graphical user interface;
3) A container with a script to load the vocabulary and synthetic patient data into the database.


**0) Prerequisites:**
- An up-to-date Docker instance (tested with `20.10.16` and `20.10.17)`.
- `git` installed.
- A stable internet connection.
- Synthetic data generated with Synthea **v2.7.0** (this can be done by following the instructions in [this repository](https://github.com/hpi-dhc/synthea-v270)).
- The OMOP vocabulary downloaded from Athena*, unzipped, and eventually complemented by proprietary vocabularies (e.g. the CPT-4 terminology can be added by following the instructions in [here](https://github.com/hpi-dhc/athena-cpt4)).
- Only for Linux users: Please provide Docker and its corresponding user group(s) read AND write access to your file system (specifically: The folders with the input data plus all its subdirectories, and the folder you will be storing the PostgreSQL database files in, cf. `PATH_TO_POSTGRES_STORAGE_LOCATION` in this README and in the *example.env* file).

# Initial setup (import data)

**1) Clone this repository:**

Use either of the following two commands:

```
git clone https://github.com/hpi-dhc/omop-synthea.git
git clone git@github.com:hpi-dhc/omop-synthea.git
```

**2) Set the environment variables:**

Before starting, folder paths and credentials have to be specified in a separate *.env* file.
The accompanying *example.env* in this repository may serve as a template for it, however it should be renamed to *.env* thereafter. 

The first four path variables refer to the paths used to store the input and database data, and the *pgAdmin* settings.
They must be specified as absolute or relative paths on the host machine (**only absolute paths work on Windows machines**), with neither brackets nor quotations marks needed:
- `PATH_TO_SYNTHEA_CSV` : The path to the folder where the *.csv* files generated by Synthea reside. This folder will be mounted just for the initial ETL process, not for production. It will also be *read-only* so that the Synthea files cannot be altered.
- `PATH_TO_OMOP_CDM_VOCAB_FILES` : The path to the folder where the unzipped OMOP vocabulary files (downloaded from Athena) are stored. This folder will also be mounted just for the ETL of the database, not for production. As such, it will be *read-only* so that the vocabulary files will remain unchanged.
- `PATH_TO_POSTGRES_STORAGE_LOCATION` : The path to the folder where the *postgreSQL* database files will be stored. This folder must first be created on the host machine before continuing with the next step of the setup. It will be a *read-and-write* volume, as the database needs to write its files to it during the ETL process. Subsequently, Docker has to be given *read-and-write* access to it (cf. prerequisites section above).
- `PATH_TO_PGADMIN_DATA` : The path to the folder where the *pgAdmin* settings will be stored.

The following variables can be used with their defaults in a local setting, but should be changed if deployed on machines with more than one user; again the values with neither brackets nor quotations marks:
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `PGADMIN_DEFAULT_EMAIL`
- `PGADMIN_DEFAULT_PASSWORD`

From now on, make sure that the working directory is your repository path.

**3) Build and compose orchestrated containers:**

Use *docker compose* to run all three services: a) The *`import-data`* service, b) the *`postgres`* database service, and c) the *`pgadmin`* service:

```
docker compose up --build
```

Building the images, spinning up the containers and executing the ETL scripts will take a considerable amount of time (1-2 hours on a non-representative set of regular notebooks).

Wait for the process to finish.

*(Known issue: Closing the lid of a laptop or, more generally, sending the host machine to sleep might compromise the successful completion of this step.)*

**4) Shut down the orchestrated containers:**

After finishing, shut down the orchestrated containers by executing the following command:

```
docker compose down
```

If you are using the same window/tab of your terminal, you first need to `Ctrl` + `c` to detach from the process and come back to your working directory OR you open a new window/tab with the same working directory and execute the above command there.
Either way will work.

In any case, the database files will be persisted (at the location specified earlier) and accessed whenever you will start the containers anew.

**5) Comment out the data import service from the *docker-compose* file**

Before you start your containers again, make sure you comment out the entire *`import-data`* service section (lines 4-14) from the *docker-compose.yml* (e.g., in VS Code `"Ctrl" + "/"` on Windows/Linux (`"Cmd" + "/"` on Mac respectively).

**6) Back up your database files**

Just to be on the safe side (and since postgres–or Docker (?)–does not support switching to a read-only mounted volume after it has been initialized with full permissions, and could thus inadvertently alter the successfully loaded files), back up the entire folder at `PATH_TO_POSTGRES_STORAGE_LOCATION`, e.g., by simply using

```
cp -r PATH_TO_POSTGRES_STORAGE_LOCATION PATH_TO_BACKUP
```
and replacing the capitalized variables with the respective absolute or relative paths on the host machine.

# Regular operation (accessing data once imported)


**1) Start the orchestrated containers**

**IMPORTANT:** Make sure you have commented out the entire *`import-data`* service section in the *docker-compose.yml* file as indicated in step 5 above.
Not following this procedure will likely result in exiting containers.

With this modified *docker-compose.yml*, execute

```
docker compose up -d
```

**2) Start querying with *pgAdmin4***

Open a browser on your local machine and type `localhost:80` to access the *pgAdmin* interface. Log in with the `PGADMIN_DEFAULT_EMAIL` and `PGADMIN_DEFAULT_PASSWORD` from the *.env* file set up earlier.

"Add New Server" by providing the following connection details in the `General` and `Connection` tabs:
- ```General >> Name```: Choose your preferred name for this connection. It does not need to reflect any of the variable names chosen before.
- ```Connection >> Host name/address```: Should be `postgres` if you followed the setup described in these instructions. Whenever accessing services inside a Docker network, Docker encourages you to use the database service name assigned in the `docker-compose.yml` file instead of IP addresses.
- ```Connection >> Port```: Should stay `5432` if you followed the setup described in these instructions. Keep in mind that the port number may need to be changed when you set up *ports* inside the Docker network or those that you *expose* to the host machine in a different way (cf. Notes section below for further details).
- ```Connection >> Maintenance database```: Remains `postgres` unless specified differently by an advanced database user during database setup.
- ```Connection >> Username```: Change to the user name for the database, specified in the *.env* file as  POSTGRES_USER (default value in the *example.env* file: `postgres`).
- ```Connection >> Password```: Enter the password specified in the *.env* as POSTGRES_PASSWORD (default value in the *example.env* file: `SuperSecret`). Eventually enable the option to save the password to avoid that it will be prompted every time at login to a new pgAdmin session. WARNING: This will persist the login details on the host machine and can be compromised by other users accessing the same machine (e.g., on a server). It is strongly advised NOT to save the password, with the only potentially justifiable reason being a fully local setup on a personal computer.

Happy querying! :)

**3) Shut down services after usage**

If you are done querying and want to spare resources on your computer, stop the containers with

```
docker compose down
```

## Notes:

- There are other ways than *pgAdmin* to access the database:
    - **Variant A:** You replace *pgAdmin* by another containerized service in the *docker-compose.yml*. No further changes are required, you might just want to amend the *.env* file. Similar to the *pgAdmin* setup above, only the database service name (*`postgres`*) in Docker is used as the server name/address in a local setup (instead of IP addresses).
    - **Variant B:** You want to access the database from your host machine with any other software. In this case, you will need to replace the following `expose` section of the *`postgres`* service in the *docker-compose.yml* by a `ports` section to make the `postgres` default port 5432 visible to and accessible from the host machine.
    ```
        expose:
            - "5432"
    ```
    ... replace by ...
    ```
        ports:
            - "5432:5432"
    ```
    - **Variant C:** You want to access the database from another container, but which is outside of this *docker-compose.yml* file. In this case, first spin this docker compose up as normal. Then spin up a second container (or compose environment) and attach it to the *`omopdb`* Docker network.
    - **Variant D:** Through attaching a shell to the *`postgres`* container and running *psql* commands directly in the terminal.
- Variant C also applies if you want to access the database from any other containerized application on the same machine (e.g., a *Jupyter* notebook server).
- If port `5432` is already taken on your host machine, you can also change the first number before the double colon in the `ports` section to a port of your choice (e.g., the result would be `54320:5432`). The same applies to port `80` in the *`pgadmin`* service section, of course.
- If not otherwise specified, all commands are executed on the host machine with the working directory being the cloned repository.
- This repository is intended for local use only. Even though some of the best practices for creating Dockerfiles were followed, deployment in a production setting would require additional security mechanisms.
- One of these mechanisms would be to pin versions (of R and Linux system libraries) to ensure exact reproducibility. However, this is not a straightforward task, and in this case here it can be rather safely assumed that non-static versions of Linux system libraries (for the *`import-data`* image/container) would not alter the behaviour of the actual embedded *R* scripts.
- Specifically, a known issue in this context is the rapid change of Linux system libraries dependencies of the *devtools* package executed in the first *R* script inside the *`import-data`* image/container. Required future additions to the Linux system libraries dependencies will likely be pointed at in the console output upon building the *`import-data`* image. They should subsequently be added to line 11 in the *Dockerfile*. Future iterations of this repository might download the *devtools* package at a specific version and `COPY` it during the build phase of the image to avoid this issue.
- The DESCRIPTION file in this repository is a small variation of [the file provided by OHDSI](https://github.com/OHDSI/ETL-Synthea/blob/master/DESCRIPTION). The two R scripts for data import partially reuse [existing code](https://github.com/OHDSI/ETL-Synthea/blob/master/extras/codeToRun.R) from the OHDSI consortium.
- This project intentionally refrains from using a copyleft license. Nevertheless, all users are kindly invited to contribute to the project, specifically to leave a note to the author if you find parts of the code to be broken or the explanations in this README ambiguous.


*(Written by [Jan Philipp Sachs](www.jpsachs.de); updated on August 11, 2022)*

**\*** *The (standardized) vocabularies need to be downloaded first from [Athena](https://athena.ohdsi.org), a service provided by OHDSI, the not-for-profit consortium behind the OMOP data standard. To that end, create a free account there, then proceed with the recommended vocabularies and wait for the download to be accessible (you will receive an email, this may take some time). If you need procedures from the CPT-4 terminology to be included into your database, you will need to follow the provided instructions (a corresponding shell script is provided with the download).*
