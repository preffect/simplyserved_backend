FROM node:18-alpine

WORKDIR /app

# Install PostgreSQL client
RUN apk add --no-cache postgresql-client

RUN npm install -g graphile-migrate

COPY ./wait-for-postgres.sh /app/wait-for-postgres.sh
RUN chmod +x /app/wait-for-postgres.sh

COPY ./entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
