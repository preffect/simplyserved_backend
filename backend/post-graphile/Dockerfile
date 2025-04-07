FROM node:18-alpine

WORKDIR /app

# Install PostgreSQL client
RUN apk add --no-cache postgresql-client
RUN apk add --no-cache bash
RUN apk add --no-cache vim

# Install dependencies locally instead of globally
RUN npm init -y
RUN npm install express postgraphile @graphile/pg-pubsub
RUN npm install @graphile-contrib/pg-simplify-inflector
RUN npm install postgraphile-plugin-connection-filter

COPY ./wait-for-postgres.sh /app/wait-for-postgres.sh
COPY ./allowedOriginPlugin.js /app/allowedOriginPlugin.js
COPY ./app.js /app/app.js
RUN chmod +x /app/wait-for-postgres.sh

COPY ./entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

COPY ./.postgraphilerc.js /app/.postgraphilerc.js

RUN echo "alias ll='ls -alF'" >> /root/.bashrc
RUN echo "alias vi='vim'" >> /root/.bashrc

EXPOSE 5000

ENTRYPOINT ["/app/entrypoint.sh"]
