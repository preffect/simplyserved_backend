FROM node:18-alpine

WORKDIR /app

# Install PostgreSQL client
RUN apk add --no-cache postgresql-client
RUN apk add --no-cache bash
RUN apk add --no-cache vim

RUN npm install -g postgraphile @graphile/pg-pubsub
RUN npm install -g @graphile-contrib/pg-simplify-inflector
RUN npm install -g postgraphile-plugin-connection-filter

COPY ./wait-for-postgres.sh /app/wait-for-postgres.sh
COPY ./allowedOriginPlugin.js /app/allowedOriginPlugin.js
RUN chmod +x /app/wait-for-postgres.sh

COPY ./entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

COPY ./.postgraphilerc.js /app/.postgraphilerc.js

RUN echo "alias ll='ls -alF'" >> /root/.bashrc
RUN echo "alias vi='vim'" >> /root/.bashrc

EXPOSE 5000

ENTRYPOINT ["/app/entrypoint.sh"]
