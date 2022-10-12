FROM maven:3.8-eclipse-temurin-19 as build

WORKDIR /graphhopper

COPY . .

RUN mvn clean install

FROM eclipse-temurin:19-jre

LABEL org.opencontainers.image.title='Graphhopper docker'
LABEL org.opencontainers.image.description='GraphHopper is a fast and memory-efficient routing engine packed into a Docker image'
LABEL org.opencontainers.image.authors='Michael Cramer <michael@bigmichi1.de>, Harel M'
LABEL org.opencontainers.image.url='https://github.com/BigMichi1/graphhopper-docker-image'
LABEL org.opencontainers.image.documentation='https://github.com/BigMichi1/graphhopper-docker-image'
LABEL org.opencontainers.image.source='https://github.com/BigMichi1/graphhopper-docker-image'
LABEL org.opencontainers.image.vendor='Michael Cramer'
LABEL org.opencontainers.image.licenses='MIT'

ENV JAVA_OPTS "-Xmx1g -Xms1g"

RUN apt-get update \
  && apt-get install --no-install-recommends -y \
    wget \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data

WORKDIR /graphhopper

COPY --from=build /graphhopper/web/target/graphhopper*.jar ./

COPY ./config-example.yml ./

COPY ./graphhopper.sh ./

VOLUME [ "/data" ]

EXPOSE 8989

HEALTHCHECK --interval=5s --timeout=3s CMD curl --fail http://localhost:8989/health || exit 1

ENTRYPOINT [ "./graphhopper.sh", "-c", "config-example.yml" ]
