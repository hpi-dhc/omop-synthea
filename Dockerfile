FROM r-base:4.1.2

LABEL maintainer="Jan Philipp Sachs" \
      email="jan-philipp.sachs@hpi.de" \
      institution="Hasso Plattner Institute, University of Potsdam, Germany"

RUN groupadd -r leastprivilegedgroup && \
    useradd -r -s /bin/false -g leastprivilegedgroup leastprivilegeduser

RUN apt-get update \
 && apt-get install -y --no-install-recommends wget=1.21.3-1+b2 default-jdk=2:1.11-72 libcurl4-openssl-dev=7.83.1-2 libssl-dev=3.0.3-8 libxml2-dev=2.9.14+dfsg-1 libgit2-dev=1.3.0+dfsg.1-3 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN mkdir ../data \
    && mkdir ../data/ETL-Synthea \
    && wget --progress=bar:force:noscroll https://github.com/OHDSI/ETL-Synthea/archive/462344ed1e9a883d360e4cd5c5a292cac07463c8.tar.gz \
    && tar -xf 462344ed1e9a883d360e4cd5c5a292cac07463c8.tar.gz -C /data/ETL-Synthea --strip-components=1 \
    && rm 462344ed1e9a883d360e4cd5c5a292cac07463c8.tar.gz \
    && chown -R leastprivilegeduser:leastprivilegedgroup /app \
    && chown -R leastprivilegeduser:leastprivilegedgroup /data

COPY ./DESCRIPTION /data/ETL-Synthea/DESCRIPTION

COPY script-1-install-packages.r .

RUN Rscript script-1-install-packages.r

COPY script-2-import-data.r .

USER leastprivilegeduser

ENTRYPOINT [ "sh", "-c", "Rscript script-2-import-data.r" ]
