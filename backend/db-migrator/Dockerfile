FROM postgres:15

RUN apt-get update && apt-get install -y \
    bash \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY ./scripts /app/scripts
COPY ./entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh
RUN chmod +x /app/scripts/*.sh

ENTRYPOINT ["/app/entrypoint.sh"]
