FROM postgres:15

RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y jq
RUN apt-get install -y md5sum

WORKDIR /app

COPY entrypoint.sh /app/
COPY wait-for-postgres.sh /app/
COPY migrate.sh /app/

RUN chmod +x /app/entrypoint.sh /app/wait-for-postgres.sh /app/migrate.sh

ENTRYPOINT ["/app/entrypoint.sh"]
