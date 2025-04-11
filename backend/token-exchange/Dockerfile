FROM node:18-alpine

WORKDIR /app

# Install PostgreSQL client for wait-for-postgres script
RUN apk add --no-cache postgresql-client

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy application code
COPY src/ ./src/
COPY entrypoint.sh ./
COPY wait-for-postgres.sh ./

# Create directory for certificates
RUN mkdir -p ./local/certs
COPY local/certs/ ./local/certs/

# Make scripts executable
RUN chmod +x ./entrypoint.sh
RUN chmod +x ./wait-for-postgres.sh

EXPOSE 5001

ENTRYPOINT ["./entrypoint.sh"]
