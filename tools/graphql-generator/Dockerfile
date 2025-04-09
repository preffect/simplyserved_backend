FROM node:18-alpine

WORKDIR /app

COPY package.json ./
RUN npm install

COPY codegen.yml ./
COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
