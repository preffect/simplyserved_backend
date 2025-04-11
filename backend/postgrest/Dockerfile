FROM alpine:latest
COPY --from=postgrest/postgrest /bin/postgrest /bin

WORKDIR /app

# Install PostgreSQL client for health check
RUN apk add --no-cache postgresql-client wget

COPY ./wait-for-postgres.sh /app/wait-for-postgres.sh
COPY ./entrypoint.sh /app/entrypoint.sh
COPY ./postgrest.conf /etc/postgrest.conf

RUN chmod +x /app/wait-for-postgres.sh /app/entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/app/entrypoint.sh"]
