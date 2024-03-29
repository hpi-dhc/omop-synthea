FROM r-base:4.2.1

LABEL maintainer="Jan Philipp Sachs" \
      email="jan-philipp.sachs@hpi.de" \
      institution="Hasso Plattner Institute, University of Potsdam, Germany"

RUN groupadd -r leastprivilegedgroup && \
    useradd -r -m -s /bin/false -g leastprivilegedgroup leastprivilegeduser

RUN apt-get update \
    && apt-get install -y --no-install-recommends wget default-jdk libcurl4-openssl-dev libssl-dev libxml2-dev libgit2-dev libharfbuzz-dev libfribidi-dev libfontconfig1-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev libpq-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN mkdir ../data \
    && mkdir ../data/ETL-Synthea \
    && wget --progress=bar:force:noscroll https://github.com/OHDSI/ETL-Synthea/archive/f63b9fc2ef13d29b8e7cf6a62c1bec11960e0922.tar.gz \
    && tar -xf f63b9fc2ef13d29b8e7cf6a62c1bec11960e0922.tar.gz -C /data/ETL-Synthea --strip-components=1 \
    && rm f63b9fc2ef13d29b8e7cf6a62c1bec11960e0922.tar.gz \
    && chown -R leastprivilegeduser:leastprivilegedgroup /app \
    && chown -R leastprivilegeduser:leastprivilegedgroup /data

COPY ./DESCRIPTION /data/ETL-Synthea/DESCRIPTION

COPY script-1-install-packages.r .

RUN Rscript script-1-install-packages.r

COPY script-2-import-data.r .

USER leastprivilegeduser

ENTRYPOINT [ "sh", "-c", "Rscript script-2-import-data.r" ]
