FROM maven:3.8-eclipse-temurin-8 as build

WORKDIR /graphhopper

COPY . .

RUN mvn clean install

FROM eclipse-temurin:18-jre

ENV JAVA_OPTS "-Xmx1g -Xms1g"

RUN apt-get update \
  && apt-get install --no-install-recommends -y \
    wget=1.20.3-1ubuntu2 \
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
