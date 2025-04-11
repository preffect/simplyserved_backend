FROM node:18-alpine

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy application code
COPY src/ ./src/
COPY entrypoint.sh ./

# Create directory for certificates
RUN mkdir -p ./local/certs
COPY local/certs/ ./local/certs/

# Make entrypoint executable
RUN chmod +x ./entrypoint.sh

EXPOSE 5001

ENTRYPOINT ["./entrypoint.sh"]
