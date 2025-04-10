FROM postgrest/postgrest:latest

WORKDIR /app

# Install PostgreSQL client for health check
RUN apt-get update && apt-get install -y postgresql-client wget && rm -rf /var/lib/apt/lists/*

COPY ./wait-for-postgres.sh /app/wait-for-postgres.sh
COPY ./entrypoint.sh /app/entrypoint.sh
COPY ./postgrest.conf /etc/postgrest.conf

RUN chmod +x /app/wait-for-postgres.sh /app/entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/app/entrypoint.sh"]
