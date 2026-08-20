# eclipse-temurin is the maintained successor of the retired adoptopenjdk
# images, and unlike those it ships linux/arm64 alongside linux/amd64
FROM eclipse-temurin:8-jre

LABEL org.opencontainers.image.source=https://github.com/BetaMasaheft/collatex-service
LABEL org.opencontainers.image.description="Docker container for using CollateX as a web service"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.authors="Claudius Teodorescu <claudius.teodorescu@gmail.com>"

ARG COLLATEX_VERSION=1.7.1

# nginx re-frames CollateX responses with Content-Length so eXist's Apache
# HttpClient can finish reading them (issue #7).
RUN apt-get update \
  && apt-get install -y --no-install-recommends nginx \
  && rm -rf /var/lib/apt/lists/* \
  && rm -f /etc/nginx/sites-enabled/default

COPY ./lib/collatex-tools-$COLLATEX_VERSION.jar /collatex-tools.jar
COPY ./nginx/collatex-framer.conf /etc/nginx/nginx.conf
COPY ./scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 17105

# Public port is nginx (17105 == 0x42D1). Entrypoint only starts nginx after
# CollateX is listening on loopback 17106.
HEALTHCHECK --interval=10s --timeout=3s --retries=5 \
  CMD sh -c 'awk "index(\$2,\":42D1\") && \$4==\"0A\" {found=1} END {exit found?0:1}" /proc/net/tcp /proc/net/tcp6'

ENTRYPOINT ["/entrypoint.sh"]

# docker build -t collatex-service .
# docker run -d --rm -p 17105:17105 collatex-service
