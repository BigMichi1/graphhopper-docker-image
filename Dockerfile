FROM maven:3.9.4-eclipse-temurin-17@sha256:e3f36fd6d0949541de3b6a32bb3de30331b2bdb6bac8ba365c4f8a5f0fcd3e59 as build

WORKDIR /graphhopper

COPY graphhopper .

RUN mvn clean install

FROM eclipse-temurin:20.0.2_9-jre-alpine@sha256:b8e2727ecec3b4c8e3d84da3fa4baf148fabcc01d203a9063f990fd4357f93b1

ENV JAVA_OPTS "-Xmx1g -Xms1g"

RUN mkdir -p /data

WORKDIR /graphhopper

COPY --from=build /graphhopper/web/target/graphhopper*.jar ./

COPY graphhopper.sh graphhopper/config-example.yml ./

# Enable connections from outside of the container
RUN sed -i '/^ *bind_host/s/^ */&# /p' config-example.yml

VOLUME [ "/data" ]

EXPOSE 8989 8990

HEALTHCHECK --interval=5s --timeout=3s CMD curl --fail http://localhost:8989/health || exit 1

ENTRYPOINT [ "./graphhopper.sh", "-c", "config-example.yml" ]
