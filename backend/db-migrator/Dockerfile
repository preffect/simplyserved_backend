FROM postgres:15

RUN apt-get update && apt-get install -y \
    curl \
    jq \
    md5sum \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY entrypoint.sh /app/
COPY wait-for-postgres.sh /app/
COPY migrate.sh /app/

RUN chmod +x /app/entrypoint.sh /app/wait-for-postgres.sh /app/migrate.sh

ENTRYPOINT ["/app/entrypoint.sh"]
