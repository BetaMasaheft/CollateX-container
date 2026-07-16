# eclipse-temurin is the maintained successor of the retired adoptopenjdk
# images, and unlike those it ships linux/arm64 alongside linux/amd64
FROM eclipse-temurin:8-jre

LABEL org.opencontainers.image.source=https://github.com/BetaMasaheft/collatex-service
LABEL org.opencontainers.image.description="Docker container for using CollateX as a web service"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.authors="Claudius Teodorescu <claudius.teodorescu@gmail.com>"

ARG COLLATEX_VERSION=1.7.1

COPY ./lib/collatex-tools-$COLLATEX_VERSION.jar collatex-tools.jar

EXPOSE 17105

ENTRYPOINT ["java", "-jar", "/collatex-tools.jar", "--http", "--port", "17105"]

# sudo docker build -t collatex-service .
# sudo docker run -a stderr collatex-service:latest
